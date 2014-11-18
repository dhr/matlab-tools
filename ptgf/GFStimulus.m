classdef GFStimulus < PTView
  properties
    Mask
  end
  
  methods
    function obj = GFStimulus(window, rect, mask)
      if ~exist('rect', 'var')
        rect = [0 0 0 0];
      end
      
      if ~exist('mask', 'var')
        mask = PTImage;
      end
      
      obj = obj@PTView(window, rect);
      obj.Mask = mask;
    end
  end
end
