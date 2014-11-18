function ns = normalsFromMesh(vs, tris)
%NORMALSFROMMESH Calculates normal vectors for a given mesh.
%   NS = NORMALSFROMMESH(VS, TRIS) calculates the normal vectors NS for a
%   mesh consisting of vertices VS and faces TRIS.  This differs from
%   calcMeshNormals only in the transposition of the arguments (both input
%   and output).
%
%   VS should be an m x 3 matrix of vertex coordinates.
%
%   TRIS should be an n x 3 matrix of indices into VS.
%
%   NS will be an m x 3 matrix of normals, corresponding to VS.
%
%   See also CALCMESHNORMALS.

ns = calcMeshNormals(vs', uint32(tris - 1)')';