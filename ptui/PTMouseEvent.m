classdef PTMouseEvent < event.EventData
  properties (SetAccess = private)
    Pos
    Buttons
    Delta
  end
  
  methods
    function obj = PTMouseEvent(pos, buttons, delta)
      obj.Pos = pos;
      obj.Buttons = buttons;
      obj.Delta = delta;
    end
  end
end