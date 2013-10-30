function [ts, cs] = isophoteFlow(f, sigma)

if ~exist('sigma', 'var')
  sigma = 1;
end

if size(f, 3) == 3
  f = convertToGrayscale(f);
end

[gxs, gys] = imageGradient(f, sigma);
ts = atan2(-gxs, gys);
cs = sqrt(gxs.^2 + gys.^2);
