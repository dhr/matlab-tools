#include <mex.h>
#include <string.h>
#include <lapack.h>

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
  double *data, *dataEnd, *out, *work;
  const int *dims;
  ptrdiff_t *ipiv;
  ptrdiff_t ndims, m, n, dataInc, info;
  
  if (nrhs != 1) mexErrMsgTxt("Exactly one argument is expected.");
  
  ndims = mxGetNumberOfDimensions(prhs[0]);
  dims = mxGetDimensions(prhs[0]);
  m = dims[0];
  n = dims[1];
  
  if (m != n) mexErrMsgTxt("Matrices must be square.");
  
  data = mxGetPr(prhs[0]);
  dataInc = n*n;
  dataEnd = data + mxGetNumberOfElements(prhs[0]);
  
  ipiv = mxMalloc(n*sizeof(long));
  work = mxMalloc(n*sizeof(double));
  
  plhs[0] = mxCreateNumericArray(ndims, dims, mxDOUBLE_CLASS, mxREAL);
  out = mxGetPr(plhs[0]);
  
  for (; data < dataEnd; data += dataInc, out += dataInc) {
    memcpy(out, data, dataInc*sizeof(double));
    dgetrf(&n, &n, out, &n, ipiv, &info);
    dgetri(&n, out, &n, ipiv, work, &n, &info);
  }
  
  mxFree(ipiv);
  mxFree(work);
}