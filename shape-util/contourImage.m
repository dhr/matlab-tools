function c = contourImage(depths, thresh)

[dx dy] = gradient(depths);
mags = sqrt(dx.^2 + dy.^2) < thresh;
c = double(mags);