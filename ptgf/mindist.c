#include <mex.h>
#include <math.h>

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
  double *from1 = mxGetPr(prhs[0]);
  double *from2 = mxGetPr(prhs[1]);
  double *to1 = mxGetPr(prhs[2]);
  double *to2 = mxGetPr(prhs[3]);
  int sqrtize = 1;
  
  double *outDists;
  double *out1;
  double *out2;
  
  if (nrhs > 4)
    sqrtize = (int) mxGetScalar(prhs[4]);
  
  mwSize nFromRows = mxGetM(prhs[0]);
  mwSize nFromCols = mxGetN(prhs[0]);
  mwSize nFroms = nFromRows*nFromCols;
  
  if (nFroms != mxGetM(prhs[1])*mxGetN(prhs[1]))
    mexErrMsgTxt("Source coordinate lists are not the same length.");
  
  mwSize nTos = mxGetM(prhs[2])*mxGetN(prhs[2]);
  
  if (nTos != mxGetM(prhs[3])*mxGetN(prhs[3]))
    mexErrMsgTxt("Destination coordinate lists are not the same length.");
  
  if (nlhs > 3) mexErrMsgTxt("Too many output arguments.");
  
  plhs[0] = mxCreateDoubleMatrix(nFromRows, nFromCols, mxREAL);
  outDists = mxGetPr(plhs[0]);
  
  if (nlhs > 1) {
    plhs[1] = mxCreateDoubleMatrix(nFromRows, nFromCols, mxREAL);
    out1 = mxGetPr(plhs[1]);
  }
  
  if (nlhs == 3) {
    plhs[2] = mxCreateDoubleMatrix(nFromRows, nFromCols, mxREAL);
    out2 = mxGetPr(plhs[2]);
  }
  
  for (int i = 0; i < nFroms; ++i) {
    outDists[i] = DBL_MAX;
    
    for (int j = 0; j < nTos; ++j) {
      double diff1 = from1[i] - to1[j];
      double diff2 = from2[i] - to2[j];
      double distSquared = diff1*diff1 + diff2*diff2;
      
      if (distSquared < outDists[i]) {
      	outDists[i] = distSquared;
        switch (nlhs) {
          case 2:
            out1[i] = j;
            break;
            
          case 3:
            out1[i] = to1[j];
            out2[i] = to2[j];
            break;
        }
      }
    }
    
    if (sqrtize) outDists[i] = sqrt(outDists[i]);
  }
}