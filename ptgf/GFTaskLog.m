classdef GFTaskLog < handle
  properties
    InitialFigSet
    FinalFigSet
    StateLog
    LogIndex
    StartTime = [0 0 0 0 0 0]
  end
  
  properties (Transient)
    FigView
  end
  
  properties (Transient, Access = protected)
    Listeners
    EventStartTime
    HistoryNavInProgress
  end
  
  properties (Constant)
    ROTATION_STARTED = 1
    ROTATION_ENDED = 2
    FIGURES_ADDED = 3
    FIGURES_REMOVED = 4
    STATE_RESET = 5
  end
  
  events
    StateChanged
  end
  
  methods
    function obj = GFTaskLog(figView, uiLoop)
      obj.FigView = figView;
      obj.InitialFigSet = GFFigSet(obj.FigView.FigSet);
      obj.LogIndex = 1;
      obj.StateLog = struct('EventType', GFTaskLog.STATE_RESET, ...
                            'StartTimeStamp', [], ...
                            'EndTimeStamp', [], ...
                            'Indxs', [], ...
                            'FigData', sparse(obj.InitialFigSet.Figs));
      obj.FinalFigSet = GFFigSet(obj.InitialFigSet);
      obj.HistoryNavInProgress = false;
      
      obj.clear;
      
      addlistener(uiLoop, 'UILoopStopped', @obj.stopLogging);
    end
    
    function clear(obj)
      obj.StartTime = clock;
    end
    
    function set.FigView(obj, val)
      obj.FigView = val;
      
      if ~isempty(obj.FigView)
        obj.setupListeners;
      else
        delete(obj.Listeners); %#ok<*MCSUP>
      end
    end
    
    function setupListeners(obj)
      obj.Listeners = event.listener(obj.FigView, 'FigureRotationStarted', @obj.log);
      obj.Listeners(2) = event.listener(obj.FigView, 'FigureRotationEnded', @obj.log);
      obj.Listeners(3) = event.listener(obj.FigView.FigSet, 'FiguresAdded', @obj.log);
      obj.Listeners(4) = event.listener(obj.FigView.FigSet, 'FiguresRemoved', @obj.log);
    end
    
    function log(obj, source, event) %#ok<*INUSL>
      if obj.HistoryNavInProgress
        obj.HistoryNavInProgress = false;
        obj.log([], struct('EventName', 'StateReset', 'Indxs', []));
      end
      
      switch event.EventName
        case 'FigureRotationStarted'
          obj.EventStartTime = etime(clock, obj.StartTime);
          return;
        case 'FigureRotationEnded'
          eventID = GFTaskLog.ROTATION_ENDED;
        case 'FiguresAdded'
          eventID = GFTaskLog.FIGURES_ADDED;
        case 'FiguresRemoved'
          eventID = GFTaskLog.FIGURES_REMOVED;
        case 'StateReset'
          eventID = GFTaskLog.STATE_RESET;
        otherwise
          return;
      end
      
      if any(strcmp(event.EventName, {'FiguresAdded', 'FiguresRemoved'}))
        obj.EventStartTime = etime(clock, obj.StartTime);
      end
      
      obj.StateLog(end + 1).EventType = eventID;
      obj.StateLog(end).StartTimeStamp = obj.EventStartTime;
      obj.StateLog(end).EndTimeStamp = etime(clock, obj.StartTime);
      obj.StateLog(end).Indxs = event.Indxs;
      obj.StateLog(end).FigData = sparse(obj.FigView.FigSet.Figs);
      
      obj.FinalFigSet = GFFigSet(obj.FigView.FigSet);
      
      obj.LogIndex = length(obj.StateLog);
      
      notify(obj, 'StateChanged');
    end
    
    function back(obj, amount)
      if amount >= obj.LogIndex
        amount = obj.LogIndex - 1;
      end
      
      obj.LogIndex = obj.LogIndex - amount;
      obj.FigView.FigSet = GFFigSet(full(obj.StateLog(obj.LogIndex).FigData));
      
      obj.HistoryNavInProgress = true;
      
      notify(obj, 'StateChanged');
    end
    
    function forward(obj, amount)
      if amount + obj.LogIndex > length(obj.StateLog)
        amount = length(obj.StateLog) - obj.LogIndex;
      end
      
      obj.LogIndex = obj.LogIndex + amount;
      obj.FigView.FigSet = GFFigSet(full(obj.StateLog(obj.LogIndex).FigData));
      
      obj.HistoryNavInProgress = true;
      
      notify(obj, 'StateChanged');
    end
    
    function restore(obj, state, log)
      obj.FigView.FigSet = GFFigSet(full(state.FigData));
      
      if ~exist('log', 'var') || log
        obj.log([], struct('EventName', 'StateReset', 'Indxs', []));
      end
    end
    
    function state = currentState(obj)
      state = obj.StateLog(obj.LogIndex);
    end
    
    function suspendLogging(obj)
      delete(obj.Listeners);
    end
    
    function resumeLogging(obj)
      obj.setupListeners;
    end
    
    function stopLogging(obj, source, event) %#ok<*INUSD>
      obj.FigView = []; % Allow the figure view to be destroyed
    end
  end
end
