classdef PTSubviewReshapedEvent < PTViewEvent
  properties
    SourceView
  end
  
  methods
    function obj = PTSubviewReshapedEvent(sourceView, oldRect, newRect)
      obj = obj@PTViewEvent(oldRect, newRect);
      obj.SourceView = sourceView;
    end
  end
end