function stimImg = createSolidMaskImgs(shapeData, varargin)

parsearglist({'brightnesses'}, varargin);
argdefaults('brightnesses', 1);

stimImg = repmat(struct('img', []), length(brightnesses));

for i = 1:length(brightnesses)
  stimImg(i).img = shapeData.mask*brightnesses(i);
end