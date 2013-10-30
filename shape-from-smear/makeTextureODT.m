function [todt, mask] = makeTextureODT(shape, r, view, varargin)
%MAKETEXTUREODT Make a texture ODT.
%   [ODT MASK] = MAKETEXTUREODT(SHAPE, R, VIEW, ...) creates a texture ODT
%   for the given shape SHAPE, rotation R, and view parameters VIEW.
%
%   SHAPE should be either the filename of a .obj mesh, a struct containing
%   the fields 'vs', 'tris', and optionally 'ns' (for the vertices,
%   triangles, and normals of the shape), or a shape data structure as
%   returned by MAKESHAPEDATA.
%
%   R should be a set of Euler angles (in degrees) in the format [Z Y X],
%   specifying the rotation to apply to SHAPE. Defaults to [0 0 0]. This is
%   only relevant if SHAPE is not a shape data structure.
%
%   VIEW should be a set of view parameters as returned by MAKEVIEWPARAMS.
%   This is only relevant if SHAPE is not a shape data structure.
%
%   Additional arguments are passed as parameters to CREATETEXTUREODTIMG.
%
%   ODT is then the resulting ODT.
%
%   MASK is the mask of the shape.
%
%   See also MAKEVIEWPARAMS, MAKESHAPEDATA, CREATETEXTUREODTIMG, MAKEODT.

argdefaults('r', [0 0 0], 'view', makeViewParams);

if ischar(shape)
  [vs, tris] = loadObj(shape);
  maxMag = sqrt(max(sum(vs.^2, 2)));
  vs = 0.95*vs/maxMag;
  ns = normalsFromMesh(vs, tris);
  shape = struct('vs', vs, 'tris', tris, 'ns', ns);
end

if isstruct(shape) && isfield(shape, 'vs')
  sd = makeShapeData(shape, r, view);
else
  sd = shape;
end

todt = createTextureODTImg(sd, varargin{:});
todt = todt.img;

mask = sd.mask;
