function r = drawCircles(image, brightness, xs, ys, rads, thickness, fill, aa)

imrows = size(image, 1);
imcols = size(image, 2);

lenxs = numel(xs);
lenys = numel(ys);
lenrs = numel(rads);

npts = max([lenxs lenys lenrs]);

if lenxs ~= npts && lenxs ~= 1 || ...
   lenys ~= npts && lenys ~= 1 || ...
   lenrs ~= npts && lenrs ~= 1
  error(['There cannot be two different lengths greater than ' ...
         '1 among arguments xs, ys, and rads.']);
end

if lenxs == 1
  xs = repmat(xs, [1 1 npts]);
end

if lenys == 1
  ys = repmat(ys, [1 1 npts]);
end

if lenrs == 1
  rads = repmat(rads, [1 1 npts]);
end

if ~exist('aa', 'var')
  aa = 1;
end

if aa == 2
  njitters = 25;
  xjitters = linspace(-2/5, 2/5, 5);
  yjitters = linspace(-2/5, 2/5, 5);
else
  xjitters = 0;
  yjitters = 0;
  njitters = 1;
end

offs = ones(imrows, imcols)*bitmax;
[xgrid ygrid] = meshgrid(0:imcols - 1, imrows - 1:-1:0);
stacks = zeros(imrows, imcols);

jitteri = 1;
for xoff = xjitters
  for yoff = yjitters
    for i = 1:npts
      top = max(imrows - min(ceil(ys(i) + rads(i) + thickness/2), imrows), 1);
      bottom = min(imrows - max(floor(ys(i) - rads(i) - thickness/2 - 1), 1), imrows);
      left = max(floor(xs(i) - rads(i) - thickness/2), 1);
      right = min(ceil(xs(i) + rads(i) + thickness/2 + 1), imcols);
      offs(top:bottom, left:right) = ...
        min(offs(top:bottom, left:right), ...
            sqrt((xgrid(top:bottom, left:right) - xs(i) - xoff).^2 + ...
                 (ygrid(top:bottom, left:right) - ys(i) - yoff).^2) - rads(i));
    end
  
    inside = offs < 0;
    dists = abs(offs);

    overlaps = thickness/2 - dists + 0.5*(aa == 1);

    if aa ~= 1
      overlaps = overlaps > 0;
    end

    if fill
      r = bound(max(overlaps, inside), 0, 1);
    else
      r = bound(overlaps, 0, 1);
    end

    r = image.*(1 - r) + r*brightness;
    stacks = stacks + r;
    jitteri = jitteri + 1;
  end
end

r = stacks/njitters;