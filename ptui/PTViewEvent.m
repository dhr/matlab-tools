classdef PTViewEvent < event.EventData
  properties
    OldRect
    NewRect
  end
  
  methods
    function obj = PTViewEvent(oldRect, newRect)
      obj.OldRect = oldRect;
      obj.NewRect = newRect;
    end
  end
end