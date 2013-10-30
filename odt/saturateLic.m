%SATURATELIC Compensate for low contrast due to LIC.
%   SAT = SATURATELIC(ODT, ENRGS, SCALES, SAT) renormalizes the contrast of
%   ODT given energies ENRGS as returned by a call to LIC.  If the texture
%   passed to LIC was a multiscale noise texture, then SCALES must be
%   passed as well.  SAT is the amount to saturate (greater than 1
%   specifies more saturation, less than 1 specifies less, with a default
%   of 1).
%
%   See also LIC, MULTISCALENOISE, SATURATECONTRAST.

function sat = saturateLic(odt, energies, scales, satKnob)

if ~exist('satKnob', 'var')
  satKnob = 1;
end

alpha = 5/(12*sqrt(2));
lmxbSize = [0.4323 1.7779];
lmxbEnrg = [0.3438 0.0625];
lineFun = @(p,x) p(1).*x + p(2);
intx = 0.2224;

energyCoefsSmall = alpha.*sqrt(energies).*(energies < intx);
energyCoefsLarge = lineFun(lmxbEnrg, energies).*(energies >= intx);
if nargin > 2
  scalesCoefs = lineFun(lmxbSize, scales);
else
  scalesCoefs = 1;
end
contrastCoefs = (energyCoefsSmall + energyCoefsLarge).*scalesCoefs;
sat = saturateContrast(odt, contrastCoefs/satKnob);