function stimImg = createMaskedNoisePatternImg(shapeData, varargin)

scale = 1;
contrast = [0 1];
saturation = 1;

parsearglist({'scale', 'contrast', 'noise', 'saturation'}, varargin);

if ~exist('noise', 'var')
  noise = rand(size(shapeData.mask));
end

target = imfilter(noise, fspecial('gaussian', 6*scale, scale), 'circular');
target = saturateContrast(target, 1/(12*scale*saturation));
stimImg = struct('img', normalizeContrast(target, contrast, 0, shapeData.mask));