function warped = MouseWarped(yesno)
persistent wasWarped
mlock

if nargin
  wasWarped = yesno;
else
  warped = wasWarped;
  wasWarped = false;
end