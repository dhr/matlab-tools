classdef PTImage < handle
  properties (SetAccess = protected)
    Data
    Width
    Height
  end
  
  methods
    function obj = PTImage(data)
      if ~exist('data', 'var')
        data = [];
      end
      
      if ischar(data)
        [image map alpha] = imread(data);
        
        if ~isempty(map)
          image = ind2rgb(image, map);
        else        
          if ~isempty(alpha)
            image = cat(3, image, alpha);
          end

          image = double(image)/255;
        end
        
        data = image;
      end
      
      if isa(data, 'PTImage')
        obj = data;
      else
        obj.Data = data;
        obj.Height = size(obj.Data, 1);
        obj.Width = size(obj.Data, 2);
      end
    end
  end
end
