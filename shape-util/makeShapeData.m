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
  shape = shapes{i};
  
  if ~isstruct(shape)
    if length(shape) == 3
      ns = shape{3};
    else
      ns = normalsFromMesh(shape{1}, shape{2});
    end
    shape = struct('vs', shape{1}, 'tris', shape{2}, 'ns', ns);
  end

  r = rs{i};

  vp = view(i).vp;
  vd = view(i).vd;
  vu = view(i).vu;
  proj = view(i).proj;
  va = view(i).va;
  w = view(i).w;
  h = view(i).h;

  if useRadiance && ischar(shape)
    if proj ~= 'v'
      error('Orthographic projection not allowed when using Radiance.');
    end
    formatStr = '-vp %f %f %f -vd %f %f %f -vu %f %f %f';
    viewOptsStr = sprintf(formatStr, [vp vd vu]); %#ok<*UNRCH>
    xformStr = sprintf('-rx %f -ry %f -rz %f', r);
    [intxs, normals] = ...
      manualRender(shape, viewOptsStr, [h w], 'pn', '', xformStr);
    depths = intxsToDists(intxs, vp);
  else
    if ischar(shape)
      [vs, tris] = loadObj(shape);
      ns = normalsFromMesh(vs, tris);
    else
      vs = shape.vs;
      tris = shape.tris;
      if isfield(shape, 'ns')
        ns = shape.ns;
      else
        ns = normalsFromMesh(vs, tris);
      end
    end
    
    if length(r) ~= 4
      r = r*pi/180;
      quat = angle2quat(r(1), r(2), r(3));
    else
      quat = r;
    end
    [normals, depths] = ...
      getDenseMeshInfo(window, [h w], vs, tris, ns, quat, ...
                       proj, vp, vd, vu, va);
  end

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
  
  shapeData(i).shapeID = shape;
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
