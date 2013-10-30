function [Is, Fs] = multifilter(img, Fs, type)

if ~iscell(Fs)
  Fs = {Fs};
end

if ~exist('type', 'var')
  type = 'circular';
end

Is = zeros([size(img) size(Fs)]);

for i = 1:numel(Fs)
  inds = cell(ndims(Fs), 1);
  [inds{:}] = ind2sub(size(Fs), i);
  Is(:,:,inds{:}) = imfilter(img, Fs{i}, type);
end
