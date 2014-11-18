classdef PTFormattedTextView < PTView
  properties
    Text
    TextPos = [0 0]
    TextFormat
    HorizontalAlignment = 'left' % Can also be 'center or 'right'
    VerticalAlignment = 'top' % Can also be 'center' or 'bottom'
    WrapCol = inf
    LineSpacing = 1.2
  end
  
  properties (Access = protected)
    BoundsNeedUpdating = true
    WrappedText
    Lines
    NLines
    LinePositions
  end
  
  methods
    function obj = PTFormattedTextView(window, textPos, text, format, halign, valign, wrap, lineSpacing)
      obj = obj@PTView(window, [0 0 0 0]);
      
      obj.TextPos = textPos;
      obj.Text = text;
      
      if exist('format', 'var')
        obj.TextFormat = format;
      end
      
      if exist('halign', 'var')
        obj.HorizontalAlignment = halign;
      end
      
      if exist('valign', 'var')
        obj.VerticalAlignment = valign;
      end
      
      if exist('wrap', 'var')
        obj.WrapCol = wrap;
      end
      
      if exist('lineSpacing', 'var')
        obj.LineSpacing = lineSpacing;
      end
      
      obj.updateBounds;
    end
    
    function set.Text(obj, val)
      obj.Text = val;
      obj.WrappedText = WrapString(obj.Text, obj.WrapCol);
      obj.BoundsNeedUpdating = true;
    end
    
    function set.WrappedText(obj, val)
      obj.WrappedText = val;
      obj.Lines = regexp(obj.WrappedText, '(\\n|\n)', 'split');
      obj.NLines = length(obj.Lines);
    end
    
    function set.TextPos(obj, val)
      obj.Pos = obj.Pos + (val - obj.TextPos);
      obj.TextPos = val;
    end
    
    function set.HorizontalAlignment(obj, val)
      obj.HorizontalAlignment = val;
      obj.BoundsNeedUpdating = true; %#ok<*MCSUP>
    end
    
    function set.VerticalAlignment(obj, val)
      obj.VerticalAlignment = val;
      obj.BoundsNeedUpdating;
    end
    
    function set.WrapCol(obj, val)
      obj.WrapCol = val;
      obj.WrappedText = WrapString(obj.Text, obj.WrapCol);
      obj.BoundsNeedUpdating = true;
    end
    
    function updateBounds(obj)
      obj.BoundsNeedUpdating = false;
      
      if isempty(obj.Text)
        obj.Rect = [obj.TextPos obj.TextPos];
        obj.LinePositions = obj.Pos;
        return;
      end
      
      obj.LinePositions = zeros(obj.NLines, 2);
      obj.Rect = [obj.TextPos obj.TextPos];
      
      xp = obj.TextPos(1);
      yp = obj.TextPos(2);
      obj.TextFormat.apply(obj.Window);
      for i = 1:obj.NLines
        [textSize boundsRect] = Screen('TextBounds', obj.Window, obj.Lines{i}, xp, yp);

        offset = [0 0];

        if strcmpi(obj.HorizontalAlignment, 'center')
          offset(1) = -textSize(3)/2;
        elseif strcmpi(obj.HorizontalAlignment, 'right')
          offset(1) = -textSize(3);
        end

        if strcmpi(obj.VerticalAlignment, 'center')
          offset(2) = -textSize(4)/2;
        elseif strcmpi(obj.VerticalAlignment, 'bottom')
          offset(2) = -textSize(4)/2;
        end

        offset = round(offset);
        boundsRect = boundsRect + [offset offset];
        
        obj.LinePositions(i,:) = boundsRect(1:2);
        
        obj.Left = min(obj.Left, boundsRect(1));
        obj.Right = max(obj.Right, boundsRect(3));
        obj.Top = min(obj.Top, boundsRect(2));
        obj.Bottom = max(obj.Bottom, boundsRect(4));
        
        yp = yp + obj.LineSpacing*textSize(4);
      end
    end
    
    function render(obj)
      if obj.BoundsNeedUpdating
        obj.updateBounds;
      end
      
      obj.TextFormat.apply(obj.Window);
      for i = 1:obj.NLines
        Screen('DrawText', obj.Window, obj.Lines{i}, obj.LinePositions(i,1), obj.LinePositions(i,2));
      end
    end
  end
end