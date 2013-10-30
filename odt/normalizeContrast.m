%NORMALIZECONTRAST Stretches an images histogram to fit in the range 0-1.
%   N = NORMALIZECONTRAST(IM, RANGE, R, MASK) rescales IM to such that its
%   minimum value is RANGE(1) and its minimum value is RANGE(2).
%   Furthermore, if R > 0, then an unsharp mask is subtracted from IM,
%   removing low frequency contrast variations.  The smaller R is, the more
%   frequencies are removed.  Only regions in IM corresponding to areas
%   where MASK ~= 0 are affected.  Regions in N (the output) where MASK = 0
%   are set to mean(N(MASK)), after renormalization.  Defaults for R and
%   MASK are 0 and true(size(IM)), respectively.
%
%   See also SATURATECONTRAST.

function normalized = normalizeContrast(image, range, radius, mask)

if nargin < 4
  mask = true(size(image));
end

if nargin < 3
  radius = 0;
end

if nargin < 2
  range = [0 1];
end

if radius > 0
  sigma = sqrt(-radius^2/(2*log(.05)));
  image(~mask) = mean(image(mask));
  image = image - imfilter(image, fspecial('gaussian', 2*radius, sigma), 'replicate');
end

maxval = max(image(mask));
minval = min(image(mask));
normalized = (image - minval)./(maxval - minval)*(range(2) - range(1)) + range(1);
normalized(~mask) = mean(normalized(mask));