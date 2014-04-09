function [e1xs, e1ys, l1s, l2s] = structureTensor(img, weights, imgsigma)

if isscalar(weights)
  weights = fspecial('gaussian', round(6*weights + 1), weights);
end

if ~exist('imgsigma', 'var')
  imgsigma = 0.5;
end

[gx, gy] = gaussianDiff(img, imgsigma);
gx2 = filter2(weights, gx.^2);
gy2 = filter2(weights, gy.^2);
gxgy = filter2(weights, gx.*gy);

[e1xs, e1ys, l1s, l2s] = eig2x2(gx2, gxgy, gy2);
