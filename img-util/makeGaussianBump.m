function out = makeGaussianBump(sz, sigma)

if isscalar(sz)
  sz = [sz sz];
end

[xs, ys] = meshgrid(linspace(-1, 1, sz(2)), linspace(1, -1, sz(1)));
out = exp(-(xs.^2 + ys.^2)/(2*sigma^2));
