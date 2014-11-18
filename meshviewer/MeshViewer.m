function MeshViewer(mesh, window, varargin)
%MESHVIEWER Views a mesh, allowing interaction via the mouse.
%   MESHVIEWER(MESH, WINDOW, ...) views the mesh MESH, which can either be
%   a filename or a cell array containing at least two elements: the
%   vertices VS and faces TRIS. Optionally the normals NS can also be
%   included.
%
%   VS should be an m x 3 set of vertices.
%
%   TRIS should be an n x 3 set of indices into the VS array, indicating
%   the triangles to be rendered.
%
%   NS should be an m x 3 set of normals corresponding to the VS array.

%   Additional arguments in order: proj, vp, vd, vu, v, lp.

  Screen('Preference', 'SkipSyncTests', 1);
  
  if ischar(mesh)
    [vs, tris, ns] = loadObj(mesh);
  elseif iscell(mesh)
    vs = mesh{1};
    tris = mesh{2};
    if length(mesh) == 3
      ns = mesh{3};
    end
  end

  if ~exist('ns', 'var')
    ns = normalsFromMesh(vs, tris);
  end
  
  arguments = varargin;
  quitKey = KbName('escape');
  uiLoop = [];
  
  if exist('window', 'var') && ~isempty(window)
    BasicUI(@setupFun, @()[], [], window);
  else
    BasicUI(@setupFun);
  end
  
  function setupFun(mainUILoop)
    uiLoop = mainUILoop;
    
    mesh = PTMesh(vs, tris, ns);

    MeshViewerController(uiLoop, mesh, arguments{:});
  
    addlistener(uiLoop.ContainerView, 'KeyUp', @keyUp);
  end
  
  function keyUp(src, event) %#ok<INUSL>
    if event.Delta(quitKey)
      uiLoop.stop;
    end
  end
end
