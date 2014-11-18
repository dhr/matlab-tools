%MAKEODT Creates an orientation-defined texture (ODT).
%   [ODT MN] = MAKEODT(TEX, DIRS, SCALES, MAXSCALE, ANISOS, MASK, SAT)
%   creates an orientation-defined texture (ODT).
%
%   TEX is the input texture from which the ODT is to be created.  If the
%   empty matrix is passed, then MAKEODT creates a multinoise texture
%   using SCALES and MAXSCALE to use for the ODT.
%
%   DIRS specifies the orientations used in creating the ODT, in radians.
%
%   SCALES specifies a set of sigma values to use in creating the input
%   texture to the ODT.  If TEX is not the empty matrix, the scales used to
%   create TEX should still be passed so that contrast renormalization can
%   be performed on ODT.
%
%   MAXSCALE specifies the maximum scale to be used.  SCALES is scaled
%   such that its maximum value is MAXSCALE.  No rescaling is performed if
%   the empty matrix is passed.
%
%   ANISOS specifies the anisotropies to use in the ODT (corresponding to
%   the magnitude parameter for LIC).
%
%   MASK specifies a mask to use in contrast renormalization.  Anything
%   outside the mask (regions where the mask is 0) is ignored in contrast
%   renormalization.
%
%   ODT is the resulting orientation-defined texture.  It is contrast
%   corrected.
%
%   SAT can be used to tweak the amount of "saturation" of contrast in the
%   image.  Values greater than 1 increase the contrast, values less than 1
%   decrease the contrast.  Defaults to 1.
%
%   MN is the multiscale noise texture used for the ODT.  If TEX is not the
%   empty matrix, MN = TEX.
%
%   See also LIC, MULTISCALENOISE, NORMALIZECONTRAST, SATURATELIC.

function [odt multinoise] = makeODT(varargin)

argi = 1;
multinoise = varargin{argi}; argi = argi + 1;
dirs = varargin{argi};

argi = argi + 1;
if argi <= length(varargin)
  scales = varargin{argi};
else
  scales = 0.5;
end

argi = argi + 1;
if argi <= length(varargin)
  maxScale = varargin{argi};
else
  maxScale = [];
end

argi = argi + 1;
if argi <= length(varargin)
  anisotropies = varargin{argi};
else
  anisotropies = 10;
end

argi = argi + 1;
if argi <= length(varargin)
  mask = varargin{argi};
else
  mask = true(size(dirs));
end

argi = argi + 1;
if argi <= length(varargin)
  satKnob = varargin{argi};
else
  satKnob = 1;
end

argi = argi + 1;
if argi <= length(varargin)
  contrast = varargin{argi};
else
  contrast = [0 1];
end

if ~isempty(maxScale)
  scales = maxScale*scales./max(scales(:));
end

if isscalar(scales)
  scales = repmat(scales, size(dirs));
end

scales(~mask) = 0;

if isempty(multinoise)
  multinoise = multiscaleNoise(scales, [], satKnob);
end

anisotropies(~isfinite(anisotropies)) = 0;
[odt energies] = lic(multinoise, dirs, anisotropies);
odt = normalizeContrast(saturateLic(odt, energies, scales, satKnob), contrast, 0, mask);