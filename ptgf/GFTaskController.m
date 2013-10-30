classdef GFTaskController < PTTaskController
  properties (SetAccess = protected)
    TaskLog
    Stimulus
    FigSet
    FigView
    ScreenshotCounter = 1
  end
  
  properties (Access = private)
    HiddenFigs
    Listeners
  end
  
  events
    StimulusCompleted
  end
  
  methods
    function obj = GFTaskController(uiLoop)
      obj.UILoop = uiLoop;
      
      obj.Stimulus = GFImStim(obj.UILoop.Window);
      obj.FigSet = GFFigSet;
      obj.FigView = GFFigView(obj.UILoop.Window, [0 0 0 0]);
      
      obj.UILoop.ContainerView.addViews({obj.Stimulus, obj.FigView});
      
      obj.Listeners = event.listener(obj.UILoop.ContainerView, 'KeyDown', @obj.globalKeyDown);
      obj.Listeners(2) = event.listener(obj.FigView, 'KeyDown', @obj.keyDown);
      obj.Listeners(3) = event.listener(obj.FigView, 'KeyUp', @obj.keyUp);
    end
    
    function detach(obj)
      obj.UILoop.ContainerView.removeViews({obj.Stimulus, obj.FigView});
    end
    
    function nextStimulus(obj, stimulus, figs, taskLog)
      if exist('figs', 'var')
        if isa(figs, 'GFFigSet')
          obj.FigSet = figs;
        else
          obj.FigSet = GFFigSet(figs);
        end
      else
        obj.FigSet = GFFigSet([]);
      end
      
      obj.UILoop.ContainerView.replaceViews(obj.Stimulus, stimulus);
      obj.Stimulus = stimulus;
      
      obj.FigView.Delegate = obj;
      obj.FigView.FigSet = obj.FigSet;
      
      if ~isempty(obj.TaskLog)
        obj.TaskLog.suspendLogging;
      end
      
      if exist('taskLog', 'var') && ~isempty(taskLog) && taskLog.FigView == obj.FigView
        obj.TaskLog = taskLog;
        obj.TaskLog.resumeLogging;
      else
        obj.TaskLog = GFTaskLog(obj.FigView, obj.UILoop);
      end
    end
    
    function globalKeyDown(obj, source, event)
      global GFSettings;
      
      if any(event.Delta(GFSettings.ScreenshotKey))
        img = GrabScreen(obj.UILoop.Window);
        fname = sprintf('gf-screenshot-%02d.png', obj.ScreenshotCounter);
        imwrite(img, fullfile(GFSettings.ScreenshotSaveDir, fname));
        obj.ScreenshotCounter = obj.ScreenshotCounter + 1;
      end
    end
    
    function valid = validFigureLocation(obj, pos)
      valid = ptPtInRect(pos, [0 0 obj.Stimulus.Dimensions]) && obj.Stimulus.Mask.Data(pos(2) + 1, pos(1) + 1);
    end
  end
  
  methods (Access = private)
    function keyDown(obj, source, event) %#ok<*INUSL>
      global GFSettings;
      
      if event.Delta(GFSettings.NextFigKey)
        if any(event.KeyCodes(GFSettings.ShiftKey))
          obj.previousFigure;
        else
          obj.nextFigure;
        end
      end
      
      if any(event.Delta(GFSettings.HideFigsKey))
        obj.HiddenFigs = find(obj.FigSet.Visibilities);
        obj.FigSet.setVisibilities(obj.HiddenFigs, false);
      end
      
      if any(event.Delta(GFSettings.HideImageKey))
        obj.Stimulus.Visible = false;
      end
    end
    
    function keyUp(obj, source, event)
      global GFSettings;
      
      if any(event.Delta(GFSettings.HideFigsKey))
        obj.FigSet.setVisibilities(obj.HiddenFigs, true);
      end
      
      if any(event.Delta(GFSettings.HideImageKey))
        obj.Stimulus.Visible = true;
      end
    end
  end
  
  methods (Abstract)
    nextFigure(obj);
    previousFigure(obj);
  end
end
