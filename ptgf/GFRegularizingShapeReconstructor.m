classdef GFRegularizingShapeReconstructor < GFShapeReconstructor
  properties
    Spacing = 8
    DepthsMask
  end
  
  methods
    function obj = GFRegularizingShapeReconstructor(figSet, mask, figView, shapeView, spacing)
      obj = obj@GFShapeReconstructor(figSet, mask, figView, shapeView);
      
      if exist('spacing', 'var')
        obj.Spacing = spacing;
      end
    end
    
    function reset(obj, figSet, mask)
      obj.reset@GFShapeReconstructor(figSet, mask);
      obj.DepthsMask = obj.Mask.Data;
    end
    
    function updateShape(obj)
      tanSlants = tan(obj.FigSet.Slants);
      dzdxs = cos(obj.FigSet.Tilts).*tanSlants;
      dzdys = sin(obj.FigSet.Tilts).*tanSlants;
      
      xs = obj.FigSet.Xs - 1 - obj.FigView.Width/2;
      ys = obj.FigView.Height/2 - obj.FigSet.Ys + 1;
      
      upp = obj.ShapeView.UnitsPerPixel;
      
      xis = ((0:obj.Spacing:obj.FigView.Width - 1) - obj.FigView.Width/2)*upp;
      yis = ((obj.FigView.Height - 1:-obj.Spacing:0) - obj.FigView.Height/2)*upp;
      newSize = [length(yis) length(xis)];
      
      [depths xs ys] = reconstructDenseDepths([], [[xs ys]*upp dzdxs dzdys], xis, yis, 1, 5, 'real');
%       depths = reconstructDenseDepths([[xs ys]*upp dzdxs dzdys], xis, yis, 1, 5);
      
      obj.Shape.Verts = [xs(:) ys(:) -depths(:)];
      obj.Shape.Tris = trisFromDepthmap(imresize(obj.Mask.Data, newSize));
      centerInd = sub2ind(newSize, round(obj.FigView.Height/obj.Spacing/2), round(obj.FigView.Width/obj.Spacing/2));
      center = obj.Shape.Verts(:,centerInd);
      obj.Shape.Verts = bsxfun(@minus, obj.Shape.Verts, center);
      obj.Shape.Position = center;
    end
  end
end