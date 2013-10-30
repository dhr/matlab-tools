function [I, temp] = unfilter(Iks, Fs)

if ~isstruct(Fs)
  if ~iscell(Fs)
    Fs = {Fs};
  end
  
  for i = 1:numel(Fs)
    Fs{i} = rot90(Fs{i}, 2);
  end
end

[I, temp] = unconvolve(Iks, Fs);
