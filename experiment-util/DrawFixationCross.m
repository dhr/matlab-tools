function DrawFixationCross(window, pos, rad, color, strength)

if nargin < 3
  rad = 10;
end

if nargin < 4
  color = [0 0 0 255];
end

if nargin < 5
  strength = 1;
end

Screen('DrawLine', window, color, pos(1) - rad, pos(2), pos(1) + rad - 1, pos(2), strength);
Screen('DrawLine', window, color, pos(1), pos(2) - rad + 1, pos(1), pos(2) + rad, strength);