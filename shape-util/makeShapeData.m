function shapeData = makeShapeData(shapes, rs, view, varargin)
%MAKESHAPEDATA Computes shape data used by ODT generation procedures.
%   SD = MAKESHAPEDATA(SHAPES, RS, VIEW, ...) returns a shape data
%   structure containing information used by ODT generation procedures
%   (including dense normal fields, foreshortening information, specular
%   compression information, and a mask).
%
%   SHAPES should be a shape structure containing the fields 'vs', with the
%   vertices, 'tris', with triangle information, and optionally 'ns', with
%   vertex normals. Alternatively it can be the file name of a shape in
%   .obj format. It can also be a cell array containing the vertices,
%   triangles, and optionally normals (in that order). A cell array of such
%   structures, names, or other cell arrays can also be provided to
%   generate multiple shape data objects.
%
%   RS is a set of Euler rotation angles (in degrees) in format [Z Y X].
%   These angles are to rotate the shape. A cell array of such angles may
%   be provided if multiple shape structures are provided in SHAPES, with
%   each cell of RS providing the rotation angles to use for the
%   corresponding element in SHAPES.
%
%   VIEW is a view object as returned by MAKEVIEWPARAMS.
%
%   Additional arguments are property/value pairs. Valid properties are:
%
%     'CalcForeshortening': Include foreshortening information in the shape
%       data structure. Defaults to true.
%
%     'CalcSpecCompression': Include specular compression information in
%       the shape data structure. Defaults to false.
%
%     'Window': Use a preexisting PsychToolbox window handle for make the
%       OpenGL calls used to calculate the shape data.
%
%   SD will be an array of structs containing the shape data information
%   corresponding to the elements of SHAPES.
%
%   See also MAKEVIEWPARAMS, GETDENSEMESHINFO.

parsearglist({'useRadiance', 'calcForeshortening', ...
              'calcSpecCompression', 'window'}, varargin);
argdefaults('rs', [0 0 0], 'view', makeViewParams, ...
            'useRadiance', false, 'calcForeshortening', true, ...
            'calcSpecCompression', false);

closeWindow = false;
if ~exist('window', 'var')
  InitializeMatlabOpenGL;
  window = Screen('OpenWindow', min(Screen('Screens')));
  closeWindow = true;
end
          
if isstruct(shapes)
  shapes = num2cell(shapes);
end

if ~iscell(shapes) || ~isstruct(shapes{1})
  shapes = {shapes};
end

if ~iscell(rs)
  rs = {rs};
end

nShapes = length(shapes);

if length(rs) == 1
  rs = repmat(rs, nShapes, 1);
end

if length(view) == 1
  view = repmat(view, nShapes, 1);
end

shapeData = repmat(struct('shapeID', [], 'rot', [], 'view', [], ...
                          'normals', [], 'depths', [], 'mask', []), ...
                   nShapes, 1);

for i = 1:nShapes
  mesh = shapes{i};
  
  if ~isstruct(mesh)
    if length(mesh) == 3
      ns = mesh{3};
    else
      ns = normalsFromMesh(mesh{1}, mesh{2});
    end
    mesh = struct('vs', mesh{1}, 'tris', mesh{2}, 'ns', ns);
  end

  r = rs{i};

  vd = view(i).vd;
  vu = view(i).vu;
  proj = view(i).proj;
  va = view(i).va;
  w = view(i).w;
  h = view(i).h;

  if ischar(mesh)
    [vs, tris] = loadObj(mesh);
    ns = normalsFromMesh(vs, tris);
    mesh = struct('vs', vs, 'tris', tris, 'ns', ns);
  end

  if length(r) ~= 4
    r = r*pi/180;
    quat = angle2quat(r(1), r(2), r(3));
  else
    quat = r;
  end
  [normals, depths] = renderDenseMeshInfo(mesh, quat, view(i), window);

  mask = squeeze(sum(normals.^2) ~= 0);
      
  [rays, du, dv, covUs, covVs] = makeViewRays(h, w, proj, vd, vu, va);
  viewRays = struct('rays', rays, 'du', du, 'dv', dv, ...
                    'covUs', covUs, 'covVs', covVs);
  
  if calcForeshortening
    [majDirs, majLens, minDirs, minLens] = ...
      foreshorteningFromNormals(normals, proj, vd, vu, rays);
    foreshortening = struct('majDirs', majDirs, 'majLens', majLens, ...
                            'minDirs', minDirs, 'minLens', minLens);
  end
  
  if calcSpecCompression
    [minDirs, minSpds, maxSpds] = ...
      specularCompressions(normals, 5, rays, du, dv, covUs, covVs, mask);
    specCompression = struct('minDirs', minDirs, 'minSpds', minSpds, ...
                             'maxSpds', maxSpds);
  end
  
  shapeData(i).shapeID = shapes{i};
  shapeData(i).rot = r;
  shapeData(i).view = view(i);
  shapeData(i).normals = normals;
  shapeData(i).depths = depths;
  shapeData(i).mask = mask;
  shapeData(i).viewRays = viewRays;
  
  if calcForeshortening
    shapeData(i).foreshortening = foreshortening;
  end
  
  if calcSpecCompression
    shapeData(i).specCompression = specCompression;
  end
end

if closeWindow
  Screen('Close', window');
end
