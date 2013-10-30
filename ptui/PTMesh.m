classdef PTMesh < handle
  properties (SetObservable = true)
    Verts
    Tris
    Normals
    Position = [0 0 0]
    Rotation = [1 0 0 0]
  end
  
  properties (SetAccess = protected)
    NormalsValid = false;
  end
  
  methods
    function obj = PTMesh(vs, tris, normals)
      if nargin == 0
        return;
      end
      
      obj.Verts = vs;
      obj.Tris = tris;
      
      if exist('normals', 'var')
        obj.Normals = normals;
      elseif ~isempty(obj.Tris)
        obj.inferNormals;
      end
    end
    
    function inferNormals(obj)
      if ~isempty(obj.Verts) && ~isempty(obj.Tris)
        obj.Normals = calcMeshNormals(obj.Verts, uint32(obj.Tris - 1));
      else
        obj.Normals = [];
      end
    end
    
    function set.Verts(obj, val)
      if size(val, 2) == 3
        val = val';
      elseif size(val, 1) ~= 3 && ~isempty(val)
        error('Vertices must be either 3 x n or n x 3.');
      end
      obj.Verts = val;
      obj.NormalsValid = false; %#ok<*MCSUP>
    end
    
    function set.Tris(obj, val)
      if size(val, 2) == 3
        val = val';
      elseif size(val, 1) ~= 3 && ~isempty(val)
        error('Triangles (faces) must be either 3 x n or n x 3.');
      end
      obj.Tris = val;
      obj.NormalsValid = false;
    end
    
    function val = get.Normals(obj)
      if ~obj.NormalsValid
        obj.inferNormals;
      end
      
      val = obj.Normals;
    end
    
    function set.Normals(obj, val)
      if size(val, 2) == 3
        val = val';
      elseif size(val, 1) ~= 3 && ~isempty(val)
        error('Normals must be either 3 x n or n x 3.');
      end
      obj.Normals = val;
      obj.NormalsValid = true;
    end
  end
end