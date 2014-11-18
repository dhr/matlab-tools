function f = bezier(varargin)

if nargin == 1
  f = @(t) varargin{1};
else
  lower = bezier(varargin{1:end - 1});
  upper = bezier(varargin{2:end});
  f = @(t) bsxfun(@times, 1 - t(:), lower(t)) + bsxfun(@times, t(:), upper(t));
end
