%MULTISCALENOISE Creates multiscale noise.
%   NOISE = MULTISCALENOISE(SIGMAS, INIT, SAT) creates multiscale noise
%   given the standard deviations SIGMAS passed to VARIABLEBLUR.  NOISE is
%   appropriately contrast corrected.  INIT is the optional initial random
%   noise pattern (will be created if not given).  SAT is the amount to
%   saturate the contrast (greater than 1 saturates more, less than 1
%   saturates less, and the default is 1).
%
%   See also VARIABLEBLUR, SATURATECONTRAST, NORMALIZECONTRAST.

function noise = multiscaleNoise(sigmas, noise, satKnob)

if nargin < 2 || isempty(noise)
  noise = rand(size(sigmas));
end

if nargin < 3
  satKnob = 1;
end

noise = variableBlur(noise, sigmas);
noise = saturateContrast(noise, 1./(12*satKnob*sigmas));
noise = normalizeContrast(noise);
