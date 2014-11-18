function img = equiluminate(img, targlum, mask, channels, coeffs, gammas)

if ~exist('channels', 'var')
  channels = [1 2 3];
end

if ~exist('coeffs', 'var')
  coeffs = [.2126 .7152 .0722];
end
coeffs = coeffs(:);

if ~exist('gammas', 'var')
  gammas = 2.2;
end

if ~exist('mask', 'var')
  mask = true(size(img, 1), size(img, 2));
end

notChannels = true(1, 3);
notChannels(channels) = false;

img = bsxfun(@power, img, shiftdim(gammas(:), -2));
if any(notChannels)
  notChanCoeffs = coeffs(notChannels);
  notChanCoeffs = shiftdim(notChanCoeffs(:), -2);
  notChanLums = sum(bsxfun(@times, notChanCoeffs, img(:,:,notChannels)), 3);
else
  notChanLums = 0;
end
chanCoeffs = coeffs(channels);
chanCoeffs = shiftdim(chanCoeffs(:), -2);
chanLums = sum(bsxfun(@times, chanCoeffs, img(:,:,channels)), 3);
scalings = (targlum - notChanLums)./chanLums;
maxScaling = min(col(1./img(bsxfun(@and, mask, shiftdim(~notChannels(:), -2)))));
if max(scalings(mask)) > maxScaling
  scalings = scalings*maxScaling/max(scalings(mask));
end
img(:,:,channels) = bsxfun(@times, img(:,:,channels), scalings);
img = bound(img, 0, 1);
img = bsxfun(@power, img, shiftdim(1./gammas(:), -2));
