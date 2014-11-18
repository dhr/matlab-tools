%DEPTHSFROMSPARSENORMALS Reconstruct z-values for a set of sparse normals.
%   [D OX OY INVDS] = DEPTHSFROMSPARSENORMALS(X, Y, N, TRIS, F, INVDS)
%   reconstructs the depth values D of a set of vertices given their
%   x-coordinates X, y-coordinates Y, and normals N.  Edges between
%   vertices are specified by the triangle-list TRIS.  The reconstruction
%   is perspective correct for a focal length of F if F is non-zero and
%   finite.  If F is non-finite, then reconstruction is correct for an
%   orthographic projection model.
%
%   X and Y should be M x 1 lists of x- and y-coordinates, on the image
%   plane.
%   
%   N should be an M x 3 list of normals corresponding to the coordinates
%   given by X and Y.
%
%   TRIS should be a P x 3 list of indices into X, Y, and N.  Each row of
%   TRIS specifies a triangle.
%
%   F is the (negative of the) z-coordinate of the view-point.  In
%   otherwords, the view-point is located at (0, 0, -F).  If F is
%   non-finite, orthographically correct reconstruction is performed.
%
%   INVDS is the inverse of the difference matrix.  Passing this can speed
%   computations drastically if orthographic reconstruction is being
%   performed.  If perspective-correct reconstruction is being performed,
%   it has no effect (it must be recomputed for every change in a normal).
%   Passing the empty matrix will force a recomputation of INVDS (which can
%   be recovered from the output parameter of the same name).
%
%   D is an M x 1 matrix containing the reconstructed depths. 
%
%   OX and OY are the output coordinates (different from X and Y only when
%   perspective-correct reconstruction is being performed).  X and Y are
%   the projections of vertices located at [OX OY D] gives the image
%   coordinates X and Y.

function [depths xs ys invdiffs] = depthsFromSparseNormals(xs, ys, ns, tris, f, invdiffs)

if nargin < 5
  f = inf;
end

if nargin < 6
  invdiffs = [];
end

edges = [tris(:,1) tris(:,2); tris(:,1) tris(:,3); tris(:,2) tris(:,3)];
edges = sort(edges, 2);
edges = unique(edges, 'rows');
edges = [edges; fliplr(edges)];

numEdges = size(edges, 1);
indxs = 1:numEdges;

is = edges(indxs,1);
js = edges(indxs,2);

tdxs = xs(js) - xs(is);
tdys = ys(js) - ys(is);

estdzs = zeros(numEdges + 1, 1);
estdzs(end) = 0.55;

perspReconstruct = f && isfinite(f);
if perspReconstruct || isempty(invdiffs)
  numXs = size(xs, 1);
  colStarts = (1:numEdges + 1:(numXs - 1)*(numEdges + 1) + 1) - 1;
  diffmat = zeros(numEdges + 1, numXs);
  diffmat(end,:) = 1/numXs;
end

if ~perspReconstruct
  estdzs(indxs) = (tdxs.*ns(is,1) + tdys.*ns(is,2))./ns(is,3);

  if isempty(invdiffs)
    diffmat(indxs + colStarts(is)) = 1;
    diffmat(indxs + colStarts(js)) = -1;
    invdiffs = pinv(diffmat);
  end
else
  estdzs(indxs) = -f*(tdxs.*ns(is,1) + tdys.*ns(is,2));
  
  diffmat(indxs + colStarts(is)) = -(ns(is,1).*xs(is) + ns(is,2).*ys(is) + f*ns(is,3));
  diffmat(indxs + colStarts(js)) = (ns(is,1).*xs(js) + ns(is,2).*ys(js) + f*ns(is,3));
  invdiffs = pinv(diffmat);
end

depths = invdiffs*estdzs;
depths = reshape(depths, size(xs));

if perspReconstruct
  xs = xs.*depths/f;
  ys = ys.*depths/f;
end