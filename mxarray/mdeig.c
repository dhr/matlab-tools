#include <mex.h>
#include <string.h>
#include <lapack.h>

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
  double *data, *dataTemp, *dataEnd;
  mxArray *eigvals, *eigvecs;
  double *evalsr, *evalsi, *evecsr, *evecsi, *evecsTemp, *work;
  ptrdiff_t m, n, ndims;
  const int *dims;
  int *eigvalDims;
  int dataInc, evalInc, evecInc;
  ptrdiff_t lwork, info;
  double *dummy;
  int count = 0;
  
  if (nrhs != 1) mexErrMsgTxt("Exactly one argument is expected.");
  
  ndims = mxGetNumberOfDimensions(prhs[0]);
  dims = mxGetDimensions(prhs[0]);
  m = dims[0];
  n = dims[1];
  
  if (m != n) mexErrMsgTxt("Matrices must be square.");
  
  data = mxGetPr(prhs[0]);
  dataInc = n*n;
  dataEnd = data + mxGetNumberOfElements(prhs[0]);
  dataTemp = mxMalloc(dataInc*sizeof(double));
  
  eigvecs = mxCreateNumericArray(ndims, dims, mxDOUBLE_CLASS, mxCOMPLEX);

  eigvalDims = mxMalloc(ndims*sizeof(int));
  memcpy(eigvalDims, dims, ndims*sizeof(int));
  eigvalDims[1] = 1;
  eigvals = mxCreateNumericArray(ndims, eigvalDims, mxDOUBLE_CLASS, mxCOMPLEX);
  
  evecInc = n*n;
  evalInc = n;
  
  evecsr = mxGetPr(eigvecs);
  evecsi = mxGetPi(eigvecs);
  evalsr = mxGetPr(eigvals);
  evalsi = mxGetPi(eigvals);
  evecsTemp = mxMalloc(evecInc*sizeof(double));
  
  lwork = 6*n;
  work = mxMalloc(lwork*sizeof(double));
  
  dummy = mxMalloc(evecInc*sizeof(double));
  
  for (; data < dataEnd; data += dataInc,
                         evalsr += evalInc,
                         evalsi += evalInc,
                         evecsr += evecInc,
                         evecsi += evecInc) {
    int i;
    
    memcpy(dataTemp, data, dataInc*sizeof(double));
    dgeev("N", "V", &n, dataTemp, &n, evalsr, evalsi,
          dummy, &n, evecsTemp, &n, work, &lwork, &info);
    
    memcpy(evecsr, evecsTemp, evecInc*sizeof(double));
    for (i = 0; i < n; ++i) {
      if (evalsi[i] != 0) {
        int j;
        for (j = 0; j < n; j++) {
          evecsr[(i + 1)*n + j] = evecsTemp[i*n + j];
          evecsi[i*n + j] = evecsTemp[(i + 1)*n + j];
          evecsi[(i + 1)*n + j] = -evecsi[i*n + j];
        }
        
        ++i;
      }
    }
  }
  
  mxFree(work);
  mxFree(dummy);
  mxFree(evecsTemp);
  mxFree(dataTemp);
  
  plhs[0] = eigvecs;
  
  if (nlhs > 1)
    plhs[1] = eigvals;
  else
    mxDestroyArray(eigvals);
}