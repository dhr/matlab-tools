function [img, alpha] = readColor(filename)

[img, ~, alpha] = imread(filename);
img = im2double(img);
alpha = im2double(alpha);
