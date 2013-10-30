function img = modulateChroma(img, c, coeffs, gammas)

if ~exist('coeffs', 'var')
  coeffs = [.2126 .7152 .0722];
end

if ~exist('gammas', 'var')
  gammas = 2.2;
end

c(c >= 1) = 1 - eps;

img = bsxfun(@power, img, shiftdim(gammas(:), -2));

r = img(:,:,1);
g = img(:,:,2);
b = img(:,:,3);

d = coeffs(1);
e = coeffs(2);
f = coeffs(3);

l = d*r + e*g + f*b;

x = b - (r + g)/2;
y = r - g;
mag = sqrt(x.^2 + y.^2);
ch = x./mag;
sh = y./mag;

ch(mag == 0) = 0;
sh(mag == 0) = 0;

rccoeff = f*ch - (e + f/2)*sh;
gccoeff = f*ch - (e + f/2 - 1)*sh;
bccoeff = (f - 1)*ch - (e + (f - 1)/2)*sh;

maxcs = cat(3, ...
  (l - (rccoeff < 0))./rccoeff, ...
  (l - (gccoeff < 0))./gccoeff, ...
  (l - (bccoeff < 0))./bccoeff);

c = c.*min(maxcs, [], 3);
c(~isfinite(c)) = 0;

r = l - c.*rccoeff;
g = l - c.*gccoeff;
b = l - c.*bccoeff;

img = cat(3, r, g, b);
img = bsxfun(@power, img, shiftdim(1./gammas(:), -2));
