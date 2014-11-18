classdef PTFixationPointView < PTView
  properties
    FixationPosition
    Radius
    Strength
    Color
  end
  
  methods
    function obj = PTFixationPointView(window, rect, fixPtPos, rad, strength, color)
      obj = obj@PTView(window, rect);
      obj.FixationPosition = fixPtPos;
      obj.Radius = rad;
      obj.Strength = strength;
      obj.Color = color;
    end
    
    function render(obj)
      Screen('DrawLine', obj.Window, obj.Color, ...
        obj.Pos(1) + obj.FixationPosition(1) - obj.Radius, obj.Pos(2) + obj.FixationPosition(2), ...
        obj.Pos(1) + obj.FixationPosition(1) + obj.Radius - 1, obj.Pos(2) + obj.FixationPosition(2), ...
        obj.Strength);
      Screen('DrawLine', obj.Window, obj.Color, ...
        obj.Pos(1) + obj.FixationPosition(1), obj.Pos(2) + obj.FixationPosition(2) - obj.Radius + 1, ...
        obj.Pos(1) + obj.FixationPosition(1), obj.Pos(2) + obj.FixationPosition(2) + obj.Radius, ...
        obj.Strength);
    end
  end
end