function stimImg = createTextureODTImg(shapeData, varargin)
%CREATETEXTUREODTIMG A creator function for texture ODT images.
%   STIM = CREATETEXTUREODTIMG(SD, ...) creates a texture ODT stimulus, and
%   acts as a creator function that can be supplied to MAKEODTSTIMULI.
%
%   SD is a (single) shape data object as returned by MAKESHAPEDATA.
%
%   Additional arguments are property/value pairs. Valid properties are:
%
%   'Noise': A noise texture to be used as the basis for ODT. Defaults to a
%     rand(size(sd.mask)).
%
%   'Scales': Specifies a set of sigma values to use in creating the input
%     texture to the ODT.
%
%   'MaxScale': Specifies the maximum scale to be used.  SCALES is scaled
%     such that its maximum value is MAXSCALE.  No rescaling is performed
%     if the empty matrix is passed.
%
%   'ScalesScale': Multiplicatively scales the scales. Defaults to 1.
%
%   'Anisos': Specifies the anisotropies to use in the ODT (corresponding
%     to the magnitude parameter for LIC).
%
%   'AnisosScale': Mutliplicatively scales the anisotropies.
%
%   'AnisosBaseline': Default maximum 'length' of the anisotropies (before
%     scaling). Defaults to 5.
%
%   'DirsOffset': Additive offset(s) for the orientations.
%
%   'DiffIters': Number of iterations of anisotropic diffusion to perform
%     after LIC for smoothing. Defaults to 5.
%
%   'Saturation': Can be used to tweak the amount of "saturation" of
%     contrast in the image.  Values greater than 1 increase the contrast,
%     values less than 1 decrease the contrast.  Defaults to 1.
%
%   See also makeODT, makeODTStimuli.

scalesScale = 1;
anisosScale = 1;
anisosBaseline = 5;
diffIters = 5;
saturation = 1;
contrast = [0 1];
dirsOffset = 0;

parsearglist({'noise', 'scales', 'maxScale', 'scalesScale', 'anisos', 'dirsOffset', ...
              'anisosScale', 'anisosBaseline', 'diffIters', 'saturation', 'contrast'}, varargin);

majDirs = shapeData.foreshortening.majDirs + dirsOffset;
minLens = shapeData.foreshortening.minLens;
majLens = shapeData.foreshortening.majLens;

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

scales = scales*scalesScale;
anisos = anisos*anisosScale;

mn = multiscaleNoise(scales, noise, saturation);

todt = makeODT(mn, majDirs, scales, [], anisos*anisosBaseline, shapeData.mask, saturation, contrast);
stimImg = struct('img', anisotropicDiffusion(todt, majDirs, anisos, diffIters));
stimImg.img = normalizeContrast(stimImg.img, contrast, 0, shapeData.mask);