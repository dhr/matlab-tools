classdef PTTextView < PTView
  properties
    Text
    TextFormat = PTTextFormat
  end
  
  methods
    function obj = PTTextView(window, rect, text, format)
      obj = obj@PTView(window, rect);
      
      obj.Text = text;
      
      if exist('format', 'var')
        obj.TextFormat = format;
      end
    end
    
    function render(obj)
      obj.TextFormat.apply(obj.Window);
      Screen('DrawText', obj.Window, obj.Text, obj.Rect(1), obj.Rect(2));
    end
  end
end