function [directions amounts] = compressedSlantTilt(compression, varargin)

normals = varargin{1};

nrows = size(normals, 1);
ncols = size(normals, 2);
  
[orthoSlants orthoTilts] = slantTiltFromNormals(varargin{1}, 'l', varargin{3:end});
cosSlants = cos(orthoSlants);
sinSlants = sin(orthoSlants);
cosTilts = cos(orthoTilts);
sinTilts = sin(orthoTilts);

surfaceX_bases = ...
  cat(3, sinTilts.^2 + cosTilts.^2.*cosSlants.^2, ...
         cosTilts.*sinSlants, ...
         sinTilts.*cosTilts.*(cosSlants - 1));
surfaceY_bases = cross(normals, surfaceX_bases);
  
compression = shiftdim(compression(:), -2);
compressionDotNormals = sum(bsxfun(@times, compression, normals), 3);
compressionAz = ...
  atan2(-compressionDotNormals, sum(bsxfun(@times, compression, surfaceX_bases), 3)) - ...
  pi/2*(compressionDotNormals ~= 0);
compressionAmount = sqrt(sum(compression.^2));
compressionForward = repmat(compression./compressionAmount, [nrows ncols]);
compressionRight = ...
  bsxfun(@times, cos(compressionAz), surfaceX_bases) + ...
  bsxfun(@times, sin(compressionAz), surfaceY_bases);
compressionUp = cross(compressionRight, compressionForward, 3);

compressionNormalComponents = bsxfun(@times, compressionDotNormals, normals);
compressionProjected = bsxfun(@minus, compression, compressionNormalComponents);

compressionProjectedRelative = ...
  cat(3, sum(bsxfun(@times, compressionProjected, compressionRight), 3), ...
         sum(bsxfun(@times, compressionProjected, compressionForward), 3), ...
         sum(bsxfun(@times, compressionProjected, compressionUp), 3));
compressionProjectedRelative = ...
  bsxfun(@rdivide, compressionProjectedRelative, sqrt(sum(compressionProjectedRelative.^2, 3)));

compressionProjectedAmount = ...
  sqrt(sum(bsxfun(@times, shiftdim([1 compressionAmount 1], -1), compressionProjectedRelative).^2, 3));
compressionProjectedDirection = ...
  atan2(sum(compressionProjected.*surfaceY_bases, 3), sum(compressionProjected.*surfaceX_bases, 3));

[slants tilts] = slantTiltFromNormals(varargin{:});

[majDirs majAmts minDirs minAmts] = ...
  combineCompressions(cat(3, compressionProjectedDirection, tilts), ...
                       cat(3, compressionProjectedAmount, sqrt(1 + tan(slants).^2)));

nanDirs = (sum(normals.^2, 3) == 0);
directions = majDirs;
directions(nanDirs) = NaN;
amounts = minAmts./majAmts;
amounts(nanDirs) = 1;
    
    