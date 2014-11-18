function M = subsample(M, varargin)

if ndims(M) ~= length(varargin)
  error('Incorrect number of subsample dimensions');
end

center = true;
if islogical(varargin{end})
  center = varargin{end};
  varargin(end) = [];
end

sizes = num2cell(size(M));
subsampler = @(s, n) iif(center, round(mod(n - 1, s)/2) + 1, 1):s:n;
indxs = cellfun(subsampler, varargin, sizes, 'UniformOutput', false);
M = M(indxs{:});
