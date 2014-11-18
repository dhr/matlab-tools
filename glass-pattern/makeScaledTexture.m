function tex = makeScaledTexture(radii, ncircles)

[nrows ncols] = size(radii);
randpts = rand(ncircles, 2);
randpts = floor(bsxfun(@times, randpts, [nrows ncols]));
colors = rand(ncircles, 1);
tex = drawCircle(rand(nrows, ncols), randpts, radii, colors);
