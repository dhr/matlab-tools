classdef MeshViewerController < PTTaskController
  properties
    Mesh
    MeshView
    InfoView
    Shaders
    RotSnapshotKey = KbName('return')
    RotSnapshotHandler
    ChangeShaderKey = KbName('`~');
  end
  
  properties (SetAccess = protected)
    Angles = [0 0 0]
  end
  
  properties (Access = protected)
    CurrentShader = 1
  end
  
  methods
    function obj = MeshViewerController(uiLoop, mesh, varargin)
      parsearglist({'projection', 'viewPoint', 'viewDir', 'viewUp', 'viewAngle', 'rotation', ...
                    'materialColor', 'infoColor', 'rotSnapshotHandler'}, varargin, true);
      argdefaults('projection', 'v', 'viewPoint', [0 -7 0], 'viewDir', [0 1 0], ...
                  'viewUp', [0 0 1], 'viewAngle', 20.5, 'rotation', [1 0 0 0], ...
                  'materialColor', 0.6*[1 1 1], 'infoColor', 0.8*[1 1 1], ...
                  'rotSnapshotHandler', @obj.rotSnapshot);
      
      obj.UILoop = uiLoop;
      
      if numel(rotation) == 3 %#ok<NODEF>
        rotation = rotation*pi/180;
        rotation = angle2quat(rotation(1), rotation(2), rotation(3));
      end
      
      shaderbase = fullfile(fileparts(mfilename('fullpath')), 'shaders', 'SoftDiffusePerPixel');
      obj.Shaders(1) = 0;
      obj.Shaders(2) = LoadGLSLProgramFromFiles({[shaderbase '.vert'], [shaderbase '.frag']});
      softShadingLoc = glGetUniformLocation(obj.Shaders(2), 'UseSoftShading');
      
      glUseProgram(obj.Shaders(2));
      glUniform1i(softShadingLoc, true);
      glUseProgram(0);
      
      obj.MeshView = PTMeshView(obj.UILoop.Window, obj.UILoop.WinRect, PTMesh);
      obj.MeshView.PerspectiveProjection = strcmpi(projection, 'v');
      obj.MeshView.ViewPoint = viewPoint;
      obj.MeshView.ViewDir = viewDir;
      obj.MeshView.ViewUp = viewUp;
      obj.MeshView.FovY = viewAngle;
      obj.MeshView.MaterialColor = materialColor;
      obj.MeshView.Shader = obj.Shaders(obj.CurrentShader);
      obj.MeshView.RotationResetValue = rotation;
      
      obj.Mesh = mesh;
      obj.Mesh.Rotation = rotation;
      
      obj.InfoView = PTTextView(obj.UILoop.Window, [20 20 170 40], '', ...
                                PTTextFormat(14, infoColor, 'Courier'));
      obj.RotSnapshotHandler = rotSnapshotHandler;
      
      obj.UILoop.ContainerView.addViews({obj.InfoView, obj.MeshView});
      
      addlistener(obj.UILoop.ContainerView, 'KeyUp', @obj.keyUp);
      addlistener(obj.MeshView, 'MeshRotating', @obj.meshRotating);
      addlistener(obj.MeshView, 'MeshRotationReset', @obj.meshRotating);
      
      obj.meshRotating;
    end
    
    function detach(obj)
      obj.UILoop.ContainerView.removeViews({obj.MeshView, obj.InfoView});
    end
    
    function set.Mesh(obj, val)
      obj.MeshView.Mesh = val; %#ok<*MCSUP>
      obj.Mesh = val;
      obj.updateAngles;
    end
    
    function rotSnapshot(angles)
      fprintf('[Z Y X] = [%.4f, %.4f, %.4f]\n', angles);
    end
    
    function keyUp(obj, src, event) %#ok<INUSL>
      if any(event.Delta(obj.RotSnapshotKey))
        obj.RotSnapshotHandler(obj.Angles);
      end
      
      if any(event.Delta(obj.ChangeShaderKey))
        obj.CurrentShader = obj.CurrentShader + 1;
        if obj.CurrentShader > length(obj.Shaders)
          obj.CurrentShader = 1;
        end
        obj.MeshView.Shader = obj.Shaders(obj.CurrentShader);
      end
    end
    
    function meshRotating(obj, src, event) %#ok<INUSD>
      obj.updateAngles;
    end
    
    function updateAngles(obj)
      [obj.Angles(1), obj.Angles(2), obj.Angles(3)] = quat2angle(obj.Mesh.Rotation);
      obj.Angles = obj.Angles*180/pi;
      obj.InfoView.Text = sprintf('[Z Y X] = [%.2f, %.2f, %.2f]', obj.Angles);
    end
  end
end
