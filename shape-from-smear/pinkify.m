function pinked = pinkify(im)

[nrows ncols] = size(im);
[js is] = meshgrid(linspace(-ncols/2, ncols/2, ncols), linspace(-nrows/2, nrows/2, nrows));
falloff = 1./sqrt(is.^2 + js.^2).^1.5;
falloff(falloff > 1) = 1;
imFft = fft2(im);
pinked = normalizeContrast(abs(ifft2(imFft.*fftshift(falloff))));