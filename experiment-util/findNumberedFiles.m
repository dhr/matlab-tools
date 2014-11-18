function [ns names] = findNumberedFiles(baseName)

[path name ext] = fileparts(baseName);

dirListing = dir(path);
dirListing = {dirListing.name};
nameRegEx = regexprep(name, '#', '(\\d+)');
[matches numbers] = regexp(dirListing, [nameRegEx ext], 'start', 'tokens');
matches = cellfun('isempty', matches);
matchIndices = find(~matches);

if isempty(matchIndices)
  ns = [];
  names = {};
  return;
end

ns = zeros(1, length(matchIndices));
for i = 1:length(matchIndices)
  num = str2double(numbers{matchIndices(i)}{1});
  ns(i) = num;
end

if nargout > 1
  names = dirListing(matchIndices);
end
