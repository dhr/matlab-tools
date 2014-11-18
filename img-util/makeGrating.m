function grating = makeGrating(sz, nbands, theta, phase, pos, fun)

if isscalar(sz)
  sz = [sz sz];
end

if ~exist('phase', 'var')
  phase = 0;
end

if ~exist('pos', 'var')
  pos = 0;
end

if ~exist('fun', 'var')
  fun = @sin;
end

xRange = linspace(-pi*sz(2)/sz(1), pi*sz(2)/sz(1), sz(2));
yRange = linspace(-pi, pi, sz(1));
[xs, ys] = meshgrid(xRange, yRange);
rys = sin(theta)*xs + cos(theta)*ys;
grating = fun(nbands*rys + phase);
if pos
  grating = (grating + 1)/2;
end
