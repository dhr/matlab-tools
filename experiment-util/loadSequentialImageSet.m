function [images ids] = loadSequentialImageSet(baseName, ns, grayScale)

if nargin < 2
  ns = [];
end

if nargin < 3
  grayScale = false;
end

[path name ext] = fileparts(baseName);

if isempty(ext)
  ext = '.png';
end

dirListing = dir(path);
dirListing = {dirListing.name};
nameRegEx = regexprep(name, '#', '(\\d+)');
[matches numbers] = regexp(dirListing, [nameRegEx ext], 'start', 'tokens');
matches = cellfun('isempty', matches);
matchIndices = find(~matches);

if isempty(matchIndices)
  error(['Could not find any files derived from ' name ' containing images.']);
end

total = numel(matchIndices);
if ~isempty(ns)
  images = cell(numel(ns), 1);
else
  ns = sort(cellfun(@str2double, cellfun(@(x) cell2mat([x{:}]), numbers, 'UniformOutput', false)));
  images = cell(total, 1);
end

for i = matchIndices
  curid = str2double(numbers{i}{1});
  
  if ~isempty(curid)
    imIndx = find(curid == ns);
  else
    imIndx = 1;
  end
  
  for j = imIndx(:)'
    images{j} = double(imread([path filesep dirListing{i}]))/255;
    if grayScale
      images{j} = mean(images{j}, 3);
    end
    
    if ~isempty(curid)
      ids(j) = curid; %#ok<AGROW>
    end
  end
end