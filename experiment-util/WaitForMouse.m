function [x, y, buttons] = WaitForMouse(window, pauseTime)

if ~exist('pauseTime', 'var')
  pauseTime = 20;
end

[x, y, buttons] = GetMouse;
oldX = x; oldY = y; oldButtons = buttons;
while oldX == x && oldY == y && all(oldButtons == buttons)
  oldX = x; oldY = y; oldButtons = buttons;
  [x, y, buttons] = GetMouse;
end
