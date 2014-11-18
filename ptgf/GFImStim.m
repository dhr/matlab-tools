classdef GFImStim < GFStimulus & PTImageView
  methods
    function obj = GFImStim(window, pos, image, mask)
      if ~exist('pos', 'var')
        pos = [0 0];
      end
      
      if ~exist('image', 'var')
        image = PTImage;
      end
      
      if ~exist('mask', 'var')
        mask = PTImage;
      end
      
      image = PTImage(image);
      mask = PTImage(mask);
      
      if any([image.Width image.Height] ~= [mask.Width mask.Height])
        error('Image and mask must have the same dimensions.');
      end
      
      obj = obj@GFStimulus(window, [pos 0 0], mask);
      obj = obj@PTImageView(window, pos, image);
    end
    
    function render(obj)
      obj.render@PTImageView;
    end
  end
end