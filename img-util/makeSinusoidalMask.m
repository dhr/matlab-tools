function mask = makeSinusoidalMask(sz, periods, phase, amp, pfun)

if isscalar(sz)
  sz = [sz sz];
end

if isscalar(phase)
  phase = [phase phase];
end

if isscalar(amp)
  amp = [amp amp];
end

if ~exist('pfun', 'var')
  pfun = @sin;
end

[xs, ys] = meshgrid(linspace(-pi, pi, sz(2)), linspace(1, -1, sz(1)));
mask = ys >= (amp(2)*pfun(periods*xs + phase(2)) - 1 + abs(amp(2)));
mask = mask & ys <= (amp(1)*pfun(periods*xs + phase(1)) + 1 - abs(amp(1)));
