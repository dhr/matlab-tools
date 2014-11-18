classdef GFShapeReconstructor < handle
  properties (SetObservable)
    FigSet
    Mask
    FigView
    ShapeView
    Shape
  end
  
  properties (Access = private)
    Listeners
  end
  
  events
    ShapeReconstructed
  end
  
  methods
    function obj = GFShapeReconstructor(figSet, mask, figView, shapeView)
      obj.FigView = figView;
      obj.ShapeView = shapeView;
      obj.reset(figSet, mask);
    end
    
    function reset(obj, figSet, mask)
      obj.FigSet = figSet;
      obj.Mask = mask;
      obj.Shape = PTMesh;
    end
  end
  
  methods (Abstract)
    updateShape(obj)
  end
end