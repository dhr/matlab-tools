classdef PTKeyEvent < event.EventData
  properties
    KeyCodes
    Delta
  end
  
  methods
    function obj = PTKeyEvent(keyCodes, delta)
      obj.KeyCodes = keyCodes;
      obj.Delta = delta;
    end
  end
end