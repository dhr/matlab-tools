function viewMesh(vs, tris)
%VIEWMESH View a triangular mesh.
%   VIEWMESH(VS, TRIS) views the mesh with vertices VS and faces defined by
%   TRIS (a matrix of indices) with some good default viewing conditions
%   and lighting.

trisurf(tris, vs(:,1), vs(:,2), vs(:,3), 'EdgeColor', 'none', 'FaceColor', [0.8 0.8 0.8], 'FaceLighting', 'phong');
light;
axis equal;