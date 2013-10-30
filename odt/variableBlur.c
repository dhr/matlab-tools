#include <mex.h>
#include <math.h>

#define MAXSIGMA 30
#define MINSIGMA 0.15

#define max(a, b) ((a) > (b) ? (a) : (b))
#define min(a, b) ((a) < (b) ? (a) : (b))
#define mod(a, b) ((a)%(b) < 0 ? (a)%(b) + (b) : (a)%(b))

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
  mxArray *output;
  double *out;
  const mxArray *input, *sigmas;
  double *in, *s;
  
  int nrows, ncols;
  int row, col;
  
  int sIsScalar;
  
  if (nrhs != 2)
    mexErrMsgTxt("Incorrect number of input arguments.");
  
  input = prhs[0];
  nrows = mxGetM(input);
  ncols = mxGetN(input);
  
  sigmas = prhs[1];
  sIsScalar = (mxGetM(sigmas) == 1 && mxGetN(sigmas) == 1);
  
  if (!sIsScalar && (mxGetM(sigmas) != nrows || mxGetN(sigmas) != ncols)) {
    mexErrMsgTxt("Sigmas argument must either be a scalar or have the same "
                 "dimensions as the input image.");
  }
  
  output = mxCreateDoubleMatrix(nrows, ncols, mxREAL);
  
  in = mxGetPr(input);
  s = mxGetPr(sigmas);
  out = mxGetPr(output);
  
  for (row = 0; row < nrows; row++) {
    for (col = 0; col < ncols; col++) {
      double accum = 0;
      double windowSum = 0;
      double sigma = min(sIsScalar ? s[0] : s[col*nrows + row], MAXSIGMA);
      double twoS2 = 2*sigma*sigma;
      int size = max(ceil(6*sigma), 3);
      int radius = size/2;
      int r, c;
      
      if (sigma < MINSIGMA) {
        out[col*nrows + row] = in[col*nrows + row];
        continue;
      }
      
      for (r = row - radius; r <= row + radius; r++) {
        for (c = col - radius; c <= col + radius; c++) {
          double dr = row - r;
          double dc = col - c;
          double dist2 = dr*dr + dc*dc;
          double window = exp(-dist2/twoS2);
          int rb = mod(r, nrows);
          int cb = mod(c, ncols);
          accum += in[cb*nrows + rb]*window;
          windowSum += window;
        }
      }
      
      out[col*nrows + row] = accum/windowSum;
    }
  }
  
  plhs[0] = output;
}