classdef GFReconstructionTaskController < GFTaskController
  properties (SetObservable)
    ShapeReconstructor
    ShapeView
    Shape
  end
  
  properties (Access = protected)
    MeshSaveCounter = 1
  end
  
  properties (Access = private)
    Listeners
  end
  
  methods
    function obj = GFReconstructionTaskController(uiLoop)
      obj = obj@GFTaskController(uiLoop);
      
      obj.ShapeView = PTMeshView(obj.UILoop.Window, [0 0 0 0]);
      
      obj.UILoop.ContainerView.addViews(obj.ShapeView, 1);
      obj.Listeners = event.listener(obj.UILoop.ContainerView, 'KeyDown', @obj.recCtrlKeyDown);
    end
    
    function nextStimulus(obj, stimulus, figs)
      global GFSettings;
      
      obj.nextStimulus@GFTaskController(stimulus, figs);
      
      pos = [(obj.UILoop.WinRect(3)/2 - stimulus.Mask.Width)/2 ...
             (obj.UILoop.WinRect(4) - stimulus.Mask.Height)/2];
      
      obj.Stimulus.Pos = pos;
      obj.FigView.Rect = obj.Stimulus.Rect;
      
      shapeViewRect = [pos(1) + obj.UILoop.WinRect(3)/2 pos(2)];
      shapeViewRect = [shapeViewRect shapeViewRect + obj.Stimulus.Dimensions];
      
      obj.ShapeView.ViewPoint = [0 0 0];
      obj.ShapeView.FovY = GFSettings.FovY;
      obj.ShapeView.Mesh = [];
      obj.ShapeView.Visible = false;
      obj.ShapeView.Rect = shapeViewRect;
      
      if isempty(obj.ShapeReconstructor)
        obj.ShapeReconstructor = obj.createReconstructor;
      else
        obj.ShapeReconstructor.reset(obj.FigSet, obj.Stimulus.Mask);
      end
      
      obj.Shape = obj.ShapeReconstructor.Shape;
      obj.ShapeView.Mesh = obj.Shape;
    end
    
    function detach(obj)
      obj.detach@GFTaskController;
      
      obj.UILoop.ContainerView.removeViews(obj.ShapeView);
    end
  end
  
  methods (Access = private)
    function recCtrlKeyDown(obj, source, event) %#ok<*INUSL>
      global GFSettings;
      
      if any(event.Delta(GFSettings.ReconstructShapeKey))
        obj.reconstructShape;
      end
      
      if any(event.Delta(GFSettings.SaveMeshKey))
        if ~isempty(obj.Shape.Verts) && ~isempty(obj.Shape.Tris)
          base = sprintf('gf-mesh-%02d.obj', obj.MeshSaveCounter);
          fileName = fullfile(GFSettings.MeshSaveDir, base);
          writeObj(fileName, obj.Shape.Verts, obj.Shape.Tris, obj.Shape.Normals);
          obj.MeshSaveCounter = obj.MeshSaveCounter + 1;
        end
      end
    end
  end
  
  methods (Abstract)
    reconstructor = createReconstructor(obj)
    reconstructShape(obj)
  end
end
