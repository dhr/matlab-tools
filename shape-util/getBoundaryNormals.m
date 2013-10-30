function [x, y, nx, ny] = getBoundaryNormals(mask)
%GETBOUNDARYNORMALS Returns the set of edge normals given a mask.
%   [X Y NX NY] = GETBOUNDARYNORMALS(MASK) returns the set of edge points
%   (X and Y) and the associated normal vectors (NX and NY) given a mask
%   MASK.
%
%   MASK should be a mask containing ones and zeros to indicate the
%   presence and absence of some entity, respectively.
%
%   X and Y return the x and y coordinates of points on the boundary of the
%   mask.
%
%   NX and NY return the coordinates of vectors normal to the boundary of
%   the mask (and correspond to the X and Y output arguments).

[nrows ncols] = size(mask);

[x, y] = meshgrid(1:ncols, 1:nrows);

g = hamming(25);
g = g*g';

dmask = double(mask);
dx = conv2(dmask, [-1 1], 'same'); 
dy = conv2(dmask, [-1 1]', 'same');
dx = conv2(dx, g, 'same');
dy = conv2(dy, g, 'same');

b = edge(mask);

j = find(b == 1);

nx = dx(j);
ny = dy(j);
x = x(j);
y = y(j);

r = sqrt(nx.^2 + ny.^2);
nx = nx./r;
ny = ny./r;