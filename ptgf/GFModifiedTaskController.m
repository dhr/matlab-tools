classdef GFModifiedTaskController < GFReconstructionTaskController
  properties
    ToolbarContainer
    ReconstructButton
    DoneButton
    HistoryButtons
    SaveButtons
    RestoreButtons
    SavedStates
    TempSavedState
  end
  
  properties (Access = private)
    AddedListenerNum
    RemovedListenerNum
    StateChangeListenerNum
    Listeners
  end
  
  methods (Access = private)
    function btn = makePushButton(obj, contents)
      global GFSettings;
      path = fullfile(GFSettings.GFRoot, 'images', 'push-button', 'push-button.png');
      btn = PTImageButton(obj.UILoop.Window, [0 0], path, contents);
      btn.TextFormat.Color = [0 0 0];
      btn.TextFormat.Style = PTTextFormat.NORMAL;
      btn.TextFormat.Font = 'Lucida Grande';
      btn.TextFormat.Size = 20;
    end
    
    function btn = makeHistoryButton(obj, amt, direction)
      global GFSettings;
      img = PTImage(fullfile(GFSettings.GFRoot, 'images', 'undo.png'));
      if strcmp(direction, 'forward')
        img = flipdim(img.Data, 2);
      end
      btn = obj.makePushButton(img);
      btn.Text = amt;
      btn.TextFormat.Size = 10;
    end
    
    function btn = makeSaveButton(obj)
      global GFSettings;
      path = fullfile(GFSettings.GFRoot, 'images', 'save-button', 'save-button.png');
      img = PTImage(fullfile(GFSettings.GFRoot, 'images', 'save.png'));
      btn = PTImageButton(obj.UILoop.Window, [0 0], path, img);
      btn.ImageOffset = [5 0];
      btn.TextFormat.Color = [0 0 0];
      btn.TextFormat.Style = PTTextFormat.NORMAL;
      btn.TextFormat.Font = 'Lucida Grande';
      btn.TextFormat.Size = 20;
    end
    
    function btn = makeRestoreButton(obj)
      global GFSettings;
      path = fullfile(GFSettings.GFRoot, 'images', 'open-button', 'open-button.png');
      img = PTImage(fullfile(GFSettings.GFRoot, 'images', 'open.png'));
      btn = PTImageButton(obj.UILoop.Window, [0 0], path, img);
      btn.ImageOffset = [-3 0];
      btn.TextFormat.Color = [0 0 0];
      btn.TextFormat.Style = PTTextFormat.NORMAL;
      btn.TextFormat.Font = 'Lucida Grande';
      btn.TextFormat.Size = 20;
    end
  end
  
  methods
    function obj = GFModifiedTaskController(uiLoop)
      global GFSettings;
      
      obj = obj@GFReconstructionTaskController(uiLoop);

      obj.ShapeView.VertexHighlightColor = GFSettings.HoveredVertexColor;
      obj.ShapeView.VertexHighlightSize = GFSettings.HoveredVertexPointSize;
      
      obj.HistoryButtons = {obj.makeHistoryButton('10x', 'back'), ...
                            obj.makeHistoryButton('1x', 'back'), ...
                            obj.makeHistoryButton('1x', 'forward'), ...
                            obj.makeHistoryButton('10x', 'forward')};
      histContainer = PTLinearLayoutContainer(obj.UILoop.Window, [0 0 0 0], obj.HistoryButtons);
      histContainer.Spacing = 10;
      histContainer.doLayout;
      
      loadSaveContainer = PTLinearLayoutContainer(obj.UILoop.Window, [0 0 0 0]);
      loadSaveContainer.Spacing = 10;
      obj.SavedStates = cell(1, 3);
      for i = 1:length(obj.SavedStates);
        obj.SaveButtons{i} = obj.makeSaveButton;
        obj.RestoreButtons{i} = obj.makeRestoreButton;
        obj.RestoreButtons{i}.Enabled = false;
        
        loadSave = {obj.SaveButtons{i}, obj.RestoreButtons{i}};
        group = PTLinearLayoutContainer(obj.UILoop.Window, [0 0 0 0], loadSave);
        group.doLayout;
        loadSaveContainer.addViews(group);
      end
      loadSaveContainer.doLayout;
      
      obj.ReconstructButton = obj.makePushButton('Reconstruct');
      obj.DoneButton = obj.makePushButton('Done');
      
      rect = obj.UILoop.ContainerView.Rect;
      rect(RectBottom) = rect(RectTop) + 90;
      obj.ToolbarContainer = PTLinearLayoutContainer(obj.UILoop.Window, rect);
      obj.ToolbarContainer.addViews({obj.ReconstructButton, histContainer, ...
                                     loadSaveContainer, obj.DoneButton});
      obj.ToolbarContainer.Spacing = 'Flexible';
      obj.ToolbarContainer.DrawBackground = true;
      obj.ToolbarContainer.BackgroundColor = [1 1 1 0.1];
      obj.ToolbarContainer.FitToContents = false;
      obj.ToolbarContainer.Padding = [50 0 50 0];
      obj.ToolbarContainer.doLayout;
      
      obj.UILoop.ContainerView.addViews(obj.ToolbarContainer);
      
      i = 2;
      obj.Listeners = event.listener(obj.DoneButton, 'ButtonClicked', @obj.doneButtonClicked);
      obj.Listeners(i) = event.listener(obj.ReconstructButton, 'ButtonClicked', @obj.reconstructButtonClicked); i = i + 1;
      
      for j = 1:length(obj.HistoryButtons)
        obj.Listeners(i) = event.listener(obj.HistoryButtons{j}, 'ButtonClicked', @(src, evt) obj.histClicked(j));
        i = i + 1;
      end
      
      for j = 1:length(obj.SaveButtons)
        obj.Listeners(i) = event.listener(obj.SaveButtons{j}, 'ButtonClicked', @(src, evt) obj.saveClicked(j));
        i = i + 1;
        obj.Listeners(i) = event.listener(obj.RestoreButtons{j}, 'ButtonClicked', @(src, evt) obj.restoreClicked(j));
        i = i + 1;
        obj.Listeners(i) = event.listener(obj.RestoreButtons{j}, 'MouseEntered', @(src, evt) obj.restoreEntered(j));
        i = i + 1;
        obj.Listeners(i) = event.listener(obj.RestoreButtons{j}, 'MouseExited', @(src, evt) obj.restoreExited(j));
        i = i + 1;
      end
      
      obj.Listeners(i) = event.listener(obj.FigView, 'MouseMoved', @obj.figViewMouseMoved); i = i + 1;
      
      % Keep me last...
      obj.AddedListenerNum = i; i = i + 1;
      obj.RemovedListenerNum = i; i = i + 1;
      obj.StateChangeListenerNum = i;
    end
    
    function detach(obj)
      obj.detach@GFReconstructionTaskController;
      
      delete(obj.Listeners);
      obj.UILoop.ContainerView.removeViews(obj.ToolbarContainer);
    end
    
    function nextFigure(obj)
      nextFig = obj.FigView.HoveredFigure + 1;
      if nextFig > obj.FigSet.NFigures
        nextFig = 1;
      end
      obj.FigView.moveMouseToFigure(nextFig);
    end
    
    function previousFigure(obj)
      nextFig = obj.FigView.HoveredFigure - 1;
      if nextFig < 1
        nextFig = obj.FigSet.NFigures;
      end
      obj.FigView.moveMouseToFigure(nextFig);
    end
    
    function nextStimulus(obj, stimulus, figs)
      obj.nextStimulus@GFReconstructionTaskController(stimulus, figs);
      
      shiftAmt = round(obj.ToolbarContainer.Height/2);
      obj.FigView.Pos(2) = obj.FigView.Pos(2) + shiftAmt;
      obj.Stimulus.Pos(2) = obj.Stimulus.Pos(2) + shiftAmt;
      obj.ShapeView.Pos(2) = obj.ShapeView.Pos(2) + shiftAmt;
      
      obj.Listeners(obj.AddedListenerNum) = event.listener(obj.FigSet, 'FiguresAdded', @obj.figuresChanged);
      obj.Listeners(obj.RemovedListenerNum) = event.listener(obj.FigSet, 'FiguresRemoved', @obj.figuresChanged);
      obj.Listeners(obj.StateChangeListenerNum) = event.listener(obj.TaskLog, 'StateChanged', @obj.figuresChanged);
      obj.checkActivations;
      obj.setNavEnableds;
    end
    
    function reconstructButtonClicked(obj, source, event) %#ok<*INUSD>
      obj.reconstructShape;
    end
    
    function doneButtonClicked(obj, source, event)
      notify(obj, 'StimulusCompleted');
    end
    
    function histClicked(obj, index)
      switch index
        case 1
          obj.TaskLog.back(10);
        case 2
          obj.TaskLog.back(1);
        case 3
          obj.TaskLog.forward(1);
        case 4
          obj.TaskLog.forward(10);
      end 
    end
    
    function saveClicked(obj, index)
      obj.RestoreButtons{index}.Enabled = true;
      obj.SavedStates{index} = obj.TaskLog.currentState;
    end
    
    function restoreClicked(obj, index)
      obj.TaskLog.restore(obj.SavedStates{index});
      obj.TempSavedState = [];
    end
    
    function restoreEntered(obj, index)
      obj.TempSavedState = obj.TaskLog.currentState;
      obj.TaskLog.restore(obj.SavedStates{index}, false);
    end
    
    function restoreExited(obj, index)
      if ~isempty(obj.TempSavedState)
        obj.TaskLog.restore(obj.TempSavedState, false);
      end
    end
    
    function figuresChanged(obj, source, event)
      obj.checkActivations;
      obj.ShapeView.MaterialColor = [0.7 0.5 0.5];
      obj.setNavEnableds;
    end
    
    function figViewMouseMoved(obj, source, event) %#ok<*INUSL>
      if isempty(obj.Shape.Verts)
        return;
      end
      
      viewPos = event.Pos - obj.FigView.Pos;
      if ptPtInRect(viewPos, obj.FigView.Rect) && obj.ShapeReconstructor.DepthsMask(viewPos(2) + 1, viewPos(1) + 1)
        vertex = obj.ShapeReconstructor.vertexForPosition(viewPos);
      else
        vertex = 0;
      end
      
      obj.ShapeView.HighlightedVertex = vertex;
    end
    
    function checkActivations(obj)
      nActivations = sum(obj.FigSet.Activations);
      
      if nActivations == obj.FigSet.NFigures
        obj.ReconstructButton.Enabled = true;
      else
        obj.ReconstructButton.Enabled = true;
      end
      
      if nActivations == obj.FigSet.NFigures
        obj.DoneButton.Enabled = true;
      else
        obj.DoneButton.Enabled = false;
      end
    end
    
    function setNavEnableds(obj)
      stateEnd = length(obj.TaskLog.StateLog);
      obj.HistoryButtons{1}.Enabled = obj.TaskLog.LogIndex > 10;
      obj.HistoryButtons{2}.Enabled = obj.TaskLog.LogIndex > 1;
      obj.HistoryButtons{3}.Enabled = obj.TaskLog.LogIndex <= stateEnd - 1;
      obj.HistoryButtons{4}.Enabled = obj.TaskLog.LogIndex <= stateEnd - 10;
    end
    
    function reconstructShape(obj)
      obj.ReconstructButton.Enabled = false;
      obj.ShapeReconstructor.updateShape;
      obj.ShapeView.Visible = true;
      obj.ShapeView.MaterialColor = [0.7 0.7 0.7];
    end
  end
end
