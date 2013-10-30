function [xs ys] = genRandom2DPoints(width, height, ndots, ...
                                     useGrid, gridOffset, jitterScale)

argdefaults('useGrid', true, 'gridOffset', [0 0], 'jitterScale', 1);
                                   
if useGrid
  nHorizDots = round(sqrt(ndots*width/height));
  nVertDots = round(sqrt(ndots*height/width));
  hSpacing = width/(nHorizDots + 2);
  vSpacing = height/(nVertDots + 2);
  xStart = hSpacing/2 + gridOffset(1)*hSpacing;
  xEnd = width - (hSpacing - xStart);
  yStart = vSpacing/2 + gridOffset(2)*vSpacing;
  yEnd = height - (vSpacing - yStart);
  xGridPositions = linspace(xStart, xEnd, nHorizDots);
  yGridPositions = linspace(yStart, yEnd, nVertDots);
  yGridPositions = yGridPositions + gridOffset(2)*vSpacing;
  [xs ys] = meshgrid(xGridPositions, yGridPositions);
  ndots = nHorizDots*nVertDots;
  rs = sqrt(rand(ndots, 1));
  ts = 2*pi*rand(ndots, 1);
  xs = xs(:) - width/2 + jitterScale*vSpacing*rs.*cos(ts);
  ys = ys(:) - height/2 + jitterScale*hSpacing*rs.*sin(ts);
else
  xs = rand(ndots, 1)*width - width/2;
  ys = rand(ndots, 1)*height - height/2;
end

if nargout == 1
  xs = [xs ys];
end
