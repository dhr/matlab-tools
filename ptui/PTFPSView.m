classdef PTFPSView < PTView
  properties
    Counter = 1
    NFramesToAvg = 20
    TextFormat = PTTextFormat
    FPS
  end
  
  properties (Access = protected)
    LoopStartTime
  end
  
  methods
    function obj = PTFPSView(window, pos, nFramesToAvg, textFormat)
      obj = obj@PTView(window, [pos pos + [30 15]]);
      
      if exist('nFramesToAvg', 'var')
        obj.NFramesToAvg = nFramesToAvg;
      end
      
      if exist('textFormat', 'var')
        obj.TextFormat = textFormat;
      end
      
      obj.LoopStartTime = GetSecs;
    end
    
    function render(obj)
      if ~mod(obj.Counter, obj.NFramesToAvg)
        lastLoopStartTime = obj.LoopStartTime;
        obj.LoopStartTime = GetSecs;
        obj.FPS = obj.NFramesToAvg/(obj.LoopStartTime - lastLoopStartTime);
      end
      obj.Counter = obj.Counter + 1;
      
      obj.TextFormat.apply(obj.Window);
      Screen('DrawText', obj.Window, sprintf('%2.1f', obj.FPS), obj.Rect(1), obj.Rect(2));
    end
  end
end