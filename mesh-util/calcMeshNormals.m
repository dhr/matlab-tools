%CALCMESHNORMALS Calculate the normals for each vertex of a mesh.
%   N = CALCMESHNORMALS(VS, TRIS) calculates the normals for each vertex of
%   the mesh consisting of vertices VS and faces TRIS.
%
%   VS should be a 3 x m matrix of doubles describing the vertices.
%
%   TRIS should be a 3 x n matrix of unsigned integers acting as indices
%   into the VS matrix.  Indexing should begin at 0, not 1.
%
%   N will be a 3 x m matrix of doubles containing the normals
%   corresponding to each vertex.
%
%   See also NORMALSFROMMESH.