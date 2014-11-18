#include <mex.h>
#include <ApplicationServices/ApplicationServices.h>

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
  CGAssociateMouseAndMouseCursorPosition(true);
}