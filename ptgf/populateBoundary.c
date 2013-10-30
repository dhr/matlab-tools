#include <stdlib.h>
#include <string.h>
#include <mex.h>

#define SQRT2M1 0.414213562
#define INIT_SIZE_LIM 100

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
  mxArray *edgeArray = mxDuplicateArray(prhs[0]);
  double *edgeData = mxGetPr(edgeArray);
  double figSep = mxGetScalar(prhs[1]);
  
  mxArray *outArray;
  double *outData;
  
  int nRows = mxGetM(edgeArray);
  int nCols = mxGetN(edgeArray);
  int nElems = nRows*nCols;
  int sizeLim = INIT_SIZE_LIM;
  double *xs = mxMalloc(sizeLim*sizeof(double));
  double *ys = mxMalloc(sizeLim*sizeof(double));
  int ptIndx = 0;
  int addPts = 0;
  double arcLength = 0;
  int start, row, col;
  
  if (mxGetClassID(edgeArray) != mxDOUBLE_CLASS)
    mexErrMsgTxt("Only accepts double inputs.");
  
  for (start = 0; start < nElems; ++start) // Find the first point
    if (edgeData[start])
      break;
  
  do {
    row = start%nRows;
    col = start/nRows;
    
    if (addPts) {
      mxDestroyArray(edgeArray);
      edgeArray = mxDuplicateArray(prhs[0]);
      edgeData = mxGetPr(edgeArray);
      arcLength = 0;
    }
    
    while (1) {    
      edgeData[col*nRows + row] = 0;
      
      if (row > 0 && col > 0 && edgeData[(col - 1)*nRows + row - 1]) {
        edgeData[(col - 1)*nRows + row] = 0;
        edgeData[col*nRows + row - 1] = 0;
        --row;
        --col;
        arcLength += SQRT2M1;
      }
      else if (row > 0 && col < nCols - 1 &&
               edgeData[(col + 1)*nRows + row - 1]) {
        edgeData[(col + 1)*nRows + row] = 0;
        edgeData[col*nRows + row - 1] = 0;
        --row;
        ++col;
        arcLength += SQRT2M1;
      }
      else if (row < nRows - 1 && col < nCols - 1 &&
               edgeData[(col + 1)*nRows + row + 1]) {
        edgeData[(col + 1)*nRows + row] = 0;
        edgeData[col*nRows + row + 1] = 0;
        ++row;
        ++col;
        arcLength += SQRT2M1;
      }
      else if (row < nRows - 1 && col > 0 &&
               edgeData[(col - 1)*nRows + row + 1]) {
        edgeData[(col - 1)*nRows + row] = 0;
        edgeData[col*nRows + row + 1] = 0;
        ++row;
        --col;
        arcLength += SQRT2M1;
      }
      else if (row > 0 && edgeData[col*nRows + row - 1])
        --row;
      else if (col < nCols - 1 && edgeData[(col + 1)*nRows + row])
        ++col;
      else if (row < nRows - 1 && edgeData[col*nRows + row + 1])
        ++row;
      else if (col > 0 && edgeData[(col - 1)*nRows + row])
        --col;
      else
        break;
      
      arcLength += 1;
      
      if (addPts && arcLength >= figSep) {
        arcLength -= figSep;
        xs[ptIndx] = col;
        ys[ptIndx++] = row;
        
        if (ptIndx >= sizeLim) {
          sizeLim += sizeLim;
          xs = mxRealloc(xs, sizeLim*sizeof(double));
          ys = mxRealloc(ys, sizeLim*sizeof(double));
        }
      }
    }
    
    figSep = arcLength/((int) (arcLength/figSep + 0.5));
  } while (!addPts++);
  
  mxDestroyArray(edgeArray);
  
  outArray = mxCreateDoubleMatrix(ptIndx, 2, mxREAL);
  outData = mxGetPr(outArray);
  
  memcpy(outData, xs, ptIndx*sizeof(double));
  memcpy(outData + ptIndx, ys, ptIndx*sizeof(double));
  
  mxFree(xs);
  mxFree(ys);
  
  plhs[0] = outArray;
}

