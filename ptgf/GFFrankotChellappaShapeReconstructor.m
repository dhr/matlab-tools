classdef GFFrankotChellappaShapeReconstructor < GFTriangulatingShapeReconstructor
  properties
    DepthsMask
    DenseNormals
  end
  
  properties (Access = protected)
    UseFBOs
    FBO
    RBO
    NormalInterpShader
    DenseGridXs
    DenseGridYs
    DepthOffset = 5
  end
  
  methods
    function obj = GFFrankotChellappaShapeReconstructor(figSet, mask, figView, shapeView)
      obj = obj@GFTriangulatingShapeReconstructor(figSet, mask, figView, shapeView);
      obj.initGLConstructs;
    end
    
    function updateShape(obj)
      obj.updateTriangulation;
      
      if size(obj.DenseGridXs, 2) ~= obj.Mask.Width || size(obj.DenseGridXs, 1) ~= obj.Mask.Height
        [obj.DenseGridXs obj.DenseGridYs] = meshgrid(0:obj.Mask.Width - 1, 0:obj.Mask.Height - 1);
      end
      
      obj.updateDenseNormals;
      
      upp = obj.ShapeView.UnitsPerPixel;
      dfdxs = -obj.DenseNormals(:,:,1)./obj.DenseNormals(:,:,3);
      dfdys = -obj.DenseNormals(:,:,2)./obj.DenseNormals(:,:,3);
      denseDepths = frankotChellappa(dfdxs, dfdys)*upp;
      denseDepths = denseDepths - mean(denseDepths(obj.Mask.Data));
      obj.Shape.Verts = [(obj.DenseGridXs(:) - obj.Mask.Width/2)*upp ...
                         (obj.Mask.Height/2 - obj.DenseGridYs(:))*upp ...
                         -denseDepths(:)]';
      if obj.ShapeView.PerspectiveProjection
        obj.Shape.Verts(1:2,:) = bsxfun(@times, obj.Shape.Verts(1:2,:), -(obj.Shape.Verts(3,:) - obj.DepthOffset));
      end
      obj.Shape.Tris = trisFromDepthmap(obj.DepthsMask);
      obj.Shape.Position = [0 0 -obj.DepthOffset];
    end
    
    function indx = vertexForPosition(obj, pos)
      indx = sub2ind(fliplr(obj.FigView.Dimensions), pos(2) + 1, pos(1) + 1);
    end
    
    function delete(obj)
      if obj.UseFBOs
        glDeleteFramebuffersEXT(1, obj.FBO);
        glDeleteRenderbuffersEXT(1, obj.RBO);
      end
      
      glDeleteProgram(obj.NormalInterpShader);
    end
  end
  
  methods (Access = protected)
    function initGLConstructs(obj)
      global GL;
      global GFSettings;
      
      obj.UseFBOs = GFSettings.UseFramebufferObjects && ...
        ~isempty(findstr(glGetString(GL.EXTENSIONS), '_framebuffer_object')) && ...
        ~isempty(findstr(glGetString(GL.EXTENSIONS), '_texture_float'));
      
      if ~obj.UseFBOs
        error('Framebuffer objects are not supported by your graphics card.');
      end
      
      fpInternalFormat = GFSettings.GL32BitFloatingPointInternalFormat;
      obj.FBO = glGenFramebuffersEXT(1);
      obj.RBO = glGenRenderbuffersEXT(1);
      glBindRenderbufferEXT(GL.RENDERBUFFER_EXT, obj.RBO);
      glRenderbufferStorageEXT(GL.RENDERBUFFER_EXT, fpInternalFormat, obj.Mask.Width, obj.Mask.Height);
      glBindFramebufferEXT(GL.FRAMEBUFFER_EXT, obj.FBO);
      glFramebufferRenderbufferEXT(GL.FRAMEBUFFER_EXT, GL.COLOR_ATTACHMENT0_EXT, ...
                                   GL.RENDERBUFFER_EXT, obj.RBO);
      glBindFramebufferEXT(GL.FRAMEBUFFER_EXT, 0);
      
      obj.NormalInterpShader = ...
        LoadGLSLProgramFromFiles({fullfile(GFSettings.GFRoot, 'shaders', 'NormalInterpolation.vert'), ...
                                  fullfile(GFSettings.GFRoot, 'shaders', 'NormalInterpolation.frag')});
      clampedLoc = glGetUniformLocation(obj.NormalInterpShader, 'Clamped');
      transformLoc = glGetUniformLocation(obj.NormalInterpShader, 'TransformNormal');

      glUseProgram(obj.NormalInterpShader);
      glUniform1i(clampedLoc, ~obj.UseFBOs);
      glUniform1i(transformLoc, true);
      glUseProgram(0);
    end
    
    function updateDenseNormals(obj)
      global GL;
      global GFSettings;
      
      if strcmp(GFSettings.InterpMethod, 'opengl')
        if obj.FigSet.NFigures > 2
          Screen('BeginOpenGL', obj.ShapeView.Window);
          
          % Draw everything in the lower left corner of the window
          
          GFFrankotChellappaShapeReconstructor.prepareOpenGL;
          
          glViewport(0, 0, obj.ShapeView.Width, obj.ShapeView.Height);
      
          glMatrixMode(GL.PROJECTION);
          glLoadIdentity;
          if obj.ShapeView.PerspectiveProjection
            gluPerspective(obj.ShapeView.FovY, obj.ShapeView.AspectRatio, 0.5, 1.5);
          else
            glOrtho(-obj.ShapeView.AspectRatio, obj.ShapeView.AspectRatio, -1, 1, 0.5, 1.5);
          end
          glMatrixMode(GL.MODELVIEW);
          
          glPushMatrix;
          
          if obj.UseFBOs
            glBindFramebufferEXT(GL.FRAMEBUFFER_EXT, obj.FBO);
          end
          
          glClearColor(0, 0, 0, 1);
          glClear(GL.COLOR_BUFFER_BIT);
          
          glDisable(GL.BLEND);
          glUseProgram(obj.NormalInterpShader);
          
          glPolygonMode(GL.FRONT_AND_BACK, GL.FILL);
          
          glVertexPointer(3, GL.DOUBLE, 0, obj.Triangulation.Verts);
          glNormalPointer(GL.DOUBLE, 0, obj.Triangulation.Normals);
          
          glDrawElements(GL.TRIANGLES, numel(obj.Triangulation.Tris), GL.UNSIGNED_INT, uint32(obj.Triangulation.Tris - 1));
          
          normals = double(glReadPixels(0, 0, obj.Mask.Width, obj.Mask.Height, GL.RGB, GL.FLOAT));
          
          normals(:,:,1) = rot90(normals(:,:,1));
          normals(:,:,2) = rot90(normals(:,:,2));
          normals(:,:,3) = rot90(normals(:,:,3));
          
          obj.DepthsMask = sum(abs(normals), 3) ~= 0;
          
          if obj.UseFBOs
            glBindFramebufferEXT(GL.FRAMEBUFFER_EXT, 0);
            obj.DenseNormals = normals;
            obj.DenseNormals(:,:,3) = obj.DenseNormals(:,:,3) + ~obj.DepthsMask;
          else
            normals = normals*2 - 1;
            invDenseDepthsMask = ~denseDepthsMask;
            denseNormals = normals + cat(3, invDenseDepthsMask, invDenseDepthsMask, 2*invDenseDepthsMask);
            % Since floating point FBOs aren't being, used, have to
            % renormalize to account for errors resulting from low precision
            obj.DenseNormals = bsxfun(@rdivide, denseNormals, sqrt(sum(denseNormals.^2, 3)));
          end
          
          glUseProgram(0);
          glEnable(GL.BLEND);
          
          glClearColor(GFSettings.ClearScreenBrightness, GFSettings.ClearScreenBrightness, GFSettings.ClearScreenBrightness, 1);
          
          glPopMatrix;
          
          Screen('EndOpenGL', obj.FigView.Window);
        else
          obj.DepthsMask = false(obj.Mask.Width, obj.Mask.Height);
          obj.DenseNormals = cat(3, zeros(obj.Mask.Width, obj.Mask.Height, 2), ones(obj.Mask.Width, obj.Mask.Height));
        end
      else
        if obj.FigSet.NFigures > 2
          interpMethod = GFSettings.InterpMethod;
          
          denseNormals = zeros(obj.Mask.Height, obj.Mask.Width, 3);
          
          for i = 1:3
            denseNormals(:,:,i) = ...
              griddata(obj.FigSet.Xs, obj.FigSet.Ys, squeeze(obj.Triangulation.Normals(i,:)), ...
                       obj.DenseGridXs, obj.DenseGridYs, interpMethod); %#ok<FPARK>
          end
          mags = sqrt(sum(denseNormals.^2, 3));
          obj.DepthsMask = isfinite(mags) & obj.Mask.Data;
          invDenseDepthsMask = ~obj.DepthsMask;
          mags(invDenseDepthsMask) = 1;
          denseNormals(repmat(invDenseDepthsMask, [1 1 3])) = 0;
          denseNormals(:,:,3) = denseNormals(:,:,3) + invDenseDepthsMask;
          obj.DenseNormals = bsxfun(@rdivide, denseNormals, mags);
        end
      end
    end
  end
  
  methods (Access = protected, Static)
    function prepareOpenGL
      global GL;
      
      glEnableClientState(GL.VERTEX_ARRAY);
      glEnableClientState(GL.NORMAL_ARRAY);
      glEnable(GL.VERTEX_PROGRAM_TWO_SIDE);
    end
  end
end
