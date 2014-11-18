#include <mex.h>
#include <ApplicationServices/ApplicationServices.h>

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
  int32_t x, y;
  
  CGGetLastMouseDelta(&x, &y);
  
  if (nlhs >= 1)
    plhs[0] = mxCreateDoubleScalar(x);
  
  if (nlhs == 2)
    plhs[1] = mxCreateDoubleScalar(y);
  else if (nlhs > 2)
    mexErrMsgTxt("Too many output values... only two are returned.");
}