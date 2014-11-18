function [oldX oldY] = ptSetMouseAndWait(newX, newY, winOrScr)
  [oldX oldY] = GetMouse(winOrScr);
  if newX ~= oldX || newY ~= oldY % Don't be a silly goose
    SetMouse(newX, newY, winOrScr);
    [tempX tempY] = GetMouse(winOrScr);
    while tempX == oldX && tempY == oldY
      [tempX tempY] = GetMouse(winOrScr);
    end
    MouseWarped(true);
  end
end