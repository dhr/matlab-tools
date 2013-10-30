#include <mex.h>

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
  const mxArray *input = prhs[0];
  
	if (!mxIsCell(input))
    mexErrMsgTxt("The input argument should be a cell array.");
  
  mwSize cellM = mxGetM(input);
  mwSize cellN = mxGetN(input);
  
  mwSize nCellElems = cellM*cellN;
  double *pointers[nCellElems];
  
  mxArray *cell = mxGetCell(input, 0);
  mwSize matM = mxGetM(cell);
  mwSize matN = mxGetN(cell);
  
  for (int i = 0; i < nCellElems; ++i) {
    cell = mxGetCell(input, i);
    if (mxGetM(cell) != matM || mxGetN(cell) != matN)
      mexErrMsgTxt("All of the matrices must have the same dimensions.");
    pointers[i] = mxGetPr(cell);
  }
  
  mwSize totM = cellM*matM;
  mwSize totN = cellN*matN;
  
  mxArray *output = mxCreateDoubleMatrix(totM, totN, mxREAL);
  double *outVals = mxGetPr(output);
  
  for (int matJ = 0; matJ < matN; ++matJ) {
    for (int matI = 0; matI < matM; ++matI) {
      int matIndx = matJ*matM + matI;
      
      for (int cellJ = 0; cellJ < cellN; ++cellJ) {
        for (int cellI = 0; cellI < cellM; ++cellI) {
          int totIndx = (matJ*cellN + cellJ)*totM + matI*cellM + cellI;
          int cellIndx = cellJ*cellM + cellI;
          
          outVals[totIndx] = pointers[cellIndx][matIndx];
        }
      }
    }
  }
  
  plhs[0] = output;
}