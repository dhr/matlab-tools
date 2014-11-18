function image = imageFromSlantTilt(slants, tilts, opts, backgroundColor)
%IMAGEFROMSLANTTILT Display slants and tilts as an HSV image.
%   IM = IMAGEFROMSLANTTILT(SLANTS, TILTS, OPTS, BGCOLOR) creates an
%   image from SLANTS and TILTS, the S and V channels of which are filled
%   according to OPTS.  The hue channel is filled by TILTS.  Regions where
%   SLANTS or TILTS are NaN are filled with BGCOLOR (default is black).
%   IM is the resulting image, and is in RGB, not HSV.
%
%   OPTS should be a 2 character string.  The first character specifies
%   what should fill the saturation channel.  If OPTS(1) == 's', then
%   SLANTS is used to generate the saturation component of the image.
%   Otherwise, the saturation channel is filled by STR2DOUBLE(OPTS(1)).  If
%   OPTS(2) == 's', then SLANTS is used to generate the values component of
%   the image. Otherwise, the values channel is filled by
%   STR2DOUBLE(OPTS(2)), which should be 1 to display anything at all.
%
%   See also SLANTTILTFROMNORMALS.

if nargin < 4
  backgroundColor = [0 0 0];
end

if length(backgroundColor) == 1
  backgroundColor = repmat(backgroundColor, [3 1]);
end

hues = mod(tilts, 2*pi)/(2*pi);

if opts(1) == 's'
  sats = mod(slants, 2*pi)/(pi/2);
elseif opts(1) == '0' || opts(1) == '1'
  sats = zeros(size(tilts)) + str2double(opts(1));
else
  error('Saturation channel character must be one of {''s'', 0, 1}.');
end

if opts(2) == 's'
  vals = mod(slants, 2*pi)/(pi/2);
elseif opts(2) == '0' || opts(2) == '1'
  vals = zeros(size(tilts)) + str2double(opts(2));
else
  error('Values channel character must be one of {''s'', 0, 1}.');
end

image = hsv2rgb(cat(3, hues, sats, vals));

nonFinites = ~isfinite(image);
image(nonFinites) = 0;
image = image + nonFinites.*repmat(shiftdim(backgroundColor(:), -2), [size(tilts) 1]);