classdef PTButton < PTView
  properties
    Text
    TextOffset
    Image
    ImageOffset
    TextFormat
    DepressedOffset = [0 0]
  end
  
  properties (Access = protected)
    ImageView
    TextTexID
    TextBounds
    TextRect
    ContentsBounds
    Hovered = false
    Depressed = false
    OldCursor
  end
  
  events
    ButtonClicked
  end
  
  methods
    function obj = PTButton(window, rect, contents, textFormat)
      obj = obj@PTView(window, rect);
      
      obj.TextOffset = [0 0];
      obj.ImageOffset = [0 0];
      
      if exist('textFormat', 'var')
        obj.TextFormat = textFormat;
      else
        obj.TextFormat = PTTextFormat;
      end
      
      if ischar(contents)
        obj.Text = contents;
      else
        if ~isa(contents, 'PTImage')
          contents = PTImage(contents);
        end
        
        obj.Image = contents;
      end
      
%       addlistener(obj, 'MouseMoved', @obj.mouseMoved);
      addlistener(obj, 'MouseDown', @obj.mouseDown);
      addlistener(obj, 'MouseDragged', @obj.mouseDragged);
      addlistener(obj, 'MouseUp', @obj.mouseUp);
      addlistener(obj, 'MouseEntered', @obj.mouseEntered);
      addlistener(obj, 'MouseExited', @obj.mouseExited);
      addlistener(obj, 'ViewReshaped', @obj.viewReshaped);
    end
    
    function set.Image(obj, val)
      if ~isa(val, 'PTImage')
        val = PTImage(val);
      end
      
      obj.Image = val;
      
      if ~isempty(obj.Image)
        obj.ImageView = PTImageView(obj.Window, [0 0], obj.Image);
      else
        obj.ImageView = [];
      end
      
      obj.recomputeBounds;
    end
    
    function set.Text(obj, val)
      obj.Text = val;
      obj.recomputeBounds; %#ok<*MCSUP>
      obj.redrawText;
    end
    
    function set.TextFormat(obj, val)
      obj.TextFormat = val;
      obj.recomputeBounds;
      obj.redrawText;
    end
    
    function redrawText(obj)
      if obj.TextTexID
        Screen('Close', obj.TextTexID);
        obj.TextTexID = [];
      end
      
      if ~isempty(obj.Text)
        obj.TextTexID = Screen('MakeTexture', obj.Window, ones(round(obj.TextBounds(4)), round(obj.TextBounds(3)), 4));
        obj.TextFormat.apply(obj.TextTexID);
        Screen('DrawText', obj.TextTexID, obj.Text, 0, 0);
      end
    end
    
    function delete(obj)
      if obj.TextTexID
        Screen('Close', obj.TextTexID);
      end
    end
    
    function renderContents(obj)
      if ~isempty(obj.ImageView)
        if obj.Depressed
          oldPos = obj.ImageView.Pos;
          obj.ImageView.Pos = obj.ImageView.Pos + obj.DepressedOffset;
        end
        
        obj.ImageView.render;
        
        if obj.Depressed
          obj.ImageView.Pos = oldPos;
        end
      end
      
      if ~isempty(obj.TextTexID)
        textPos = obj.TextRect(1:2);
        if obj.Depressed
          textPos = textPos + obj.DepressedOffset;
        end
        textDims = obj.TextBounds(3:4);
        Screen('DrawTexture', obj.Window, obj.TextTexID, [0 0 textDims], [textPos textPos + textDims]);
      end
    end
      
    function recomputeBounds(obj)
      if ~isempty(obj.Text)
        obj.TextFormat.apply(obj.Window);
        obj.TextBounds = Screen('TextBounds', obj.Window, obj.Text);
      else
        obj.TextBounds = [0 0 0 0];
      end
      
      obj.layoutContents;
    end
    
    function layoutContents(obj)
      if ~isempty(obj.Text)
        obj.TextRect = CenterRect(obj.TextBounds, obj.Rect);
        obj.TextRect = obj.TextRect + [obj.TextOffset [0 0]];
        obj.ContentsBounds = obj.TextRect;
      end
      
      if ~isempty(obj.ImageView)
        obj.ImageView.Rect = CenterRect(obj.ImageView.Rect, obj.Rect);
        obj.ImageView.Pos = obj.ImageView.Pos + obj.ImageOffset;
        
        if ~isempty(obj.Text)
          obj.ContentsBounds = UnionRect(obj.ImageView.Rect, obj.ContentsBounds);
        else
          obj.ContentsBounds = obj.ImageView.Rect;
        end
      end
      
      if isempty(obj.Text) && isempty(obj.ImageView)
        obj.ContentsBounds = CenterRect([0 0 0 0], obj.Rect);
      end
    end
    
    function viewReshaped(obj, source, event) %#ok<INUSD>
      obj.layoutContents;
    end
    
%     function mouseMoved(obj, source, event) %#ok<INUSL>
%     end
    
    function mouseDown(obj, source, event) %#ok<INUSL>
      if event.Delta(1)
        obj.Hovered = false;
        obj.Depressed = true;
      end
    end
    
    function mouseDragged(obj, source, event) %#ok<INUSL>
      obj.Depressed = ptPtInRect(event.Pos, obj.Rect);
    end
    
    function mouseUp(obj, source, event) %#ok<INUSL>
      if event.Delta(1) && obj.Depressed
        obj.Depressed = false;
        obj.Hovered = true;
        notify(obj, 'ButtonClicked');
      end
    end
    
    function mouseEntered(obj, source, event) %#ok<INUSD>
      obj.Hovered = true; % ptPtInRect(event.Pos, obj.Rect);
      obj.OldCursor = ShowCursor('Hand');
    end
    
    function mouseExited(obj, source, event) %#ok<INUSD>
      obj.Hovered = false;
      ShowCursor(obj.OldCursor);
    end
  end
end
