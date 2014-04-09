function out = differenceOfGaussian(img, sigma1, sigma2, channels)

if ~exist('channels', 'var')
  channels = repmat((1:size(img, 3))', [1 2]);
end

size1 = ceil(6*sigma1) + 1;
size2 = ceil(6*sigma2) + 1;

out = zeros([size(img, 1) size(img, 2) size(channels, 1)]);

for i = 1:size(channels, 1)
  out(:,:,i) = filter2(fspecial('gaussian', size1, sigma1), img(:,:,channels(i,1))) - ...
               filter2(fspecial('gaussian', size2, sigma2), img(:,:,channels(i,2)));
end
