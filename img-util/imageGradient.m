function [gx, gy, Fs] = imageGradient(img, sigma)

if ~exist('sigma', 'var')
  sigma = 1/2;
end

if sigma == 0
  sigma = eps;
end

Fs = gradientFilter(sigma);

gs = multifilter(img, Fs);
gx = gs(:,:,1);
gy = gs(:,:,2);
