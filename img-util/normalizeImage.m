function out = normalizeImage(img)
%NORMALIZEIMAGE Normalize an image to have min value 0 and max value 1
%   N = NORMALIZEIMAGE(IMG) normalizes the image IMG, returning N
%   such that min(N(:)) == 0 and max(N(:)) == 1.

out = (img - min(img(:)))/(max(img(:)) - min(img(:)));
