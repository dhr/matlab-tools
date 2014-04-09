function out = makeCircularMask(sz, rad)

if isscalar(sz)
  sz = [sz sz];
end

[xs, ys] = meshgrid(linspace(-1, 1, sz(2)) * (sz(2) - 1)/2, ...
                    linspace(1, -1, sz(1)) * (sz(1) - 1)/2);
out = (xs.^2 + ys.^2) <= rad.^2;
