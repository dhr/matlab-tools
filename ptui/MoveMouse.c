#include <mex.h>
#include <ApplicationServices/ApplicationServices.h>

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
  CGEventRef event;
  CGPoint offset;
  CGPoint currentLocation;
  CGPoint newLocation;
  
  if (nrhs != 2)
    mexErrMsgTxt("The global x and y coordinates (and only those) must be supplied.");
  
  event = CGEventCreate(NULL);
  currentLocation = CGEventGetLocation(event);
  CFRelease(event);
  
  offset = CGPointMake((CGFloat) mxGetScalar(prhs[0]), (CGFloat) mxGetScalar(prhs[1]));
  newLocation = CGPointMake(currentLocation.x + offset.x, currentLocation.y + offset.y);
  
  event = CGEventCreateMouseEvent(NULL, kCGEventMouseMoved, newLocation, kCGMouseButtonLeft);
  CGEventPost(kCGHIDEventTap, event);
  CFRelease(event);
}