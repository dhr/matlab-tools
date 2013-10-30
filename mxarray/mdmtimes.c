#include <mex.h>
#include <string.h>
#include <blas.h>

#define max(a, b) ((a) > (b) ? (a) : (b))

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
  double *as, *asEnd, *bs, *bsEnd, *cs, *csEnd;
  double zero = 0, one = 1;
  ptrdiff_t andims, bndims, cndims, am, an, bm, bn;
  const int *adims, *bdims;
  int *cdims;
  int aInc, bInc, cInc;
  
  if (nrhs != 2) mexErrMsgTxt("There must be exactly two arguments.");
  
  andims = mxGetNumberOfDimensions(prhs[0]);
  adims = mxGetDimensions(prhs[0]);
  
  bndims = mxGetNumberOfDimensions(prhs[1]);
  bdims = mxGetDimensions(prhs[1]);
  
  am = adims[0];
  an = adims[1];
  bm = bdims[0];
  bn = bdims[1];
  
  if (an != bm) mexErrMsgTxt("Matrix dimensions must agree.");
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
  memcpy(cdims, andims > bndims ? adims : bdims, cndims*sizeof(int));
  cdims[0] = am;
  cdims[1] = bn;
  
  plhs[0] = mxCreateNumericArray(cndims, cdims, mxDOUBLE_CLASS, mxREAL);
  cs = mxGetPr(plhs[0]);
  
  aInc = andims > 2 ? am*an : 0;
  bInc = bndims > 2 || !aInc ? bm*bn : 0;
  cInc = am*bn;
  
  as = mxGetPr(prhs[0]);
  bs = mxGetPr(prhs[1]);
  
  asEnd = as + mxGetNumberOfElements(prhs[0]);
  bsEnd = bs + mxGetNumberOfElements(prhs[1]);
  
  for (; as < asEnd && bs < bsEnd; as += aInc, bs += bInc, cs += cInc) {
    dgemm("N", "N", &am, &bn, &an, &one, as, &am,
          bs, &bm, &zero, cs, &am);
  }
}