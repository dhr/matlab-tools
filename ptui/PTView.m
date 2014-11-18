classdef PTView < handle
  properties (SetObservable)
    Rect
    Visible = true
    Enabled = true
  end
  
  properties (Dependent)
    Pos
    Dimensions
    Width
    Height
    Left
    Top
    Bottom
    Right
    AspectRatio
  end
  
  properties (SetAccess = protected)
    Window
    WinWidth
    WinHeight
  end
  
  events
    ViewReshaped
    MouseMoved
    MouseDragged
    MouseWarped
    MouseDown
    MouseUp
    MouseEntered
    MouseExited
    KeyDown
    KeyUp
  end
  
  methods
    function obj = PTView(window, rect)
      obj.Window = window;
      obj.Rect = rect;
    end
    
    function set.Window(obj, val)
      obj.Window = val;
      [obj.WinWidth obj.WinHeight] = Screen('WindowSize', obj.Window); %#ok<*MCSUP>
    end
    
    function val = get.Left(obj)
      val = obj.Rect(1);
    end
    
    function set.Left(obj, val)
      obj.Rect(1) = val;
    end
    
    function val = get.Top(obj)
      val = obj.Rect(2);
    end
    
    function set.Top(obj, val)
      obj.Rect(2) = val;
    end
    
    function val = get.Right(obj)
      val = obj.Rect(3);
    end
    
    function set.Right(obj, val)
      obj.Rect(3) = val;
    end
    
    function val = get.Bottom(obj)
      val = obj.Rect(4);
    end
    
    function set.Bottom(obj, val)
      obj.Rect(4) = val;
    end
    
    function val = get.Pos(obj)
      val = obj.Rect(1:2);
    end
    
    function set.Pos(obj, val)
      obj.Rect = [val val + obj.Dimensions];
    end
    
    function val = get.Dimensions(obj)
      val = [obj.Width obj.Height];
    end
    
    function set.Dimensions(obj, val)
      obj.Rect = [obj.Rect(1:2) obj.Rect(1:2) + val];
    end
    
    function val = get.Width(obj)
      val = obj.Rect(3) - obj.Rect(1);
    end
    
    function set.Width(obj, val)
      obj.Rect(3) = obj.Rect(1) + val;
    end
    
    function val = get.Height(obj)
      val = obj.Rect(4) - obj.Rect(2);
    end
    
    function set.Height(obj, val)
      obj.Rect(4) = obj.Rect(2) + val;
    end
    
    function set.Rect(obj, val)
      oldRect = obj.Rect;
      obj.Rect = val;
      if ~isempty(oldRect) && any(obj.Rect ~= oldRect)
        notify(obj, 'ViewReshaped', PTViewEvent(oldRect, obj.Rect));
      end
    end
    
    function val = get.AspectRatio(obj)
      val = obj.Width/obj.Height;
    end
    
    function set.AspectRatio(obj, val)
      obj.Width = val*obj.Height;
    end
  end
  
  methods (Access = protected)
    function configureOpenGLViewport(obj)
      glViewport(obj.Rect(1), obj.WinHeight - 1 - obj.Rect(4), obj.Width, obj.Height);
    end
  end
  
  methods (Abstract)
    render(obj)
  end
end