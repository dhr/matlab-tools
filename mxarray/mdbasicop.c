#include <mex.h>
#include <string.h>

#define max(a, b) ((a) > (b) ? (a) : (b))

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
  double *as, *asEnd, *bs, *bsEnd, *cs, *csEnd;
  int andims, am, an, asArentScalars, copyADims;
  int bndims, bm, bn, bsArentScalars;
  int cndims;
  const int *adims, *bdims;
  int *cdims;
  int aInc, bInc, cInc;
  
  if (nrhs != 3) mexErrMsgTxt("There must be exactly three arguments.");
  if (mxGetClassID(prhs[2]) != mxCHAR_CLASS)
    mexErrMsgTxt("Third argument should be an op character (+,-,*,/).");
  
  andims = mxGetNumberOfDimensions(prhs[0]);
  adims = mxGetDimensions(prhs[0]);
  
  bndims = mxGetNumberOfDimensions(prhs[1]);
  bdims = mxGetDimensions(prhs[1]);
  
  am = adims[0];
  an = adims[1];
  asArentScalars = (am != 1 || an != 1);
  
  bm = bdims[0];
  bn = bdims[1];
  bsArentScalars = (bm != 1 || bn != 1);
  
  if ((am != bm || an != bn) && asArentScalars && bsArentScalars)
    mexErrMsgTxt("Matrix dimensions must agree.");
  if (andims > 2 && bndims > 2) {
    if (andims != bndims) {
      mexErrMsgTxt("Matrix dimensions must agree.");
    }
    else {
      int i;
      for (i = 2; i < andims; ++i) {
        if (adims[i] != bdims[i])
          mexErrMsgTxt("Matrix dimensions must agree.");
      }
    }
  }
  
  cndims = max(andims, bndims);
  cdims = mxMalloc(cndims*sizeof(int));
  copyADims = (andims > bndims || (asArentScalars && !bsArentScalars));
  memcpy(cdims, copyADims ? adims : bdims, cndims*sizeof(int));
  plhs[0] = mxCreateNumericArray(cndims, cdims, mxDOUBLE_CLASS, mxREAL);
  cs = mxGetPr(plhs[0]);
  
  aInc = andims > 2 ? am*an : 0;
  bInc = bndims > 2 || !aInc ? bm*bn : 0;
  cInc = max(aInc, bInc);
    
  as = mxGetPr(prhs[0]);
  bs = mxGetPr(prhs[1]);
  
  asEnd = as + mxGetNumberOfElements(prhs[0]);
  bsEnd = bs + mxGetNumberOfElements(prhs[1]);
  
  switch (*mxGetChars(prhs[2])) {
    case '+':
      for (; as < asEnd && bs < bsEnd; as += aInc, bs += bInc) {
        int i;
        for (i = 0; i < cInc; ++i)
          *(cs++) = as[i*asArentScalars] + bs[i*bsArentScalars];
      }
      break;
    
    case '-':
      for (; as < asEnd && bs < bsEnd; as += aInc, bs += bInc) {
        int i;
        for (i = 0; i < cInc; ++i)
          *(cs++) = as[i*asArentScalars] - bs[i*bsArentScalars];
      }
      break;
    
    case '*':
      for (; as < asEnd && bs < bsEnd; as += aInc, bs += bInc) {
        int i;
        for (i = 0; i < cInc; ++i)
          *(cs++) = as[i*asArentScalars]*bs[i*bsArentScalars];
      }
      break;
      
    case '/':
      for (; as < asEnd && bs < bsEnd; as += aInc, bs += bInc) {
        int i;
        for (i = 0; i < cInc; ++i)
          *(cs++) = as[i*asArentScalars]/bs[i*bsArentScalars];
      }
      break;
      
    default:
      mexErrMsgTxt("Unrecognized op character (should be one of +,-,*,/).");
  }
}