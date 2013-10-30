#include <mex.h>
#include <math.h>
#include <string.h>

#define is1DVec(a) (mxGetM((a)) == 1 || mxGetN((a)) == 1)
#define getLength(a) (mxGetM((a))*mxGetN((a)))
#define max(a, b) ((a) > (b) ? (a) : (b))
#define min(a, b) ((a) < (b) ? (a) : (b))
#define bound(a, b, c) (max(min((a), (c)), (b)))

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
  const mxArray *image, *points, *radii, *brightnesses, *colors;
  mxArray *output;
  double *out, *img, *pts, *rads, *brights, *colormap;
  int nrows, ncols, npixels, npts, ncolors;
  int radsIs1D, radsIsScalar, brightsIsScalar;
  int rgbOut;
  int i;
  
  if (nrhs != 4 && nrhs != 5)
    mexErrMsgTxt("Incorrect number of input arguments.");
  
  if (nlhs != 1)
    mexErrMsgTxt("Incorrect number of output arguments.");
  
  rgbOut = (nrhs == 5);
  
  image = prhs[0];
  img = mxGetPr(image);
  nrows = mxGetDimensions(image)[0];
  ncols = mxGetDimensions(image)[1];
  npixels = nrows*ncols;
  
  points = prhs[1];
  pts = mxGetPr(points);
  npts = mxGetM(points);
  
  if (mxGetN(points) != 2)
    mexErrMsgTxt("The points argument should be an n x 2 matrix.");
  
  radii = prhs[2];
  rads = mxGetPr(radii);
  radsIs1D = is1DVec(radii);
  radsIsScalar = (getLength(radii) == 1);
  
  if ((radsIs1D && getLength(radii) != npts && !radsIsScalar) ||
      (!radsIs1D && (mxGetM(radii) != nrows || mxGetN(radii) != ncols))) {
    mexErrMsgTxt("Radii argument should either be a scalar, a 1-D vector "
                 "corresponding to points, or a 2-D matrix corresponding "
                 "to image.");
  }
  
  brightnesses = prhs[3];
  brights = mxGetPr(brightnesses);
  brightsIsScalar = (getLength(brightnesses) == 1);
  
  if (mxGetM(brightnesses) != npts && getLength(brightnesses) != 1) {
    mexErrMsgTxt("Brightnesses argument should either be a scalar "
                 "or correspond to the points matrix.");
  }
  
  if (rgbOut) {
    colors = prhs[4];
    colormap = mxGetPr(colors);
    ncolors = mxGetM(colors);
    
    if (mxGetN(colors) != 3) {
      mexErrMsgTxt("Colormap should have exactly three columns.");
    }
    
    if (mxGetNumberOfDimensions(image) != 3 ||
        mxGetDimensions(image)[2] != 3) {
      mexErrMsgTxt("Input image should be RGB when using a colormap.");
    }
  }
  
  int dims[] = {nrows, ncols, 1 + 2*rgbOut};
  output = mxCreateNumericArray(2 + rgbOut, dims, mxDOUBLE_CLASS, mxREAL);
  out = mxGetPr(output);
  
  memcpy(out, img, nrows*ncols*(1 + 2*rgbOut)*sizeof(double));
  
  for (i = 0; i < npts; i++) {
    double x = pts[i];
    double y = nrows - pts[i + npts] - 1;
    int row = floor(y);
    int col = floor(x);
    double rad, brightness, red, green, blue;
    int ceilRad, top, left, bottom, right;
    int r, c;
    
    if (!radsIs1D && (row < 0 || row >= nrows || col < 0 || col >= nrows))
      mexErrMsgTxt("Circle center outside bounds of radii matrix.");
    
    rad = radsIs1D ? (radsIsScalar ? rads[0] : rads[i]) : rads[col*nrows + row];
    brightness = brightsIsScalar ? brights[0] : brights[i];
    ceilRad = ceil(rad);
    top = max(row - ceilRad - 1, 0);
    left = max(col - ceilRad - 1, 0);
    bottom = min(row + ceilRad + 1, nrows - 1);
    right = min(col + ceilRad + 1, ncols - 1);
    
    if (rgbOut) {
      int index = brightness - 1;
      red = colormap[index];
      green = colormap[index + ncolors];
      blue = colormap[index + 2*ncolors];
    }
    
    for (r = top; r <= bottom; r++) {
      for (c = left; c <= right; c++) {
        double dx = c - x, dy = r - y;
        double dist = sqrt(dx*dx + dy*dy);
        double edgeDist = rad - dist;
        double coverage = bound(edgeDist + 0.5, 0, 1);
        int indx = c*nrows + r;
        
        if (rgbOut) {
          out[indx] =
            coverage*red + (1 - coverage)*out[indx];
          out[indx + npixels] =
            coverage*green + (1 - coverage)*out[indx + npixels];
          out[indx + 2*npixels] =
            coverage*blue + (1 - coverage)*out[indx + 2*npixels];
        }
        else {
          out[indx] = coverage*brightness + (1 - coverage)*out[indx];
        }
      }
    }
  }
  
  plhs[0] = output;
}