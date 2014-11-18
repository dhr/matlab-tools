function vs = genPlane(d, nxv, nyv, vp, vd, vu, h, v)
%GENPLANE Generates a plane perpendicular to the viewing direction.
%   [VS TRIS] = GENPLANE(D, NXV, NYV, VP, VD, VU, H, V) generates a plane
%   at distance D from the the viewpoint VP, perpendicular to the viewing
%   direction VD, oriented such that the edges of the plane are parallel to
%   the view up vector VU and wide enough so that it would fill the entire
%   screen if viewed with viewing angles H and V (horizontal and vertical
%   respectively, in degrees).  NXV and NYV specify how to discretize the
%   plane (i.e., how many "stripes" the plane is sliced into horizontally
%   and vertically).  VS, the resulting vertices are returned.
%
%   See also TRISFROMDEPTHMAP, GENDEFORMATIONS.

vd = vd/norm(vd);
vu = vu/norm(vu);

vr = cross(vd, vu);

maxX = d*tan(h*pi/180/2);
maxY = d*tan(v*pi/180/2);

xs = linspace(-maxX, maxX, nxv);
ys = linspace(-maxY, maxY, nyv);

[xs ys] = meshgrid(xs, ys);

vs = bsxfun(@plus, bsxfun(@times, xs(:), vr(:)') + ...
     bsxfun(@times, ys(:), vu(:)'), vp(:)' + vd(:)'*d);