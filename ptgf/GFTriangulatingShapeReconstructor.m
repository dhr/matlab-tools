classdef GFTriangulatingShapeReconstructor < GFShapeReconstructor
  properties (Access = protected)
    Triangulation
    RetriangulationRequired
    ChangedIndxs
  end
  
  properties (Access = private)
    Listeners
  end
  
  methods
    function obj = GFTriangulatingShapeReconstructor(figSet, mask, figView, shapeView)
      obj = obj@GFShapeReconstructor(figSet, mask, figView, shapeView);
      addlistener(obj, 'FigSet', 'PostSet', @obj.figSetChanged);
      obj.init;
    end
  end
  
  methods (Access = protected)
    function figSetChanged(obj, source, event)
      obj.init;
    end
    
    function init(obj)
      obj.initStencilBuffer;
      
      obj.Triangulation = PTMesh;
      obj.RetriangulationRequired = true;
      obj.ChangedIndxs = true(obj.FigSet.NFigures, 1);
      
      obj.Listeners = event.listener(obj.FigSet, 'FiguresAdded', @obj.retriangulationRequired);
      obj.Listeners(2) = event.listener(obj.FigSet, 'FiguresRemoved', @obj.retriangulationRequired);
      obj.Listeners(3) = event.listener(obj.FigSet, 'FigurePositionsChanged', @obj.retriangulationRequired);
      obj.Listeners(4) = event.listener(obj.FigSet, 'FigureSlantsChanged', @obj.indxsChanged);
      obj.Listeners(5) = event.listener(obj.FigSet, 'FigureTiltsChanged', @obj.indxsChanged);
    end
    
    function updateTriangulation(obj)
      if obj.RetriangulationRequired
        obj.retriangulate;
        obj.RetriangulationRequired = false;
      end
      
      sinSlants = sin(obj.FigSet.Slants(obj.ChangedIndxs));
      obj.Triangulation.Normals(:,obj.ChangedIndxs) = ...
        [cos(obj.FigSet.Tilts(obj.ChangedIndxs)).*sinSlants ...
         sin(obj.FigSet.Tilts(obj.ChangedIndxs)).*sinSlants ...
         cos(obj.FigSet.Slants(obj.ChangedIndxs))]';
    end
    
    function retriangulationRequired(obj, source, event) %#ok<*INUSD>
      obj.RetriangulationRequired = true;
    end
    
    function retriangulate(obj, source, event)
      upp = obj.ShapeView.UnitsPerPixel;
      obj.Triangulation.Verts = ...
        [(obj.FigSet.Xs' - obj.FigView.Width/2)*upp;
         (obj.FigView.Height/2 - obj.FigSet.Ys')*upp;
         -ones(1, obj.FigSet.NFigures)];
       obj.Triangulation.Tris = delaunay(obj.Triangulation.Verts(1,:), obj.Triangulation.Verts(2,:));
       obj.removeInvalidTris;
       
       obj.RetriangulationRequired = false;
       obj.ChangedIndxs = true(obj.FigSet.NFigures, 1);
    end
    
    function indxsChanged(obj, source, event) %#ok<*INUSL>
      obj.ChangedIndxs(event.Indxs) = true;
    end
    
    function removeInvalidTris(obj)
      global GL;
      global GFSettings;
      
      nTris = size(obj.Triangulation.Tris, 2);
      indices = 1:nTris;
      colorLabelsBlues = mod(indices, 256);
      colorLabelsGreens = mod(floor(indices/256), 256);
      colorLabelsReds = floor(indices/(256^2));
      colorLabels = uint8([colorLabelsReds; colorLabelsGreens; colorLabelsBlues]);

      Screen('BeginOpenGL', obj.FigView.Window);

      glViewport(0, 0, obj.FigView.Width, obj.FigView.Height);
      
      glMatrixMode(GL.PROJECTION);
      glLoadIdentity;
      if GFSettings.FigsUsePerspective
        gluPerspective(GFSettings.FovY, obj.FigView.AspectRatio, 0.1, 10);
      else
        glOrtho(-obj.FigView.AspectRatio, obj.FigView.AspectRatio, -1, 1, 0.1, 10);
      end
      glMatrixMode(GL.MODELVIEW);

      glPushMatrix;

      clearColor = glGetDoublev(GL.COLOR_CLEAR_VALUE);
      glClearColor(0, 0, 0, 1);
      glClear(GL.COLOR_BUFFER_BIT);

      glDisable(GL.BLEND);
      glEnable(GL.STENCIL_TEST);
      glLineWidth(1);
      glDisable(GL.LINE_SMOOTH);

      glPolygonMode(GL.FRONT_AND_BACK, GFSettings.AreaType);
      glShadeModel(GL.FLAT);

      glBegin(GL.TRIANGLES);
      for i = indices
        glColor3ubv(colorLabels(:,i));
        glVertex3d(obj.FigView.FigObjXs(obj.Triangulation.Tris(1,i)), obj.FigView.FigObjYs(obj.Triangulation.Tris(1,i)), -1);
        glVertex3d(obj.FigView.FigObjXs(obj.Triangulation.Tris(2,i)), obj.FigView.FigObjYs(obj.Triangulation.Tris(2,i)), -1);
        glVertex3d(obj.FigView.FigObjXs(obj.Triangulation.Tris(3,i)), obj.FigView.FigObjYs(obj.Triangulation.Tris(3,i)), -1);
      end
      glEnd;

      display = glReadPixels(0, 0, obj.Mask.Width, obj.Mask.Height, GL.RGB, GL.UNSIGNED_BYTE);

      glEnable(GL.LINE_SMOOTH);
      glDisable(GL.STENCIL_TEST);
      glEnable(GL.BLEND);

      glClearColor(clearColor(1), clearColor(2), clearColor(3), clearColor(4));

      glPopMatrix;

      Screen('EndOpenGL', obj.FigView.Window);

      display = double(display);
      toRemove = display(:,:,1)*256^2 + display(:,:,2)*256 + display(:,:,3);
      toRemove = sort(nonzeros(toRemove(:)));
      uniques = [true; diff(toRemove) > 0];
      counts = 1:length(uniques) + 1;
      counts = diff(counts([uniques; true]));
      toKeep = true(nTris, 1);
      if ~isempty(toRemove)
        toRemove = toRemove(uniques);
        toRemove = toRemove(counts >= GFSettings.MinInvalidArea);
      end
      toKeep(toRemove) = false;
      obj.Triangulation.Tris = obj.Triangulation.Tris(:,toKeep);
    end
    
    function initStencilBuffer(obj)
      global GL;
      global GFSettings;
      
      Screen('BeginOpenGL', obj.FigView.Window);
      
      glEnable(GL.STENCIL_TEST);
    
      glClearStencil(0);
      glClear(GL.STENCIL_BUFFER_BIT);

      glViewport(0, 0, obj.FigView.Width, obj.FigView.Height);

      glPushMatrix;

      % Draw boundary polygon into stencil buffer

      nBoundaryPoints = size(obj.FigSet.BoundaryPoly, 1);
      if nBoundaryPoints > 2 && GFSettings.IncludeBoundaryPolyInMask
        glStencilOp(GL.INVERT, GL.INVERT, GL.INVERT);
        boundaryPolyVerts = [(obj.FigSet.BoundaryPoly(:,1)' - obj.FigView.Width/2)*obj.FigView.UnitsPerPixel; ...
                             (obj.FigSet.BoundaryPoly(:,2)' - obj.FigView.Height/2)*obj.FigView.UnitsPerPixel; ...
                             -ones(1, nBoundaryPoints)];
        glVertexPointer(3, GL.DOUBLE, 0, boundaryPolyVerts);
        glPolygonMode(GL.FRONT_AND_BACK, GL.FILL);
        glDrawElements(GL.TRIANGLE_FAN, nBoundaryPoints, GL.UNSIGNED_INT, uint32(0:nBoundaryPoints - 1));
      end

      glPopMatrix;

      % Draw mask where polygon has not been drawn

      glStencilFunc(GL.EQUAL, 0, 1);
      glStencilOp(GL.KEEP, GL.KEEP, GL.KEEP);

      glPushClientAttrib(GL.CLIENT_PIXEL_STORE_BIT);
      glPushAttrib(GL.CURRENT_BIT);

      glPixelStorei(GL.UNPACK_ROW_LENGTH, obj.FigView.Width);
      glPixelStorei(GL.UNPACK_IMAGE_HEIGHT, obj.FigView.Height);
      glPixelStorei(GL.UNPACK_ALIGNMENT, 1);

      stencil = obj.Mask.Data;
      if GFSettings.StencilGrowSigma > 0
        fsize = round(6*GFSettings.StencilGrowSigma);
        fsize = fsize + 1 - mod(fsize, 2);
        stencil = imfilter(stencil, fspecial('gaussian', fsize, GFSettings.StencilGrowSigma)) > 0;
      end

      currentStencil = ...
        glReadPixels(0, 0, obj.FigView.Width, obj.FigView.Height, GL.STENCIL_INDEX, GL.UNSIGNED_BYTE);
      stencil = uint8(rot90(stencil, -1)) | currentStencil;

      glRasterPos3d(-obj.FigView.AspectRatio, -1, -1);
      glDrawPixels(obj.FigView.Width, obj.FigView.Height, GL.STENCIL_INDEX, GL.UNSIGNED_BYTE, stencil);

      glPopAttrib;
      glPopClientAttrib;

      glDisable(GL.STENCIL_TEST);
      
      Screen('EndOpenGL', obj.FigView.Window);
    end
  end
end