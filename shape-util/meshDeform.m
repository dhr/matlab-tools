function newVs = meshDeform(vs, deformation, amp, view, renorm)
%MESHDEFORM Contour preserving mesh deformation.
%   NEWVS = MESHDEFORM(VS, DEF, AMP, VIEW, RENORM)
%   deforms the mesh consisting of vertices VS by the deformation
%   DEFORMATION, specified as a m x n matrix consisting of offsets to move
%   vertices, i.e., the image is treated as the viewing plane, and a vertex
%   is shifted along the line of sight by an amount corresponding to the
%   quantity in DEF at the location (in the viewing plane) where the vertex
%   projects to, given the projection type PROJ, the viewing point VP, the
%   view direction VD, the view up vector VU, and the horizontal and
%   vertical fields of view HFOV and VFOV.  The subsequent mesh can
%   optionally be renormalized to fit within a unit cube centered at the
%   origin, though this defaults to false (since it is not guaranteed to
%   preserve contour under perspective projection).
%
%   VS should be an m x 3 matrix, with a vertex in each row.
%
%   DEF should be an "image" of offset values.  This image is treated as
%   the viewing plane, and a vertex is shifted along the line of sight by
%   an amount corresponding to the quantity in DEF at the location (in the
%   viewing plane) where the vertex projects to.
%
%   AMP should be either a scalar specifying the amplitude of deformation
%   to apply, or an array of scalars of length size(VS, 1), specifying the
%   amount of deformation on a per-vertex basis.
%
%   VIEW should be a view parameter structure as returned by
%   makeViewParams.
%
%   RENORM should be a logical value indicating whether to renormalize the
%   resulting mesh to fit within a unit cube centered at the origin.
%   Defaults to false.
%
%   See also GENDEFORMATIONS, MAKEVIEWPARAMS.

if nargin < 10
  renorm = false;
end


[vp, vd, vu, proj, va, width, height] = ...
  deal(view.vp, view.vd, view.vu, view.proj, view.va, view.w, view.h);

vp = vp(:)';
vd = vd(:)';
vr = cross(vd, vu);
[nrows, ncols] = size(deformation);

if strcmpi(proj, 'v')
  perspective = true;
elseif strcmpi(proj, 'l')
  perspective = false;
else
  error('PROJ must be either ''v'' or ''l''.');
end

if perspective
  h = va*pi/180;
  v = 2*atan(height/width*tan(h/2));
  maxX = tan(h/2);
  maxY = tan(v/2);
  vsViewDirs = bsxfun(@minus, vs, vp);
  vsViewDirs = bsxfun(@rdivide, vsViewDirs, sqrt(sum(vsViewDirs.^2, 2)));
  vsViewPlaneIntxScale = 1./sum(bsxfun(@times, vsViewDirs, vd), 2);
  vsViewPlaneIntxs = bsxfun(@times, vsViewDirs, vsViewPlaneIntxScale);
  vsProjXs = sum(bsxfun(@times, vsViewPlaneIntxs, vr), 2)/maxX;
  vsProjYs = sum(bsxfun(@times, vsViewPlaneIntxs, vu), 2)/maxY;
else
  h = va;
  v = height/width*h;
  vsProjXs = (sum(bsxfun(@times, vs, vr), 2) - dot(vp, vr))/(h/2);
  vsProjYs = (sum(bsxfun(@times, vs, vu), 2) - dot(vp, vu))/(v/2);
  vsViewDirs = repmat(vd, size(vs, 1), 1);
end

vsToDeform = abs(vsProjXs) <= 1 & abs(vsProjYs) <= 1;
vsProjIs = round((-vsProjYs(vsToDeform) + 1)/2*(nrows - 1)) + 1;
vsProjJs = round((vsProjXs(vsToDeform) + 1)/2*(ncols - 1)) + 1;
vsProjInds = sub2ind([nrows ncols], vsProjIs, vsProjJs);
vsDeformationDistance = zeros(size(vsToDeform));
vsDeformationDistance(vsToDeform) = deformation(vsProjInds);
newVs = bsxfun(@plus, vs, bsxfun(@times, vsDeformationDistance.*amp(:), vsViewDirs));

if renorm
  newVs(:,1) = newVs(:,1)./max(abs(newVs(:,1)));
  newVs(:,2) = newVs(:,2)./max(abs(newVs(:,2)));
  newVs(:,3) = newVs(:,3)./max(abs(newVs(:,3)));
end