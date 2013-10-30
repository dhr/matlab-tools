function grad = makeRotatedGradient(theta, size, pos)

if ~exist('size', 'var')
  size = [400 400];
elseif isscalar(size)
  size = [size size];
end

if ~exist('pos', 'var')
  pos = true;
end

[xs, ys] = meshgrid(linspace(-1, 1, size(2)), linspace(1, -1, size(1)));
grad = -sin(theta)*xs + cos(theta)*ys;

if pos
  grad = (grad + 1)/2;
end
