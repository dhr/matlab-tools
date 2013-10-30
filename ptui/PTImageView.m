classdef PTImageView < PTView
  properties
    Image
  end
  
  properties (Access = protected)
    TextureID
  end
  
  methods
    function obj = PTImageView(window, pos, image)
      image = PTImage(image);
      obj = obj@PTView(window, [pos pos + [image.Width image.Height]]);
      obj.Image = image;
    end
    
    function set.Image(obj, val)
      obj.Image = PTImage(val);
      obj.Dimensions = [obj.Image.Width obj.Image.Height]; %#ok<*MCSUP>
      
      if obj.TextureID
        Screen('Close', obj.TextureID);
      end
      
      if any(obj.Dimensions)
        obj.TextureID = Screen('MakeTexture', obj.Window, obj.Image.Data*255);
      else
        obj.TextureID = 0;
      end
    end
    
    function render(obj)
      if obj.TextureID
        Screen('DrawTexture', obj.Window, obj.TextureID, [0 0 obj.Image.Width obj.Image.Height], obj.Rect);
      end
    end
    
    function delete(obj)
      if obj.TextureID
        Screen('Close', obj.TextureID);
      end
    end
  end
end