classdef GFFigView < PTView
  properties
    FigSet
    Delegate
  end
  
  properties (SetAccess = protected)
    HoveredFigure = 0
    ActiveFigure = 0
    
    FigObjXs
    FigObjYs
  end
  
  properties (Access = protected)
    CurrentCursor
    CursorIsHidden = false
    FigColors
    
    Selecting = false
    Lasso = zeros(1000, 2)
    LassoObjCoords = zeros(2, 1000)
    NPolyPts = 0;
    
    CosTilts
    SinTilts
    SlantLimits
    FigRotOffsetsX
    FigRotOffsetsY
    
    ViewMousePos = [0 0]
    MouseDrag
    FirstButton
    HasDraggedMuchTotal
    InsertionKeyIsDown = false
    SelectionKeyIsDown = false
    
    FigureDisplayListID
    ListenerHandles
  end
  
  properties (Dependent)
    UnitsPerPixel;
  end
  
  events
    HoveredFigureChanged
    FigureRotationStarted
    FigureRotating
    FigureRotationEnded
    FiguresReset
  end    
  
  methods
    function obj = GFFigView(window, rect, figSet)
      if ~exist('figSet', 'var')
        figSet = GFFigSet;
      end
      
      obj = obj@PTView(window, rect);
      
      obj.FigSet = figSet;
      
      obj.FigureDisplayListID = obj.initDisplayList;
      
      addlistener(obj, 'MouseMoved', @obj.mouseMoved);
      addlistener(obj, 'MouseDown', @obj.mouseDown);
      addlistener(obj, 'MouseDragged', @obj.mouseDragged);
      addlistener(obj, 'MouseUp', @obj.mouseUp);
      addlistener(obj, 'MouseEntered', @obj.mouseEntered);
      addlistener(obj, 'MouseExited', @obj.mouseExited);
      
      addlistener(obj, 'KeyDown', @obj.keyDown);
      addlistener(obj, 'KeyUp', @obj.keyUp);
      
      addlistener(obj, 'HoveredFigureChanged', @obj.hoveredFigureChanged);
      addlistener(obj, 'FigureRotationStarted', @obj.figureRotationStarted);
      addlistener(obj, 'FigureRotationEnded', @obj.figureRotationEnded);
      
      addlistener(obj, 'ViewReshaped', @obj.viewReshaped);
    end
    
    function set.FigSet(obj, val)
      if obj.ActiveFigure
        obj.ActiveFigure = 0;
        obj.endFigRotation;
      end
      
      % Unset the hovered figure, otherwise there is an indexing error in
      % updateFigColors.
      obj.setHoveredFigure(0);
      
      obj.FigSet = val;
      
      nFigs = obj.FigSet.NFigures;
      
      obj.Selecting = false;
      obj.NPolyPts = 0;
      
      obj.FigObjXs = [];
      obj.FigObjYs = [];
      obj.CosTilts = [];
      obj.SinTilts = [];
      obj.SlantLimits = [];
      obj.FigColors = [];
      
      obj.updateFigColors(1:nFigs); %#ok<*MCSUP>
      obj.updateFigObjCoords(1:nFigs);
      obj.updateTiltTrigCache(1:nFigs);
      obj.updateSlantLimits(1:nFigs);
      
      % This must stay below the updateFigColors call, since
      % hoveredFigureChanged updates figure colors and expects the
      % FigColors matrix to be properly sized (possible indexing error).
      obj.updateHoveredFigure;
      
      obj.ListenerHandles = event.listener(obj.FigSet, 'FigureTiltsChanged', @obj.figureTiltsChanged);
      obj.ListenerHandles(2) = event.listener(obj.FigSet, 'FiguresAdded', @obj.figuresAdded);
      obj.ListenerHandles(3) = event.listener(obj.FigSet, 'FiguresRemoved', @obj.figuresRemoved);
      obj.ListenerHandles(4) = event.listener(obj.FigSet, 'FigureSelectionsChanged', @obj.figureSelectionsChanged);
      obj.ListenerHandles(5) = event.listener(obj.FigSet, 'FigureVisibilitiesChanged', @obj.figureVisibilitiesChanged);
      
      notify(obj, 'FiguresReset');
    end
    
    function delete(obj)
      if obj.CursorIsHidden
        ShowCursor;
      end
    end
    
    function render(obj)
      global GL;
      global GFSettings;
      
      Screen('BeginOpenGL', obj.Window);

      GFFigView.prepareOpenGL;

      obj.configureOpenGLViewport;
      
      glMatrixMode(GL.PROJECTION);
      glLoadIdentity;
      if GFSettings.FigsUsePerspective
        gluPerspective(GFSettings.FovY, obj.AspectRatio, 0.1, 10);
      else
        glOrtho(-obj.AspectRatio, obj.AspectRatio, -1, 1, 0.1, 10);
      end
      glMatrixMode(GL.MODELVIEW);
      
      % If there is no active figure draw everything that's visible
      if ~obj.ActiveFigure || ~GFSettings.SoloActiveFigures
        sel = logical(obj.FigSet.Visibilities);
      else % Otherwise just draw figures being manipulated
        sel = logical(obj.FigSet.Selections & obj.FigSet.Visibilities);
        sel(obj.ActiveFigure) = true;
      end

      upp = obj.UnitsPerPixel;

      glPolygonMode(GL.FRONT_AND_BACK, GL.FILL);

      scale = GFSettings.DefaultFigScale*upp;
      
      if GFSettings.OutlineFigures
        GFFigView.setLineAndPointStrength(GFSettings.OutlineStrength);
        gfDrawGaugeFigures(obj.FigObjXs(sel), obj.FigObjYs(sel), ...
                           obj.CosTilts(sel), obj.SinTilts(sel), ...
                           obj.FigSet.Slants(sel), ...
                           scale, GFSettings.OutlineColor(:), obj.FigureDisplayListID);
      end
      
      GFFigView.setLineAndPointStrength(GFSettings.FigureStrength);
      gfDrawGaugeFigures(obj.FigObjXs(sel), obj.FigObjYs(sel), ...
                         obj.CosTilts(sel), obj.SinTilts(sel), ...
                         obj.FigSet.Slants(sel), ...
                         scale, obj.FigColors(:,sel), obj.FigureDisplayListID);
      
      if GFSettings.ShowGhostFigure && ~obj.HoveredFigure && ~obj.Selecting && ...
         obj.canAddFigureAtLocation(obj.ViewMousePos)
        fig = obj.Delegate.figureForLocation(obj.ViewMousePos);
        objX = (fig(1) - obj.Width/2)*upp;
        objY = (obj.Height/2 - fig(2))*upp;
        
        if GFSettings.OutlineFigures
          GFFigView.setLineAndPointStrength(GFSettings.OutlineStrength);
          gfDrawGaugeFigures(objX, objY, cos(fig(4)), sin(fig(4)), fig(3), ...
                             scale, GFSettings.OutlineColor, obj.FigureDisplayListID);
        end
        
        GFFigView.setLineAndPointStrength(GFSettings.FigureStrength);
        gfDrawGaugeFigures(objX, objY, cos(fig(4)), sin(fig(4)), fig(3), ...
                           scale, GFSettings.GhostFigureColor, obj.FigureDisplayListID);
      end
      
      if obj.Selecting
        glLineWidth(GFSettings.LassoStrength);
        glColor4dv(GFSettings.LassoColor);
        glVertexPointer(2, GL.DOUBLE, 0, obj.LassoObjCoords);
        glPushMatrix;
          glTranslatef(0, 0, -1);
          glDrawArrays(GL.LINE_LOOP, 0, obj.NPolyPts);
        glPopMatrix;
      end

      Screen('EndOpenGL', obj.Window);
    end
    
    function val = get.UnitsPerPixel(obj)
      global GFSettings;
      
      if GFSettings.FigsUsePerspective
        val = 2*tan(GFSettings.FovY*pi/180/2)/obj.Height;
      else
        val = 2/obj.Height;
      end
    end
    
    function set.CurrentCursor(obj, val)
      obj.CurrentCursor = val;
      if ~isempty(obj.CurrentCursor)
        ShowCursor(obj.CurrentCursor);
        obj.CursorIsHidden = false;
      elseif ~obj.CursorIsHidden % Don't hide cursor twice
        HideCursor;
        obj.CursorIsHidden = true;
      end
    end
    
    function setSelections(obj, indxs, vals)
      global GFSettings;
      
      if isempty(indxs)
        return;
      end
      
      if islogical(indxs)
        indxs = find(indxs);
      end
      
      if ~GFSettings.FigureSelectionEnabled
        obj.FigSet.setSelections(indxs, false);
      else
        vals = logical(vals);
        
        if max(indxs) > size(obj.FigSet.Selections, 1)
          obj.FigSet.setSelections(indxs, vals);
        else
          changed = obj.FigSet.Selections(indxs) ~= vals;
          
          if any(changed)
            if length(vals) == length(indxs)
              obj.FigSet.setSelections(indxs(changed), vals(changed));
            else
              obj.FigSet.setSelections(indxs(changed), vals);
            end
          end
        end
      end
    end
    
    function moveMouseToFigure(obj, indx)
      global GFSettings;
      
      if ~obj.ActiveFigure || GFSettings.ClicklessMode
        ptSetMouseAndWait(obj.FigSet.Xs(indx) + obj.Rect(1), obj.FigSet.Ys(indx) + obj.Rect(2), obj.Window);
        obj.setHoveredFigure(indx);
        obj.updateCursor;
      end
    end
    
    function activateFigure(obj, indx)
      global GFSettings;
      
      if GFSettings.ClicklessMode
        if obj.ActiveFigure
          obj.endFigRotation;
        end
        
        obj.ActiveFigure = indx;
        
        if obj.ActiveFigure
          obj.moveMouseToFigure(obj.ActiveFigure);
          obj.MouseDrag = [0 0];
          obj.startFigRotation;
        end
      end
    end
    
    function updateCursor(obj)
      global GFSettings;
      
      if GFSettings.ClicklessMode
        obj.CurrentCursor = [];
        return;
      end
      
      if obj.HoveredFigure
        obj.CurrentCursor = GFSettings.HoverCursor;
      elseif obj.canAddFigureAtLocation(obj.ViewMousePos)
        obj.CurrentCursor = GFSettings.AddPtCursor;
      else
        obj.CurrentCursor = GFSettings.DefaultCursor;
      end
    end
  end
  
  methods (Access = protected)
    % Input event handlers
    
    function mouseMoved(obj, source, event) %#ok<*INUSL>
      global GFSettings;
      
      if GFSettings.ClicklessMode
        obj.MouseDrag = obj.MouseDrag + event.Delta;
        if obj.ActiveFigure
          obj.doFigRotation;
        end
      else
        obj.ViewMousePos = event.Pos - obj.Pos;
        obj.updateHoveredFigure;
        obj.updateCursor;
      end
    end
    
    function mouseDown(obj, source, event)
      global GFSettings;
      
      if GFSettings.ClicklessMode
        return;
      end
      
      if event.Delta(1) && ~any(event.Buttons(2:end))
        if obj.HoveredFigure && ~obj.SelectionKeyIsDown
          obj.startFigRotation;
        end
        
        obj.HasDraggedMuchTotal = false;
        obj.FirstButton = 1;
      elseif event.Delta(2) && ~any(event.Buttons([1 3:end]))
        obj.HasDraggedMuchTotal = false;
        obj.FirstButton = 2;
      elseif ~any(event.Buttons([1 2]))
        obj.FirstButton = 0;
      end
      
      if any(event.Delta) && ~any(event.Buttons & ~event.Delta)
        obj.MouseDrag = [0 0];
      end
    end
    
    function mouseDragged(obj, source, event)
      global GFSettings;
      
      if GFSettings.ClicklessMode
        obj.mouseMoved(source, event);
        return;
      end
      
      obj.ViewMousePos = event.Pos - obj.Pos;
      obj.MouseDrag = obj.MouseDrag + event.Delta;
      
      if obj.ActiveFigure
        obj.doFigRotation;
      elseif ~obj.Selecting && obj.FirstButton == 1 && ...
             obj.HasDraggedMuchTotal && GFSettings.FigureSelectionEnabled
        obj.Selecting = true;
        obj.initSelection;
      end
        
      if obj.Selecting
        obj.extendSelection;
      end
      
      if any(event.Buttons([1 2]))
        obj.HasDraggedMuchTotal = obj.HasDraggedMuchTotal || ...
          sum(obj.MouseDrag.^2) > GFSettings.MaxAllowedMotionForClick^2;
      end
    end
    
    function mouseUp(obj, source, event)
      global GFSettings;
      
      if GFSettings.ClicklessMode
        return;
      end
      
      if event.Delta(1) && obj.FirstButton == 1
        if obj.ActiveFigure
          obj.endFigRotation;
        elseif ~obj.HoveredFigure && ~obj.HasDraggedMuchTotal && (~any(obj.FigSet.Selections) || obj.SelectionKeyIsDown)
          obj.addFigure;
        elseif obj.HoveredFigure && obj.SelectionKeyIsDown && ~obj.HasDraggedMuchTotal
          obj.setSelections(obj.HoveredFigure, ~obj.FigSet.Selections(obj.HoveredFigure));
        elseif ~obj.Selecting
          obj.setSelections(1:obj.FigSet.NFigures, false);
          obj.updateHoveredFigure;
          obj.updateCursor;
        end
      elseif event.Delta(2) && obj.FirstButton == 2
        if obj.HoveredFigure
          obj.removeFigures(obj.HoveredFigure);
        else
          obj.updateHoveredFigure;
          obj.updateCursor;
        end
      else
        obj.updateHoveredFigure;
        obj.updateCursor;
      end
      
      obj.HasDraggedMuchTotal = false;
      obj.Selecting = false;
    end
    
    function mouseEntered(obj, source, event)
      obj.mouseMoved(source, PTMouseEvent(event.Pos, event.Buttons, [0 0]));
    end
    
    function mouseExited(obj, source, event) %#ok<*INUSD>
      obj.setHoveredFigure(0);
    end
    
    function keyDown(obj, source, event)
      global GFSettings;
      
      if any(event.Delta(GFSettings.SelectionKey));
        obj.SelectionKeyIsDown = true;
      end
      
      if GFSettings.FigureAdditionEnabled && any(event.Delta(GFSettings.InsertionKey))
        obj.InsertionKeyIsDown = true;
        obj.updateHoveredFigure;
        obj.updateCursor;
      end
      
      if any(event.Delta(GFSettings.DeleteKey))
        obj.removeFigures(obj.FigSet.Selections);
        obj.setSelections(1:obj.FigSet.NFigures, false);
      end
    end
    
    function keyUp(obj, source, event)
      global GFSettings;
      
      if any(event.Delta(GFSettings.SelectionKey))
        obj.SelectionKeyIsDown = false;
      end
      
      if GFSettings.FigureAdditionEnabled && any(event.Delta(GFSettings.InsertionKey))
        obj.InsertionKeyIsDown = false;
        obj.updateHoveredFigure;
        obj.updateCursor;
      end
    end
    
    % Figure event handlers
    
    function hoveredFigureChanged(obj, source, event)
      obj.updateFigColors(event.Indxs);
    end
    
    function figureRotationStarted(obj, source, event)
      obj.updateFigColors(event.Indxs);
    end
    
    function figureRotationEnded(obj, source, event)
      obj.updateFigColors(event.Indxs);
    end
    
    function figuresAdded(obj, source, event)
      obj.updateHoveredFigure;
      obj.updateCursor;
      obj.updateFigColors(event.Indxs);
      obj.updateFigObjCoords(event.Indxs);
      obj.updateTiltTrigCache(event.Indxs);
      obj.updateSlantLimits(event.Indxs);
    end
    
    function figuresRemoved(obj, source, event)
      % The colons below are surprisingly vital, since otherwise if the
      % last figure is deleted by itself, MATLAB decides to delete the
      % column, not the row (leaving a 1x0 matrix), which then gets fed to
      % gfDrawFigures, leading it to think there is 1 figure and not 0, and
      % fiery death ensues.
      
      obj.FigObjXs(event.Indxs,:) = [];
      obj.FigObjYs(event.Indxs,:) = [];
      obj.CosTilts(event.Indxs,:) = [];
      obj.SinTilts(event.Indxs,:) = [];
      obj.SlantLimits(event.Indxs,:) = [];
      obj.FigColors(:,event.Indxs) = [];
      
      obj.HoveredFigure = 0;
      obj.updateHoveredFigure;
      obj.updateCursor;
    end
    
    function figureTiltsChanged(obj, source, event)
      obj.updateTiltTrigCache(event.Indxs);
      obj.updateSlantLimits(event.Indxs);
    end
    
    function figureSelectionsChanged(obj, source, event)
      obj.updateFigColors(event.Indxs);
    end
    
    function figureVisibilitiesChanged(obj, source, event)
      obj.updateHoveredFigure;
      obj.updateCursor;
    end
    
    function viewReshaped(obj, source, event)
      obj.updateFigObjCoords(1:obj.FigSet.NFigures);
      obj.updateSlantLimits(1:obj.FigSet.NFigures);
    end
    
    % Interface action implementations
    
    function startFigRotation(obj)
      global GFSettings;

      if ~GFSettings.ClicklessMode
        obj.ActiveFigure = obj.HoveredFigure;
        HideCursor;
        GrabCursor;
      end
          
      if ~obj.FigSet.Selections(obj.ActiveFigure) || ~GFSettings.FigureMultirotationEnabled
        obj.setSelections(1:obj.FigSet.NFigures, false);
      end
      
      affected = obj.getAffectedFiguresForRotation;
      
      obj.prepareFigRotOffsets(affected);
      
      notify(obj, 'FigureRotationStarted', FigureEvent(affected));
    end
    
    function doFigRotation(obj)
      global GFSettings;
      
      affected = obj.getAffectedFiguresForRotation;
      
      if any(obj.MouseDrag)
        obj.FigSet.setActivations(affected, true);
      end
      
      totOffsX = obj.MouseDrag(1) + obj.FigRotOffsetsX(affected);
      totOffsY = obj.MouseDrag(2) + obj.FigRotOffsetsY(affected);
      totOffMags = sqrt(totOffsX.^2 + totOffsY.^2);
      excessAmts = (totOffMags - GFSettings.FigRotSens).*(totOffMags > GFSettings.FigRotSens);
      obj.FigSet.setTilts(affected, -atan2(totOffsY, totOffsX));
      obj.FigSet.setSlants(affected, min(totOffMags, GFSettings.FigRotSens)./ ...
                                     GFSettings.FigRotSens.*obj.SlantLimits(affected));

      % These lines prevent "saturation" of the rotation when the mouse
      % moves too far away from the figure.
      
      obj.FigRotOffsetsX(affected) = obj.FigRotOffsetsX(affected) - obj.CosTilts(affected).*excessAmts;
      obj.FigRotOffsetsY(affected) = obj.FigRotOffsetsY(affected) + obj.SinTilts(affected).*excessAmts;
      
      notify(obj, 'FigureRotating', FigureEvent(affected));
    end
    
    function endFigRotation(obj)
      global GFSettings;
      
      affected = obj.getAffectedFiguresForRotation;
      obj.ActiveFigure = 0;
      
      if ~GFSettings.ClicklessMode
        ReleaseCursor;
        ShowCursor(obj.CurrentCursor);
      end
      
      notify(obj, 'FigureRotationEnded', FigureEvent(affected));
    end
    
    function affected = getAffectedFiguresForRotation(obj)
      global GFSettings;
      
      if GFSettings.FigureMultirotationEnabled
        affected = [obj.ActiveFigure; find(obj.FigSet.Selections)];
      else
        affected = obj.ActiveFigure;
      end
    end
    
    function addFigure(obj)
      if obj.canAddFigureAtLocation(obj.ViewMousePos)
        if ~isempty(obj.Delegate)
          figToAdd = obj.Delegate.figureForLocation(obj.ViewMousePos);
        else
          figToAdd = [obj.ViewMousePos 0 0];
        end

        if ~isempty(figToAdd)
          obj.FigSet.addFigures(figToAdd);
          obj.setSelections(obj.FigSet.NFigures, obj.SelectionKeyIsDown);
        end
      end
    end
    
    function removeFigures(obj, indxs)
      global GFSettings;
      
      if GFSettings.FigureRemovalEnabled
        obj.FigSet.removeFigures(indxs);
      end
    end
    
    % State/utility functions
    
    function yesno = canAddFigureAtLocation(obj, pos)
      global GFSettings;
      
      yesno = GFSettings.FigureAdditionEnabled && ~isempty(obj.Delegate) && obj.Delegate.validFigureLocation(obj.ViewMousePos);
    end
    
    function updateHoveredFigure(obj)
      global GFSettings;
      
      if obj.InsertionKeyIsDown
        obj.setHoveredFigure(0);
        return;
      end
      
      visibleIndxs = find(obj.FigSet.Visibilities);
      dists = (obj.ViewMousePos(1) - obj.FigSet.Xs(visibleIndxs)).^2 + ...
              (obj.ViewMousePos(2) - obj.FigSet.Ys(visibleIndxs)).^2;
      [dist indx] = min(dists);
      
      if dist < GFSettings.DefaultFigScale^2
        obj.setHoveredFigure(visibleIndxs(indx));
      else
        obj.setHoveredFigure(0);
      end
    end
    
    function setHoveredFigure(obj, val)
      oldHF = obj.HoveredFigure;
      obj.HoveredFigure = val;
      
      if obj.HoveredFigure ~= oldHF
        if obj.HoveredFigure
          if oldHF
            indxs = [obj.HoveredFigure oldHF];
          else
            indxs = obj.HoveredFigure;
          end
        else
          indxs = oldHF;
        end
        
        notify(obj, 'HoveredFigureChanged', FigureEvent(indxs));
      end
    end
    
    function updateFigColors(obj, indxs)
      global GFSettings;
      
      if isempty(indxs)
        return;
      end
      
      if ~islogical(indxs)
        sel = false(obj.FigSet.NFigures, 1);
        sel(indxs) = true;
      else
        sel = indxs;
        indxs = find(indxs);
      end
      
      isActive = obj.ActiveFigure > 0;
      
      obj.FigColors(:,indxs) = repmat(GFSettings.UnactivatedFigColor(:), 1, nnz(indxs));
      
      indxs = sel;
      
      sel = indxs & obj.FigSet.Activations;
      obj.FigColors(:,sel) = repmat(GFSettings.ActivatedFigColor(:), 1, nnz(sel));
      
      sel = indxs & obj.FigSet.Selections;
      if isActive
        color = GFSettings.ActiveFigColor;
      else
        color = GFSettings.SelectedFigColor;
      end
      obj.FigColors(:,sel) = repmat(color(:), 1, nnz(sel));

      if isActive
        obj.FigColors(:,obj.ActiveFigure) = GFSettings.ActiveHoveredFigColor;
      end

      if obj.HoveredFigure > 0 && ~isActive
        if obj.FigSet.Selections(obj.HoveredFigure)
          obj.FigColors(:,obj.HoveredFigure) = GFSettings.SelectedHoveredFigColor;
        elseif obj.FigSet.Activations(obj.HoveredFigure)
          obj.FigColors(:,obj.HoveredFigure) = GFSettings.ActivatedHoveredFigColor;
        else
          obj.FigColors(:,obj.HoveredFigure) = GFSettings.UnactivatedHoveredFigColor;
        end
      end
    end
    
    function initSelection(obj)
      upp = obj.UnitsPerPixel;
      
      obj.NPolyPts = 2;
      obj.Lasso(1:2,:) = [obj.ViewMousePos; obj.ViewMousePos];
      obj.LassoObjCoords(:,1) = [(obj.ViewMousePos(1) - obj.Width/2)*upp;
                                         (obj.Height/2 - obj.ViewMousePos(2))*upp];
      obj.LassoObjCoords(:,2) = obj.LassoObjCoords(:,1);
    end
    
    function extendSelection(obj)
      global GFSettings;
      
      if obj.NPolyPts < 639 && ... % Very strange bug in glDrawElements: when it hits 640, death
         (obj.ViewMousePos(1) - obj.Lasso(end - 1,1))^2 + ...
         (obj.ViewMousePos(2) - obj.Lasso(end - 1,2))^2 > GFSettings.MinSelectAddPtDist^2
        obj.NPolyPts = obj.NPolyPts + 1;
      end

      upp = obj.UnitsPerPixel;
      
      obj.Lasso(obj.NPolyPts,:) = obj.ViewMousePos;
      obj.LassoObjCoords(:,obj.NPolyPts) = [(obj.ViewMousePos(1) - obj.Width/2)*upp;
                                                    (obj.Height/2 - obj.ViewMousePos(2))*upp];

      inside = insidePoly(obj.FigSet.Xs, obj.FigSet.Ys, ...
                          obj.Lasso(1:obj.NPolyPts,1), ...
                          obj.Lasso(1:obj.NPolyPts,2));
      obj.setSelections(1:obj.FigSet.NFigures, obj.SelectionKeyIsDown & obj.FigSet.Selections | inside);
    end
    
    function updateFigObjCoords(obj, indxs)
      if obj.FigSet.NFigures
        upp = obj.UnitsPerPixel;
        obj.FigObjXs(indxs,1) = (obj.FigSet.Xs(indxs) - obj.Width/2)*upp;
        obj.FigObjYs(indxs,1) = (obj.Height/2 - obj.FigSet.Ys(indxs))*upp;
      end
    end
    
    function updateTiltTrigCache(obj, indxs)
      obj.CosTilts(indxs,1) = cos(obj.FigSet.Tilts(indxs));
      obj.SinTilts(indxs,1) = sin(obj.FigSet.Tilts(indxs));
    end
    
    function updateSlantLimits(obj, indxs)
      if isempty(indxs)
        return;
      end
      
      viewDirs = [obj.FigObjXs(indxs) obj.FigObjYs(indxs) -ones(numel(indxs), 1)];
      viewDirs = bsxfun(@rdivide, viewDirs, sum(viewDirs.^2, 2));
      tempThing = viewDirs(:,1).*obj.CosTilts(indxs) + viewDirs(:,2).*obj.SinTilts(indxs);
      obj.SlantLimits(indxs,1) = acos(tempThing./sqrt(viewDirs(:,3).^2 + tempThing.^2));
    end
    
    function prepareFigRotOffsets(obj, indxs)
      global GFSettings;
      
      temp = GFSettings.FigRotSens.*obj.FigSet.Slants(indxs)./obj.SlantLimits(indxs);
      obj.FigRotOffsetsX(indxs) = obj.CosTilts(indxs).*temp;
      obj.FigRotOffsetsY(indxs) = -obj.SinTilts(indxs).*temp;
      obj.FigRotOffsetsX = obj.FigRotOffsetsX(:);
      obj.FigRotOffsetsY = obj.FigRotOffsetsY(:);
    end
    
    function id = initDisplayList(obj)
      global GL;
      global GFSettings;
      
      Screen('BeginOpenGL', obj.Window);
      
      id = glGenLists(1);
      glNewList(id, GL.COMPILE);
        for i = 0:GFSettings.NCircleSegments - 1
          theta = i/GFSettings.NCircleSegments*2*pi;
          glVertex2d(cos(theta), sin(theta));
        end
        glVertex2d(1, 0);
      glEndList;
      
      Screen('EndOpenGL', obj.Window);
    end
  end
    
  methods (Static, Access = protected)
    function prepareOpenGL
      global GL;

      glEnable(GL.LINE_SMOOTH);
      glEnable(GL.POINT_SMOOTH);
      glEnable(GL.BLEND);
      glBlendFunc(GL.SRC_ALPHA, GL.ONE_MINUS_SRC_ALPHA);
      
      glEnableClientState(GL.VERTEX_ARRAY);
    end
    
    function setLineAndPointStrength(strength)
      glLineWidth(strength);
      glPointSize(strength);
    end
  end
end
