function stimImg = createSpecularODTImg(shapeData, varargin)

minDirs = shapeData.specCompression.minDirs;
maxSpds = shapeData.specCompression.maxSpds;
minSpds = shapeData.specCompression.minSpds;
mask = shapeData.mask;

diffIters = 5;
anisosd = 30;

parsearglist({'noise', 'scales', 'anisos', 'mags', 'diffIters', 'anisosd'}, varargin);

if ~exist('noise', 'var')
  noise = rand(size(shapeData.mask));
end

if ~exist('scales', 'var')
  scales = 1./(maxSpds.*minSpds);
  scales(~mask) = 0;
  scales = imfilter(30*scales + 0.25, fspecial('gaussian', 30, 5), 'replicate');
end

if ~exist('anisos', 'var')
  anisos = 1 - minSpds./maxSpds;
  anisos(~mask) = 1;
  anisos = imfilter(anisos, fspecial('gaussian', 36, 6), 'replicate');
end

if ~exist('mags', 'var')
  anisoso = sqrt(1./anisosd + 1/4) - 1/2; % Offset for hyperbolicness
  mags = -1./(anisosd*(anisos - anisoso - 1)) - anisoso; % Compute hyperbolic nonlinearity
  mags = mags.*scales*100;
end

mn = multiscaleNoise(scales*0.6, noise);

sodt = makeODT(mn, minDirs, scales, [], mags, shapeData.mask);
stimImg = struct('img', anisotropicDiffusion(sodt, minDirs, sqrt(anisos), diffIters));