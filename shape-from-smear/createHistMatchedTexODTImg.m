function stimImg = createHistMatchedTexODTImg(shapeData, varargin)

majDirs = shapeData.foreshortening.majDirs;
minLens = shapeData.foreshortening.minLens;
majLens = shapeData.foreshortening.majLens;

anisosScale = 5;
diffIters = 5;
saturation = 1;
bins = 400;

parsearglist({'noise', 'scales', 'maxScale', 'anisos', 'anisosScale', 'diffIters', 'saturation', 'bins'}, varargin);

if ~exist('scales', 'var')
  scales = minLens;
  
  if ~exist('maxScale', 'var')
    maxScale = 2;
  end
end

if ~exist('noise', 'var')
  noise = rand(size(shapeData.mask));
end

if ~exist('anisos', 'var')
  anisos = 1 - minLens./majLens;
end

if isscalar(scales)
  scales = repmat(scales, size(shapeData.mask));
end

if exist('maxScale', 'var') && ~isempty(maxScale)
  scales = maxScale*scales./max(scales(:));
end

sz = size(scales);
scales = histMatch(scales, pinkify(rand(sz)), shapeData.mask, bins);
mn = multiscaleNoise(scales, noise, saturation);

dirs = histMatch(majDirs, pinkify(rand(sz)), shapeData.mask, bins);
anisos = histMatch(anisos, pinkify(rand(sz)), shapeData.mask, bins);
matched = makeODT(mn, dirs, scales, [], anisos*anisosScale, shapeData.mask, saturation);
stimImg = struct('img', anisotropicDiffusion(matched, dirs, anisos, diffIters));
