function ShapeChooser(shapeBaseFmt, shapeNs, varargin)
  arguments = varargin;
  quitKey = KbName('escape');
  nextShapeKey = KbName('tab');
  uiLoop = [];
  controller = [];
  shapeIdx = 1;
  
  if ~exist('shapeBaseFmt', 'var')
    shapeBaseFmt = meshpath('blob%02d.obj');
  end
  
  if ~exist('shapeNs', 'var')
    shapeNs = 1:1000;
  end
  
  BasicUI(@setupFun);
  
  function setupFun(mainUILoop)
    mesh = loadMesh;
    
    uiLoop = mainUILoop;
    controller = MeshViewerController(uiLoop, mesh, ...
      'RotSnapshotHandler', @printAngles, varargin{:});
    addlistener(uiLoop.ContainerView, 'KeyUp', @keyUp);
  end
  
  function mesh = loadMesh
    file = sprintf(shapeBaseFmt, shapeNs(shapeIdx));
    [vs, tris, ns] = loadObj(file);
    mesh = PTMesh(vs, tris, ns);
  end
  
  function printAngles(angles)
    fprintf(['\nshape{i} = ''' shapeBaseFmt ''';\n'], shapeNs(shapeIdx));
    fprintf('rs{i} = [%.4f, %.4f, %.4f];\n', angles);
    fprintf('i = i + 1;\n');
  end

  function keyUp(src, event) %#ok<INUSL>
    if event.Delta(quitKey)
      uiLoop.stop;
    end
    
    if event.Delta(nextShapeKey)
      shapeIdx = shapeIdx + 1;
      if shapeIdx > numel(shapeNs)
        uiLoop.stop;
      end
      
      try
        mesh = loadMesh;
        controller.Mesh = mesh;
      catch exc
        uiLoop.stop;
        rethrow(exc);
      end
    end
  end
end
