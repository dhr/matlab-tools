classdef GFFigureIDTracker < handle
  properties
    FigSet
  end
  
  properties (SetAccess = protected)
    IDs
    IDCounter
  end
  
  methods
    function obj = GFFigureIDTracker(figSet)
      obj.FigSet = figSet;
    end
    
    function set.FigSet(obj, val)
      obj.FigSet = val;
      obj.IDs = 1:obj.FigSet.NFigures; %#ok<*MCSUP>
      obj.IDCounter = obj.FigSet.NFigures + 1;
    end
    
    function addFigures(obj, indxs)
      nNewFigs = size(indxs);
      oldIDCounter = obj.IDCounter;
      obj.IDCounter = obj.IDCounter + nNewFigs;
      obj.IDs(indxs) = oldIDCounter:obj.IDCounter - 1;
    end
    
    function removeFigures(obj, indxs)
      obj.IDs(indxs) = [];
    end
  end
end