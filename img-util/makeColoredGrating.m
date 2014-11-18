function out = makeColoredGrating(color, orientation, phase, nbands, size)

if ~exist('nbands', 'var')
  nbands = 10;
end

if ~exist('size', 'var')
  size = [750 750];
elseif isscalar(size)
  size = [size size];
end

temp = color;
color = cell(1, 3);
for i = 1:3
  a = real(temp(i));
  b = imag(temp(i));
  color{i} = @(x) a*(x - (a < 0)) + b;
end

[rfun, gfun, bfun] = deal(color{:});
g = makeGrating(size, nbands, orientation, phase);
out = cat(3, rfun(g), gfun(g), bfun(g));
