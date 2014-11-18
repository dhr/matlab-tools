classdef PTImageLoopView < PTView
  properties
    Images
    InterImageInterval
    CurImageIndx
  end
  
  properties (SetAccess = protected)
    NImages
  end
  
  properties (Access = protected)
    TextureIDs
    NextImageTime
  end
  
  methods
    function obj = PTImageLoopView(window, pos, images, interImageInterval)
      sz = size(images(:,:,1));
      obj = obj@PTView(window, [pos pos + fliplr(sz(1:2))]);
      obj.Images = images;
      obj.InterImageInterval = interImageInterval;
      
      obj.CurImageIndx = obj.NImages;
      obj.NextImageTime = GetSecs;
    end
    
    function set.Images(obj, val)
      if isempty(obj.Images) && ~isempty(val)
        obj.Images = val(1);
      end
      
      for i = 1:length(val)
        obj.Images(i) = val(i);

        if i <= length(obj.TextureIDs) %#ok<*MCSUP>
          Screen('Close', obj.TextureIDs(i));
        end

        obj.TextureIDs(i) = Screen('MakeTexture', obj.Window, obj.Images(i).Data*255);
      end
      
      if length(val) < length(obj.Images)
        obj.Images = obj.Images(1:length(val));
        Screen('Close', obj.TextureIDs(length(val) + 1:end));
        obj.TextureIDs = obj.TextureIDs(1:length(val));
      end
      
      obj.NImages = length(obj.Images);
      if obj.NImages
        obj.Dimensions = [obj.Images(1).Width obj.Images(1).Height];
      else
        obj.Dimensions = [0 0];
      end
    end
    
    function render(obj)
      if ~obj.NImages
        return;
      end
      
      if GetSecs > obj.NextImageTime
        obj.CurImageIndx = obj.CurImageIndx + 1;
        if obj.CurImageIndx > obj.NImages
          obj.CurImageIndx = 1;
        end
        
        obj.NextImageTime = GetSecs + obj.InterImageInterval;
      end
      
      i = obj.CurImageIndx;
      Screen('DrawTexture', obj.Window, obj.TextureIDs(i), [0 0 obj.Images(i).Width obj.Images(i).Height], obj.Rect);
    end
    
    function delete(obj)
      if ~isempty(obj.TextureIDs)
        Screen('Close', obj.TextureIDs);
      end
    end
  end
end