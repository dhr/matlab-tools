classdef PTUILoop < handle
  properties (SetAccess = protected)
    Window
    WinRect
    ContainerView
    Running = false
  end
  
  properties (Access = protected)
    StopRequested = false
    MousePos
    MouseButtons
    KeyCodes
    ActiveView = 0
    ViewUnderMouse = 0
    OkToUseGMD = true
    LastEventTic
    LastLoopTic
  end
  
  events
    UILoopStarted
    UILoopRunning
    UILoopStopped
  end
  
  methods
    function obj = PTUILoop(window, views)
      if ~exist('views', 'var')
        views = {};
      end
      
      obj.Window = window;
      obj.WinRect = Screen('Rect', obj.Window);
      
      obj.ContainerView = PTContainerView(obj.Window, obj.WinRect, views);
      
      [obj.MousePos(1) obj.MousePos(2) obj.MouseButtons] = GetMouse(obj.Window);
      [ignore ignore obj.KeyCodes] = KbCheck; %#ok<*ASGLU>
    end
    
    function run(obj)
      obj.Running = true;
      obj.StopRequested = false;
      GetMouseDelta; % This call makes sure GetMouseDelta is accurate from the start
      
      notify(obj, 'UILoopStarted');
      
      obj.LastEventTic = tic;
      obj.LastLoopTic = tic;
      
      while ~obj.StopRequested
        Screen('BlendFunction', obj.Window, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
        
        if obj.ContainerView.Visible
          obj.ContainerView.render;
        
          Screen('Flip', obj.Window); % , 0, 0, 2, 0); % Don't sync with display... 3-4x higher FPS

          obj.dispatchMouseEvents;
          obj.dispatchKeyEvents;
        end
        
        if toc(obj.LastEventTic) > 1
          WaitSecs(0.1);
        else
          WaitSecs(max(0.03 - toc(obj.LastLoopTic), 0));
          obj.LastLoopTic = tic;
        end
        
        notify(obj, 'UILoopRunning');
      end
      
      obj.Running = false;
      
      notify(obj, 'UILoopStopped');
    end
    
    function stop(obj)
      obj.StopRequested = true;
    end
  end
  
  methods (Access = protected)
    function sendEvent(obj, name, event)
      notify(obj.ActiveView, name, event);
      obj.LastEventTic = tic;
    end
    
    function dispatchMouseEvents(obj)
      lastPos = obj.MousePos;
      lastButtons = obj.MouseButtons;
      [obj.MousePos(1) obj.MousePos(2) obj.MouseButtons] = GetMouse(obj.Window);
      obj.MousePos = floor(obj.MousePos);
            
      anyButtons = any(obj.MouseButtons);
      anyLastButtons = any(lastButtons);
      
      [motionDelta(1) motionDelta(2)] = GetMouseDelta;

      mouseWarped = MouseWarped;
      if mouseWarped
        obj.OkToUseGMD = false;
      end
      
      if ~obj.OkToUseGMD % Compensate for GetMouseDelta bug
        if any(motionDelta) && ~mouseWarped
          obj.OkToUseGMD = true;
        end
        motionDelta = obj.MousePos - lastPos;
      end
      
      if ~anyButtons || ~anyLastButtons
        obj.ViewUnderMouse = obj.ContainerView.viewUnderPoint(obj.MousePos);
        
        if ~anyButtons && anyLastButtons && obj.ActiveView ~= 0
          obj.sendEvent('MouseUp', PTMouseEvent(obj.MousePos, obj.MouseButtons, lastButtons & ~obj.MouseButtons));
        end

        if obj.ViewUnderMouse ~= obj.ActiveView
          if obj.ActiveView ~= 0
            obj.sendEvent('MouseExited', PTMouseEvent(obj.MousePos, obj.MouseButtons, motionDelta));
          end

          obj.ActiveView = obj.ViewUnderMouse;
          activeViewChanged = true;

          if obj.ActiveView ~= 0
            obj.sendEvent('MouseEntered', PTMouseEvent(obj.MousePos, obj.MouseButtons, motionDelta));
          end
        else
          activeViewChanged = false;
        end
        
        if obj.ActiveView ~= 0
          if ~anyButtons
            if any(motionDelta) && ~activeViewChanged
              if mouseWarped
                obj.sendEvent('MouseWarped', PTMouseEvent(obj.MousePos, obj.MouseButtons, motionDelta));
              else
                obj.sendEvent('MouseMoved', PTMouseEvent(obj.MousePos, obj.MouseButtons, motionDelta));
              end
            end
          else
            obj.sendEvent('MouseDown', PTMouseEvent(obj.MousePos, obj.MouseButtons, obj.MouseButtons & ~lastButtons));
          end
        end
      else        
        if obj.ActiveView ~= 0 && any(motionDelta)
          if mouseWarped
            obj.sendEvent('MouseWarped', PTMouseEvent(obj.MousePos, obj.MouseButtons, motionDelta));
          else
            obj.sendEvent('MouseDragged', PTMouseEvent(obj.MousePos, obj.MouseButtons, motionDelta));
          end
        end
      end
    end
    
    function dispatchKeyEvents(obj)
      lastKeyCodes = obj.KeyCodes;
      [ignore ignore obj.KeyCodes] = KbCheck;
      
      justPressed = obj.KeyCodes & ~lastKeyCodes;
      justReleased = lastKeyCodes & ~obj.KeyCodes;
      
      something = false;
      if any(justPressed)
        obj.ContainerView.dispatchEventThroughSubviews('KeyDown', PTKeyEvent(obj.KeyCodes, justPressed));
        something = true;
      end
      
      if any(justReleased)
        obj.ContainerView.dispatchEventThroughSubviews('KeyUp', PTKeyEvent(obj.KeyCodes, justReleased));
        something = true;
      end
      
      if something
        obj.LastEventTic = tic;
      end
    end
  end
end
