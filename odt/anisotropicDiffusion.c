#include <mex.h>
#include <string.h>
#include <math.h>

#define max(a, b) ((a) > (b) ? (a) : (b))
#define min(a, b) ((a) < (b) ? (a) : (b))

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
  mxArray *output, *temp;
  double *out, *tmp;
  const mxArray *image, *orientations, *amounts;
  double *img, *dirs, *amts;
  int iters;
  double dt;
  
  int nrows, ncols, nelems, amtsIsScalar, freeAmounts = 0;
  
  int i;
  
  if (nrhs > 5)
    mexErrMsgTxt("Too many input arguments.");
  
  if (nrhs < 5)
    dt = 0.1;
  else
    dt = mxGetScalar(prhs[4]);
  
  if (nrhs < 4)
    iters = 20;
  else
    iters = mxGetScalar(prhs[3]);
  
  if (nrhs < 3) {
    amounts = mxCreateDoubleMatrix(1, 1, mxREAL);
    freeAmounts = 1;
    mxGetPr(amounts)[0] = 1;
  }
  else
    amounts = prhs[2];
  
  if (nrhs < 2)
    mexErrMsgTxt("Not enough input arguments.");
  
  image = prhs[0];
  img = mxGetPr(image);
  nrows = mxGetM(image);
  ncols = mxGetN(image);
  nelems = nrows*ncols;
  
  orientations = prhs[1];
  dirs = mxGetPr(orientations);
  
  if (mxGetM(orientations) != nrows || mxGetN(orientations) != ncols) {
    mexErrMsgTxt("Orientations matrix must have the same dimensions "
                 "as the image matrix.");
  }
  
  amts = mxGetPr(amounts);
  amtsIsScalar = (mxGetM(amounts) == 1 && mxGetN(amounts) == 1);
  
  if (!amtsIsScalar && (mxGetM(amounts) != nrows || 
                        mxGetN(amounts) != ncols))  {
    mexErrMsgTxt("Amounts matrix must either be a scalar or have "
                 "the same dimensions as the image matrix.");
  }
  
  output = mxCreateDoubleMatrix(nrows, ncols, mxREAL);
  out = mxGetPr(output);
  
  temp = mxCreateDoubleMatrix(nrows, ncols, mxREAL);
  tmp = mxGetPr(temp);
  
  memcpy(out, img, nelems*sizeof(double));

  for (i = 0; i < iters; i++) {
    int e;
    
    for (e = 0; e < nelems; e++) {
      double dir = dirs[e];
      double a1 = 1;
      double a2 = 1 - (amtsIsScalar ? amts[0] : amts[e]);
      double cosdir = cos(dir), sindir = -sin(dir);
      double a11 = a1*a1*cosdir*cosdir + a2*a2*sindir*sindir;
      double a12 = (a2*a2 - a1*a1)*cosdir*sindir;
      double a22 = a2*a2*cosdir*cosdir + a1*a1*sindir*sindir;
      int u = max(e - 1, 0);
      int d = min(e + 1, nelems - 1);
      int l = max(e - nrows, 0);
      int r = min(e + nrows, nelems - 1);
      int ul = (l/nrows)*nrows + u%nrows;
      int dl = (l/nrows)*nrows + d%nrows;
      int ur = (r/nrows)*nrows + u%nrows;
      int dr = (r/nrows)*nrows + d%nrows;
      double convolved = 
        -a12*out[ul] +     2*a22*out[u]     + a12*out[ur] +
        2*a11*out[l] - 4*(a11 + a22)*out[e] + 2*a11*out[r] +
         a12*out[dl] +     2*a22*out[d]     - a12*out[dr];
      tmp[e] = out[e] + dt*convolved/2;
    }
    
    memcpy(out, tmp, nelems*sizeof(double));
  }
  
  if (freeAmounts)
    mxDestroyArray((mxArray *) amounts);
  
  mxDestroyArray(temp);
  
  plhs[0] = output;
}