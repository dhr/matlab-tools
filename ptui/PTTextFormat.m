classdef PTTextFormat
  properties
    Size = 16
    Color = [1 1 1]
    Font
    Style = 1
  end
  
  properties (Constant)
    NORMAL = 0
    BOLD = 1
    ITALIC = 2
    UNDERLINE = 4
    OUTLINE = 8
    CONDENSE = 32
    EXTEND = 64
  end
  
  methods
    function obj = PTTextFormat(size, color, font, style)
      if exist('size', 'var')
        obj.Size = size;
      end
      
      if exist('color', 'var')
        obj.Color = color;
      end
      
      if exist('font', 'var')
        obj.Font = font;
      else
        obj.Font = Screen('Preference', 'DefaultFontName');
      end
      
      if exist('style', 'var')
        obj.Style = style;
      end
    end
    
    function apply(obj, window)
      Screen('TextSize', window, obj.Size);
      Screen('TextFont', window, obj.Font);
      Screen('TextStyle', window, obj.Style);
      Screen('TextColor', window, obj.Color*255);
    end
  end
end
