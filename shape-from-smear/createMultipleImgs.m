function stimImg = createMultipleImgs(shapeData, varargin)

nImages = 10;
unrecognized = parsearglist({'creationFun', 'nImages'}, varargin, false);

if ~exist('creationFun', 'var')
  error('No image creation function specified -- use the ''CreationFun'' parameter name.');
end

stimImg = struct('img', cell(nImages, 1));

for j = 1:nImages
  img = creationFun(shapeData, unrecognized{:});
  stimImg(j).img = img.img;
end