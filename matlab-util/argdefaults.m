function argdefaults(varargin)
%ARGDEFAULTS Assign default values to arguments.
%   ARGDEFAULTS('argname', DEFAULTVAL, ...) checks whether the variable
%   'argname' exists in the caller's workspace, and assigns it the value
%   DEFAULTVAL if it does not.  Note that 'argname' must be a string.  This
%   is more robust than checking nargin for assigning default values to
%   arguments, since if the order of variables changes in the function
%   signature, then all corresponding nargin checks must be renumbered.

l = length(varargin);

if mod(l, 2)
  error('Input should be pairs of argument names and their default values.');
end

for i = 1:2:l
  if ~evalin('caller', ['exist(''' varargin{i} ''', ''var'')'])
    assignin('caller', varargin{i}, varargin{i + 1});
  end
end