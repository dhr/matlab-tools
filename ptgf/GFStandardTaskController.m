classdef GFStandardTaskController < GFTaskController
  properties
    Order
    RequireFigureAdjustment = true
  end
  
  properties (SetAccess = protected)
    Info
    CurrentFigIndx
  end
  
  methods
    function obj = GFStandardTaskController(uiLoop)
      global GFSettings;
      
      GFSettings.ClicklessMode = true;
      
      obj = obj@GFTaskController(uiLoop);
      
      obj.Info = PTFormattedTextView(obj.UILoop.Window, [obj.UILoop.WinRect(3)/2 10], '', PTTextFormat(20, [1 1 1]), 'center');
      obj.UILoop.ContainerView.addViews(obj.Info);
      obj.Info.Text = '<tab> - Move to next figure';
    end
    
    function detach(obj)
      obj.detach@GFTaskController;
      
      obj.UILoop.ContainerView.removeViews(obj.Info);
      
      ShowCursor;
      ReleaseCursor;
    end
    
    function nextStimulus(obj, stimulus, figs)
      obj.nextStimulus@GFTaskController(stimulus, figs);
      
      pos = [(obj.UILoop.WinRect(3) - stimulus.Mask.Width)/2 ...
             (obj.UILoop.WinRect(4) - stimulus.Mask.Height)/2];
      
      obj.Stimulus.Pos = pos;
      obj.FigView.Rect = obj.Stimulus.Rect;
      
      ReleaseCursor;
      GrabCursor;
      
      obj.resetFigureState;
    end
    
    function resetFigureState(obj)
      obj.CurrentFigIndx = 0;
      nFigs = obj.FigSet.NFigures;
      if isempty(obj.Order) || length(obj.Order) ~= nFigs
        obj.Order = Shuffle(1:nFigs);
      end
      obj.nextFigure;
    end
    
    function nextFigure(obj)
      if ~obj.RequireFigureAdjustment || ~obj.CurrentFigIndx || ...
         obj.FigView.ActiveFigure && obj.FigSet.Activations(obj.FigView.ActiveFigure)
        obj.CurrentFigIndx = obj.CurrentFigIndx + 1;

        if obj.CurrentFigIndx <= length(obj.Order)
          obj.FigView.activateFigure(obj.Order(obj.CurrentFigIndx));
        else
          notify(obj, 'StimulusCompleted');
        end
      end
    end
    
    function previousFigure(obj)
    end
    
    function valid = validFigureLocation(obj, pos)
      valid = false;
    end
    
    function figure = figureForLocation(obj, pos) %#ok<*INUSD,*MANU>
      figure = [pos 0 0 false true false true];
    end
  end
end