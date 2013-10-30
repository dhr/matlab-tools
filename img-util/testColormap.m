function testColormap(cmap, n, size, gray)

if ~exist('n', 'var')
  n = 1;
end

if ~exist('size', 'var')
  size = [500 500];
end

if ~exist('gray', 'var')
  gray = false;
end

if isscalar(size)
  size = [size size];
end

gradient = repmat(linspace(0, 1, round(size(2)/n)), size(1), n);
img = applyColormap(gradient, cmap);
if gray
  img = convertToGrayscale(img);
end
imshow(img);
