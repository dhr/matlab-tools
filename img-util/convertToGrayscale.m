function gray = convertToGrayscale(img)

wts = [.2126 .7152 .0722];
gray = sum(bsxfun(@times, img.^2.2, shiftdim(wts(:), -2)), 3).^(1/2.2);
