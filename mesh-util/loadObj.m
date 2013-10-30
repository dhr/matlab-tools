function [vs tris ns] = loadObj(file)
%LOADOBJ Loads a .obj file, returning vertices and faces.
%   [VS TRIS] = LOADOBJ(FILE) loads the .obj file FILE and stores vertices
%   and triangles in VS and TRIS respectively.
%
%   FILE should be a filename (either absolute or relative to the current
%   directory).
%
%   VS is an n x 3 matrix containing the vertices of the loaded mesh
%   object (one vertex per row).
%
%   TRIS is an m x 3 matrix containing the faces of the loaded mesh, one
%   face per row (with each face consisting of a three indices into the VS
%   output argument).
%
%   [VS TRIS NS] = LOADOBJ(FILE) also computes the normals for the mesh
%   returned in VS and TRIS.
%
%   NS is an n x 3 matrix containing the normals of the loaded mesh, one
%   normal per row.
%
%   See also SAVEMESHASOBJ.

sloooooow = exist('readObj', 'file') ~= 3;

if ~sloooooow
  [vs tris] = readObj(file);
else
  initialSize = 5000;
  vs = zeros(initialSize, 3);
  iv = 1;
  tris = zeros(initialSize, 3);
  it = 1;

  fid = fopen(file);
  line = fgetl(fid);
  while ischar(line)
    [tok rem] = strtok(line);
    switch tok
      case 'v'
        if iv > size(vs, 1)
          vs = [vs; zeros(iv - 1, 3)]; %#ok<AGROW>
        end

        fields = textscan(rem, '%n%n%n', 'CollectOutput', true);
        vs(iv,:) = fields{1};
        iv = iv + 1;
      case 'f'
        if it > size(tris, 1)
          tris = [tris; zeros(it - 1, 3)]; %#ok<AGROW>
        end

        fields = textscan(rem, '%s%s%s', 'CollectOutput', true);
        for i = 1:3
          tris(it,i) = str2double(strtok(fields{1}{1,i}, '/'));
        end
        it = it + 1;
    end

    line = fgetl(fid);
  end

  vs = vs(1:iv - 1,:);
  tris = tris(1:it - 1,:);
end

if nargout > 2
  ns = normalsFromMesh(vs, tris);
end