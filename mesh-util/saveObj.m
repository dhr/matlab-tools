function saveObj(name, vs, tris, ns)
%SAVEOBJ Save a set of vertices and triangles as an OBJ file.
%   SAVEOBJ(NAME, VS, TRIS, NS) saves the mesh described by vertices VS,
%   faces TRIS, and optionally normals NS into the file with filename NAME.
%
%   NAME is the filename in which to save the OBJ file.
%
%   VS is an m x 3 matrix of vertex coordinates.
%
%   TRIS is an n x 3 matrix of vertex indices.
%
%   NS should be an m x 3 matrix containing the normals for the mesh.  This
%   argument is optional.

if nargin < 4
  ns = [];
end

if size(vs, 2) ~= 3 || size(tris, 2) ~= 3 || ~isempty(ns) && size(ns, 2) ~= 3
  error('Shape data should consist of n x 3 matrices.');
end

writeObj(name, vs', tris', ns');
