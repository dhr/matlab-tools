function h = blurDirs(h, sigma)

xs = cos(h);
ys = sin(h);

filt = fspecial('gaussian', 6*sigma + 1, sigma);
blurXs = filter2(filt, xs);
blurYs = filter2(filt, ys);
h = atan2(blurYs, blurXs);
