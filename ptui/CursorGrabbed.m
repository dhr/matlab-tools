function grabbed = CursorGrabbed(yesno)
persistent isGrabbed
mlock

if nargin
  isGrabbed = yesno;
elseif isempty(isGrabbed)
  isGrabbed = false;
end

grabbed = isGrabbed;