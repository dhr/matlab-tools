function unrecognized = parsearglist(paramNames, argList, errorOnUnknownParam)

if nargin < 3
  errorOnUnknownParam = true;
end

if mod(length(argList), 2)
  error('Every named parameter should have a corresponding value.');
end

unrecognized = cell(0, 0);

for i = 1:2:length(argList)
  match = strcmpi(argList{i}, paramNames);
  
  if ~any(match)
    if errorOnUnknownParam
      error('No parameter named %s found.', argList{i});
    else
      unrecognized(end + 1:end + 2) = argList(i:i + 1);
    end
  else
    assignin('caller', paramNames{match}, argList{i + 1});
  end
end
