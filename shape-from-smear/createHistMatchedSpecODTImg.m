function stimImg = createHistMatchedSpecODTImg(shapeData, varargin)

mask = shapeData.mask;

minDirs = shapeData.specCompressions.minDirs;
maxspds = shapeData.specCompressions.maxspds;
minspds = shapeData.specCompressions.minspds;

diffIters = 5;
bins = 400;

parsearglist({'noise', 'scales', 'anisos', 'diffIters', 'bins'}, varargin);

if ~exist('noise', 'var')
  noise = rand(size(shapeData.mask));
end

if ~exist('scales', 'var')
  scales = 1./(maxspds.*minspds);
  scales(~mask) = 0;
end

sz = size(scales);
scales = histMatch(scales, pinkify(rand(sz)), mask, bins);
scales = imfilter(30*scales + 0.25, fspecial('gaussian', 30, 5), 'replicate');

if ~exist('anisos', 'var')
  anisoso = sqrt(1./anisosd + 1/4) - 1/2; % Offset for hyperbolicness
  anisos = 1 - minspds./maxspds;
  anisos(~mask) = 1;
  anisos = imfilter(anisos, fspecial('gaussian', 36, 6), 'replicate');
end

anisos = histMatch(anisos, pinkify(rand(sz)), mask, bins);
anisos = -1./(anisosd*(anisos - anisoso - 1)) - sanisoso; % Compute hyperbolic nonlinearity
anisos = anisos.*scales*100;

mn = multiscaleNoise(scales*0.6, noise);

matchedDirs = histMatch(minDirs, pinkify(rand(sz)), mask, bins);
matched = makeODT(mn, matchedDirs, scales, [], mags, mask);
stimImg = struct('img', anisotropicDiffusion(matched, dirs, sqrt(anisos), diffIters));
