#include <mex.h>
#include <string.h>
#include <lapack.h>

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
  double *data, *dataEnd, *lu, *det;
  const int *dims;
  int *detDims;
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
  
  lu = mxMalloc(dataInc*sizeof(double));
  ipiv = mxMalloc(n*sizeof(long));
  
  detDims = mxMalloc(ndims*sizeof(int));
  memcpy(detDims, dims, ndims*sizeof(int));
  detDims[0] = 1;
  detDims[1] = 1;
  plhs[0] = mxCreateNumericArray(ndims, detDims, mxDOUBLE_CLASS, mxREAL);
  det = mxGetPr(plhs[0]);
  
  for (; data < dataEnd; data += dataInc, det++) {
    int i;
    double detLcl = 1, *diag = lu;
    memcpy(lu, data, dataInc*sizeof(double));
    dgetrf(&n, &n, lu, &n, ipiv, &info);
    for (i = 0; i < n; ++i, diag += n + 1)
      detLcl *= ((ipiv[i] - 1) != i ? -1 : 1)*(*diag);
    *det = detLcl;
  }
  
  mxFree(ipiv);
  mxFree(lu);
}