function blurred = gaussianBlur(image, sigma, method)

if ~exist('method', 'var')
  method = 'replicate';
end

blurred = imfilter(image, fspecial('gaussian', 6*sigma, sigma), method);
