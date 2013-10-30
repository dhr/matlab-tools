classdef PTMeshView < PTView
  properties (SetObservable = true)
    Mesh
    Shader
    ViewPoint = [0 0 1]'
    ViewDir = [0 0 -1]'
    ViewUp = [0 1 0]'
    PerspectiveProjection = true
    FovY = 20.5
    RotationResetValue = [1 0 0 0]
    MaterialColor = 0.6*[1 1 1]
    VertexHighlightColor = [1 1 0]
    VertexHighlightSize = 5
    LightPosition = [0.3 0.2 1 0]
    RotationSensitivity = 800
    DefaultCursor = 'Arrow'
    HoverCursor = 9
    HighlightedVertex = 0
  end
  
  properties (Dependent)
    ViewCenter
  end
  
  properties (SetAccess = protected)
    ShapeActive = false
    ViewRight
    ViewFrameInv
  end
  
  properties (Access = protected)
    Listeners
    ShapeChanged
    
    MouseOverShape = false
    
    MouseDownPos
    MouseDownOffset
    MouseDragOffset
    
    RotStartVec
    RotEndVec
    PreviousRotQuat
    CurrentRotQuat
    
    RotReferencePos
    ScreenID
    
    VertexBuffer
    NormalBuffer
    IndexBuffer
  end
  
  properties (Dependent)
    UnitsPerPixel
  end
  
  events
    MeshRotationStarted
    MeshRotating
    MeshRotationEnded
    MeshRotationReset
  end
  
  methods
    function obj = PTMeshView(window, rect, varargin)
      obj = obj@PTView(window, rect);
      
      obj.setupVBOs;
      
      if length(varargin) == 1
        obj.Mesh = varargin{1};
      elseif length(varargin) > 1
        obj.Mesh = PTMesh(varargin{:});
      end
      
      obj.ScreenID = Screen('WindowScreenNumber', obj.Window);
      [obj.RotReferencePos(1) obj.RotReferencePos(2)] = RectCenter(Screen('Rect', obj.ScreenID));
      
      obj.updateViewFrameInv;
      
      addlistener(obj, 'MouseMoved', @obj.mouseMoved);
      addlistener(obj, 'MouseDown', @obj.mouseDown);
      addlistener(obj, 'MouseDragged', @obj.mouseDragged);
      addlistener(obj, 'MouseUp', @obj.mouseUp);
    end
    
    function set.Mesh(obj, val)
      obj.Mesh = val;
      
      if ~isempty(obj.Mesh)
        delete(obj.Listeners); %#ok<*MCSUP>
        obj.Listeners = addlistener(obj.Mesh, {'Verts', 'Tris', 'Normals'}, 'PostSet', @obj.shapeChanged);
      end
      
      obj.ShapeChanged = true;
    end
    
    function set.ViewPoint(obj, val)
      obj.ViewPoint = val(:);
    end
    
    function val = get.ViewCenter(obj)
      val = obj.ViewPoint + obj.ViewDir;
    end
    
    function set.ViewCenter(obj, val)
      dir = val(:) - obj.ViewPoint;
      obj.ViewDir = dir/normal(dir);
    end
    
    function set.ViewDir(obj, val)
      obj.ViewDir = val(:)/norm(val);
      obj.updateViewFrameInv;
    end
    
    function set.ViewUp(obj, val)
      obj.ViewUp = val(:)/norm(val);
      obj.updateViewFrameInv;
    end
    
    function updateViewFrameInv(obj, val)
      obj.ViewRight = cross(obj.ViewDir, obj.ViewUp);
      obj.ViewFrameInv = [obj.ViewRight'; obj.ViewUp'; -obj.ViewDir'];
    end
    
    function val = get.UnitsPerPixel(obj)
      if obj.PerspectiveProjection
        val = 2*tan(obj.FovY*pi/180/2)/obj.Height;
      else
        val = 2/obj.Height;
      end
    end
    
    function render(obj)
      global GL;
      
      if obj.ShapeChanged
        obj.updateVBOs;
        obj.ShapeChanged = false;
      end
      
      if isempty(obj.Mesh)
        return;
      end
      
      Screen('BeginOpenGL', obj.Window);
      
      PTMeshView.prepareOpenGL;
      
      obj.configureOpenGLViewport;
      
      glMatrixMode(GL.PROJECTION);
      glLoadIdentity;
      if obj.PerspectiveProjection
        gluPerspective(obj.FovY, obj.AspectRatio, 1, 100);
      else
        glOrtho(-obj.AspectRatio, obj.AspectRatio, -1, 1, 1, 100);
      end
      glMatrixMode(GL.MODELVIEW);

      glClear(GL.DEPTH_BUFFER_BIT);

      glPushMatrix;
        glLightfv(GL.LIGHT0, GL.POSITION, obj.LightPosition);
        
        gluLookAt(obj.ViewPoint(1), obj.ViewPoint(2), obj.ViewPoint(3), ...
                  obj.ViewCenter(1), obj.ViewCenter(2), obj.ViewCenter(3), ...
                  obj.ViewUp(1), obj.ViewUp(2), obj.ViewUp(3));
        
        glTranslated(obj.Mesh.Position(1), obj.Mesh.Position(2), obj.Mesh.Position(3));
        glRotatef(2*acos(obj.Mesh.Rotation(1))*180/pi, ...
                  obj.Mesh.Rotation(2), obj.Mesh.Rotation(3), obj.Mesh.Rotation(4));

        if obj.Shader
          glUseProgram(obj.Shader);
        end
        
        glPolygonOffset(5, 5);
        glEnable(GL.POLYGON_OFFSET_FILL);
        
        glColor3dv(obj.MaterialColor);
        
        glBindBuffer(GL.ARRAY_BUFFER, obj.VertexBuffer);
        glVertexPointer(3, GL.FLOAT, 0, 0);

        glBindBuffer(GL.ARRAY_BUFFER, obj.NormalBuffer);
        glNormalPointer(GL.FLOAT, 0, 0);

        glBindBuffer(GL.ELEMENT_ARRAY_BUFFER, obj.IndexBuffer);

        glDrawElements(GL.TRIANGLES, numel(obj.Mesh.Tris), GL.UNSIGNED_INT, 0);

        glBindBuffer(GL.ARRAY_BUFFER, 0);
        glBindBuffer(GL.ELEMENT_ARRAY_BUFFER, 0);
        
        glDisable(GL.POLYGON_OFFSET_FILL);
        
        if obj.HighlightedVertex
          glDisable(GL.LIGHTING);
          glPointSize(obj.VertexHighlightSize);
          glColor3dv(obj.VertexHighlightColor);
          glBegin(GL.POINTS);
          glVertex3d(obj.Mesh.Verts(1,obj.HighlightedVertex), ...
                     obj.Mesh.Verts(2,obj.HighlightedVertex), ...
                     obj.Mesh.Verts(3,obj.HighlightedVertex));
          glEnd;
        end

        glUseProgram(0);
      glPopMatrix;
      
      PTMeshView.cleanupOpenGL;

      Screen('EndOpenGL', obj.Window);
    end
    
    function delete(obj)
      glDeleteBuffers(1, obj.VertexBuffer);
      glDeleteBuffers(1, obj.NormalBuffer);
      glDeleteBuffers(1, obj.IndexBuffer);
    end
  end
  
  methods (Access = protected)
    function mouseMoved(obj, source, event) %#ok<*INUSL>
      obj.MouseOverShape = obj.pointOverShape(event.Pos);
      obj.updateCursor;
    end
    
    function mouseDown(obj, source, event)
      if event.Delta(1) && obj.MouseOverShape
        [x y] = RectCenter(obj.Rect);
        obj.MouseDownOffset = event.Pos - [x y];
        obj.RotStartVec = [obj.MouseDownOffset.*[1 -1] 0]/obj.RotationSensitivity;
        mag2 = sum(obj.RotStartVec.^2);
        obj.RotStartVec(3) = sqrt(1 - mag2);
        obj.RotStartVec = obj.RotStartVec*obj.ViewFrameInv;

        HideCursor;
        GrabCursor;
        obj.MouseDragOffset = obj.MouseDownOffset;

        obj.PreviousRotQuat = obj.Mesh.Rotation;
        obj.MouseDownPos = event.Pos;
        obj.ShapeActive = true;
        
        notify(obj, 'MeshRotationStarted');
      end
    end
    
    function mouseDragged(obj, source, event)
      if obj.ShapeActive
        obj.MouseDragOffset = obj.MouseDragOffset + event.Delta;
        obj.RotEndVec = [obj.MouseDragOffset.*[1 -1] 0]/obj.RotationSensitivity;
        mag2 = sum(obj.RotEndVec(1:2).^2);
        if mag2 > 1
          mag = sqrt(mag2);
          s = 1/(mag + 2*eps(mag));
          obj.RotEndVec = -s*obj.RotEndVec;
          obj.MouseDragOffset = -obj.MouseDragOffset;
        else
          obj.RotEndVec(3) = sqrt(1 - mag2);
        end
        obj.RotEndVec = obj.RotEndVec*obj.ViewFrameInv;
        obj.CurrentRotQuat = [dot(obj.RotEndVec, obj.RotStartVec) cross(obj.RotStartVec, obj.RotEndVec)];
        obj.Mesh.Rotation = quatmultiply(obj.CurrentRotQuat, obj.PreviousRotQuat);
        
        notify(obj, 'MeshRotating');
      end
    end
    
    function mouseUp(obj, source, event)
      if obj.ShapeActive
        ReleaseCursor;
        ShowCursor(obj.HoverCursor);
        obj.ShapeActive = false;
        
        notify(obj, 'MeshRotationEnded');
      elseif event.Delta(2)
        obj.Mesh.Rotation = obj.RotationResetValue;
        notify(obj, 'MeshRotationReset');
      end
    end
    
    function shapeChanged(obj, source, event) %#ok<*INUSD>
      obj.ShapeChanged = true;
    end
    
    function updateCursor(obj)
      if obj.MouseOverShape
        ShowCursor(obj.HoverCursor);
      else
        ShowCursor(obj.DefaultCursor);
      end
    end
    
    function yesno = pointOverShape(obj, pos)
      [x y] = RectCenter(obj.Rect);
      yesno = sum((pos - [x y]).^2) <= obj.RotationSensitivity^2;
    end
    
    function setupVBOs(obj)
      global GL;
      
      Screen('BeginOpenGL', obj.Window);
      hasVBOs = ~isempty(findstr(glGetString(GL.EXTENSIONS), '_vertex_buffer_object'));
  
      if hasVBOs
        obj.VertexBuffer = glGenBuffers(1);
        obj.NormalBuffer = glGenBuffers(1);
        obj.IndexBuffer = glGenBuffers(1);
      else
        error('Vertex buffer objects are not available.');
      end
      
      Screen('EndOpenGL', obj.Window);
    end
    
    function updateVBOs(obj)
      global GL;
      
      if isempty(obj.Mesh)
        return;
      end
      
      Screen('BeginOpenGL', obj.Window);
      
      glBindBuffer(GL.ARRAY_BUFFER, obj.VertexBuffer);
      glBufferData(GL.ARRAY_BUFFER, 4*numel(obj.Mesh.Verts), single(obj.Mesh.Verts), GL.STATIC_DRAW);

      glBindBuffer(GL.ARRAY_BUFFER, obj.NormalBuffer);
      glBufferData(GL.ARRAY_BUFFER, 4*numel(obj.Mesh.Normals), single(obj.Mesh.Normals), GL.STATIC_DRAW);
      
      glBindBuffer(GL.ARRAY_BUFFER, 0);
      
      glBindBuffer(GL.ELEMENT_ARRAY_BUFFER, obj.IndexBuffer);
      glBufferData(GL.ELEMENT_ARRAY_BUFFER, 4*numel(obj.Mesh.Tris), uint32(obj.Mesh.Tris - 1), GL.STATIC_DRAW);
      
      glBindBuffer(GL.ELEMENT_ARRAY_BUFFER, 0);
      
      Screen('EndOpenGL', obj.Window);
    end
  end
  
  methods (Static)
    function prepareOpenGL
      global GL;
      
      glShadeModel(GL.SMOOTH);
    
      glEnable(GL.LINE_SMOOTH);
      glEnable(GL.POINT_SMOOTH);
      glEnable(GL.BLEND);
      glBlendFunc(GL.SRC_ALPHA, GL.ONE_MINUS_SRC_ALPHA);

      glClearDepth(1000);
      glDepthFunc(GL.LEQUAL);
      glEnable(GL.DEPTH_TEST);

      glColorMaterial(GL.FRONT_AND_BACK, GL.AMBIENT_AND_DIFFUSE);
      glEnable(GL.COLOR_MATERIAL);

      glEnable(GL.VERTEX_PROGRAM_TWO_SIDE);
      glLightModeli(GL.LIGHT_MODEL_TWO_SIDE, GL.FALSE);
      glLightModelfv(GL.LIGHT_MODEL_AMBIENT, [0.2 0.2 0.2 1]);
      glLightfv(GL.LIGHT0, GL.AMBIENT, [0 0 0 1]);
      glEnable(GL.LIGHT0);
      
      glEnableClientState(GL.VERTEX_ARRAY);
      glEnableClientState(GL.NORMAL_ARRAY);

      glEnable(GL.LIGHTING);
      glPolygonMode(GL.FRONT_AND_BACK, GL.FILL);
    end
    
    function cleanupOpenGL
      global GL;
      
      glDisable(GL.DEPTH_TEST);
      glDisable(GL.LIGHTING);
      glDisable(GL.COLOR_MATERIAL);
    end
  end
end
      