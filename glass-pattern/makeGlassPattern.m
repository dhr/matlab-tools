function p = makeGlassPattern(transform, imSize, varargin)
%MAKEGLASSPATTERN Create a Glass pattern.
%   P = MAKEGLASSPATTERN(TRANSFORM, IMSIZE, ...) creates a Glass pattern P
%   based on the transform function TRANSFORM, with size IMSIZE. Additional
%   parameters are options in a property/value pair format.
%
%   TRANSFORM is the transform function to use. It should be a function
%   handle taking an Nx2 array of points as input and outputting an Nx2
%   array of transformed dots. The transforms.m file loads function handles
%   providing constructors for basic transformations (expansion, rotation,
%   translation).
%
%   IMSIZE is the size of the image, either as a scalar or as a standard
%   two element size vector.
%
%   Additional parameters consist of property/value pairs. Valid properties
%   are:
%
%     'Density': The overall density of initial dots in the pattern. Should
%       be a value between 0 and 1 representing the approximate number of
%       dots per square pixel that will be used as the initial dot set.
%       Default value is 0.005.
%
%     'DotSizes': The size (diameter) of the dots to draw. Default is 2.
%
%     'InitialPoints': An n x 2 array containing a list of the initial
%       points to include in the glass pattern.
%
%     'PatVal': The intensity (or color) of the pattern background. Default
%       is 1 (white).
%
%     'Background': An image to use as the background.
%
%     'DotVals': The intensity of the dots (or indices into a colormap if
%       one is provided). Default is 0 (black).
%
%     'ColorMap': A colormap used to interpret the 'DotVals' parameter.
%
%     'NumIts': The number of times to apply the transformation. Default is
%       1, resulting in dot pairs (initial dots plus a single copy).
%
%     'UseAperture': Whether to use a circular aperture to window the
%       resulting pattern. Default is false.
%
%     'StartWithGrid': Generate initial dot placements by using a grid and
%       then randomly offsetting the grid points by an amount modulated by
%       'JitterScale' in a random direction. Defaults is true.
%
%     'GridOffset': Offset the grid by a fraction of the grid spacing in
%       the horizontal and vertical directions. The value should be a two
%       element vector [x y], specifying the amounts to shift in the x and
%       y directions as fractions of the horizontal and vertical grid
%       spacings. Defaults to [0 0].
%
%     'JitterScale': The amount to modulate offsetting when 'StartWithGrid'
%       is true. Defaults to 1.
%
%     'Mask': A logical mask used to mask the glass pattern. No points in
%       locations where mask is false will be drawn. Defaults to
%       true(IMSIZE).
%
%   See also basicGlassTransforms, mapTransform, sinTransform,
%     genRandom2DPoints.

if numel(imSize) < 2
  imSize = [imSize imSize];
end

parsearglist({'density', 'dotSizes', 'patVal', 'background', ...
  'dotVals', 'colorMap', 'numIts', 'useAperture', 'initialPoints', ...
  'startWithGrid', 'gridOffset', 'jitterScale', 'mask'}, varargin);
argdefaults('density', .02, 'dotSizes', 2, 'patVal', 1, 'dotVals', 0, ...
  'background', [], 'colorMap', [], 'numIts', 1, 'useAperture', false, ...
  'initialPoints', [], 'startWithGrid', true, 'gridOffset', [0 0], ...
  'jitterScale', 1, 'mask', true(imSize));

height = imSize(1);
width = imSize(2);

if ~isempty(initialPoints) %#ok<*NODEF>
  ndots = size(initialPoints, 1);
  
  x1s = initialPoints(:,1);
  y1s = initialPoints(:,2);
else
  density = density/(numIts + 1);
  ndots = round(density*width*height);
  
  ptsArgs = {width, height, ndots, startWithGrid, gridOffset, jitterScale};
  [x1s y1s] = genRandom2DPoints(ptsArgs{:});
end

pts = [x1s y1s];
transPts = pts;

for i = 1:numIts
  transPts = transform(transPts); % transform the dots
  pts = [pts; transPts]; %#ok<AGROW>
end

xs = pts(:,1);
ys = pts(:,2);

if useAperture
  inside = xs.^2/width^2 + ys.^2/height^2 < .25;
else
  inside = true(size(pts, 1), 1);
end

is = ceil(height/2 - ys + 1);
js = ceil(xs + width/2);
inside = inside & is > 0 & is <= height & js > 0 & js <= width;
is(~inside) = 1;
js(~inside) = 1;
indices = sub2ind(imSize, is, js);
inside = inside & mask(indices);
indices(~inside) = [];

if ~isscalar(dotSizes) && length(dotSizes) ~= length(indices)
  dotSizes = dotSizes(indices);
end

xs = xs(inside) + width/2;
ys = ys(inside) + height/2;

if numel(dotVals) == numIts + 1
  dotVals = reshape(repmat(dotVals(:)', size(xs, 1), 1), [], 1);
elseif numel(dotVals) == size(x1s, 1)
  dotVals = repmat(dotVals(:), numIts + 1, 1);
  dotVals = dotVals(inside);
elseif numel(dotVals) == size(pts, 1)
  dotVals = dotVals(inside);
elseif size(dotVals,1) == imSize(1) && size(dotVals,2) == imSize(2)
  if size(dotVals, 3) == 3
    off = prod(imSize);
    colorMap = [dotVals(indices) ...
                dotVals(indices + off) ...
                dotVals(indices + 2*off)];
    dotVals = (1:size(colorMap, 1))';
  else
    dotVals = dotVals(indices);
  end
elseif ~isscalar(dotVals)
  error('Incorrect number of dot values supplied.');
end

if ~isempty(colorMap)
  if isempty(background)
    if isscalar(patVal)
      patVal = repmat(patVal, 3, 1);
    end
    patVal = shiftdim(patVal(:), -2);
    p = repmat(patVal, imSize);
  else
    if size(background) == 1
      background = repmat(background, [1 1 3]);
    end
    
    p = background;
  end
  
  p = drawCircle(p, [xs ys], dotSizes/2, dotVals, colorMap);
else
  if isempty(background)
    p = zeros(imSize) + patVal;
  else
    p = background;
  end
  
  p = drawCircle(p, [xs ys], dotSizes/2, dotVals);
end
