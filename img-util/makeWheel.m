function h = makeWheel(sz)

[xs ys] = meshgrid(linspace(-sz/2, sz/2, sz), linspace(sz/2, -sz/2, sz));
h = atan2(ys, xs);
