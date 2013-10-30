function varargout = dimdeal(array, dim)

varargout = cell(1, min(size(array, dim), nargout));
index = num2cell(repmat(':', 1, ndims(array)));
for i = 1:length(varargout)
  index{dim} = i;
  varargout{i} = array(index{:});
end
