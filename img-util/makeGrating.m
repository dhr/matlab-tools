function grating = makeGrating(sz, nbands, theta, phase, pos)

if isscalar(sz)
  sz = [sz sz];
end

if ~exist('phase', 'var')
  phase = 0;
end

if ~exist('pos', 'var')
  pos = 0;
end

[xs, ys] = meshgrid(linspace(-pi, pi, sz(2)), linspace(-pi, pi, sz(1)));
rys = sin(theta)*xs + cos(theta)*ys;
grating = sin(nbands*rys + phase);
if pos
  grating = (grating + 1)/2;
end
