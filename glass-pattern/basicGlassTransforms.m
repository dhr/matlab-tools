function x = basicGlassTransforms
%basicGlassTransforms Returns basic transforms for use in Glass patterns.
%   X = basicGlassTransforms() returns a structure X containing function
%   handles. These handles act as 'constructors' to create function handles
%   suitable for use as transformations in the createGlassPattern function.
%   X has three handles of the following forms:
%
%     X.rotation(theta) creates a rotation transformation handle that
%     rotates input points by theta.
%
%     X.expansion(amt) creates an expansion transformation handle that
%     expands (scales) input points by an amount amt.
%
%     X.translation(amt, theta) creates a translation transformation handle
%     that translates input points by an amount amt in the direction theta.
%
%   See also createGlassPattern, mapTransform.

x.rotation = @(t) @(ps) ps*[cos(t) sin(t); -sin(t) cos(t)];
x.expansion = @(x) @(ps) ps*x;
x.translation = @(dir, amt) @(ps) bsxfun(@plus, ps, amt*[cos(dir) sin(dir)]);
