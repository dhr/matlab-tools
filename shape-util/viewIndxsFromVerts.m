function [is js] = viewIndxsFromVerts(vs, imSize, proj, vp, vd, vu, h, v)
%VIEWINDXSFROMVERTS Get indices of vertices in image plane of given size.
%   [IS JS] = VIEWINDXSFROMVERTS(VS, SZ, PROJ, VP, VD, VU, H, V) returns
%   indices into an image at the viewing plane of dimensions SZ for each
%   vertex in VS (n x 3), with NaNs where the VS fall outside the viewing
%   plane.  View parameters are specified by PROJ (the projection type),
%   VP, the viewpoint, VD the view direction, VU the view up direction, and
%   H and V for horizontal and vertical fields of view (or image plane
%   dimensions in object space for parallel projection).
%
%   VS should be an n x 3 matrix of vertices.
%
%   SZ should be a two element size vector for the image at the image
%   plane, as would be returned by SIZE.
%
%   PROJ is the projection type, which can be 'v' for perspective
%   projection and 'l' for parallel projection (orthographic).
%
%   VP, VD, and VU are the view point, view direction, and view up vectors,
%   respectively.  These should all be three element vectors.
%
%   H and V are the horizontal and vertical fields of view, in degrees,
%   when PROJ specifies perspective projection.  When the projection type
%   is orthographic, H and V are the dimensions of the viewing plane in
%   object space.

vp = vp(:)';
vd = vd(:)';
vu = vu(:)';
vr = cross(vd, vu);

relVs = bsxfun(@minus, vs, vp);
vsProjUs = sum(bsxfun(@times, relVs, vr), 2);
vsProjVs = sum(bsxfun(@times, relVs, vu), 2);
vsProjDs = sum(bsxfun(@times, relVs, vd), 2);

if strcmpi(proj, 'v')
  us = vsProjUs./vsProjDs/tan(h*pi/180/2);
  vs = vsProjVs./vsProjDs/tan(v*pi/180/2);
else
  us = vsProjUs/(h/2);
  vs = vsProjVS/(v/2);
end

is = round((vs + 1)/2*(imSize(1) - 1) + 1);
is(is <= 0 | is > imSize(1)) = nan;
js = round((us + 1)/2*(imSize(2) - 1) + 1);
js(js <= 0 | js > imSize(2)) = nan;