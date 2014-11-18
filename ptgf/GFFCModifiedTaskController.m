classdef GFFCModifiedTaskController < GFModifiedTaskController
  methods
    function obj = GFFCModifiedTaskController(uiLoop)
      obj = obj@GFModifiedTaskController(uiLoop);
      obj.ShapeView.PerspectiveProjection = false;
    end
    
    function reconstructor = createReconstructor(obj)
      reconstructor = ...
        GFFrankotChellappaShapeReconstructor(obj.FigSet, obj.Stimulus.Mask, obj.FigView, obj.ShapeView);
    end
    
    function figure = figureForLocation(obj, pos)
      if ~isempty(obj.Shape.Normals) && obj.ShapeReconstructor.DepthsMask(pos(2) + 1, pos(1) + 1)
        normal = squeeze(obj.Shape.Normals(:,obj.ShapeReconstructor.vertexForPosition(pos)));
        slantTilt(1) = acos(normal(3));
        slantTilt(2) = atan2(normal(2), normal(1));
      else
        slantTilt = [0 0];
      end
      
      figure = [pos slantTilt false true false true];
    end
  end
end