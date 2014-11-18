classdef FigureEvent < event.EventData
  properties
    Indxs
  end
  
  methods
    function obj = FigureEvent(indxs)
      if islogical(indxs)
        indxs = find(indxs);
      end
      
      obj.Indxs = indxs;
    end
  end
end