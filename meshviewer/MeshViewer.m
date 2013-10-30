function MeshViewer(vs, tris, ns, varargin)
%MESHVIEWER Views a mesh, allowing interaction via the mouse.
%   MESHVIEWER(VS, TRIS, NS) views the mesh defined by the vertices VS and
%   faces TRIS, optionally including the normals NS.
%
%   VS should be an m x 3 set of vertices.
%
%   TRIS should be an n x 3 set of indices into the VS array, indicating
%   the triangles to be rendered.
%
%   NS should be an m x 3 set of normals corresponding to the VS array.

%   Additional arguments in order: proj, vp, vd, vu, v, lp.

  if ischar(vs)
    [vs, tris, ns] = loadObj(vs);
  end

  if ~exist('ns', 'var')
    ns = normalsFromMesh(vs, tris);
  end
  
  arguments = varargin;
  quitKey = KbName('escape');
  uiLoop = [];
  
  BasicUI(@setupFun);
  
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
