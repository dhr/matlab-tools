classdef GFNefsShapeReconstructor < GFTriangulatingShapeReconstructor
  properties
    FigSetBoundaryPoly
  end  
  
  methods
    function obj = GFNefsShapeReconstructor(figSet, mask, figView, shapeView, figSetBoundaryPoly)
      obj = obj@GFTriangulatingShapeReconstructor(figSet, mask, figView, shapeView, figSetBoundaryPoly);
    end
    
    function updateShape(obj)
      obj.updateTriangulation;
      [ds xs ys] = ...
        depthsFromSparseNormals(obj.Triangulation.Verts(1,:), ...
                                obj.Triangulation.Verts(2,:), ...
                                obj.Triangulation.Normals, ...
                                obj.Triangulation.Tris, false, []);
      obj.Shape.Verts = [xs'; ys'; ds'];
      obj.Shape.Tris = obj.Triangulation.Tris;
    end
  end
end