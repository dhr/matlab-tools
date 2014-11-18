#include <mex.h>
#include <math.h>
#include <stdlib.h>

#define PI 3.14159265358979
#define NUDGE 1e-10
#define COSSMALLTHETA 0.99862953475457
#define MINDIST 1e-5
#define INITBUFSIZE 100
#define NSMOOTHS 5

#define in(a, b, c) ((a) >= (b) && (a) < (c))
#define sign(a) ((a) >= 0 ? 1 : -1)
#define min(a, b) ((a) < (b) ? (a) : (b))
#define max(a, b) ((a) > (b) ? (a) : (b))
#define bound(a, b, c) (min(max((a), (b)), (c)))
#define mod(a, b) ((a)%(b) < 0 ? (a)%(b) + (b) : (a)%(b))
#define hann(a, b) (0.5*(1 - cos(2*PI*((a) - (b)/2)/(b))));

double findIntx(double, double, double, double);
double getNbhdAvgValue(const mxArray *, int, int, double);

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
  mxArray *output, *energies;
  double *out, *enrgs;
  const mxArray *directions, *texture, *magnitudes;
  double *dirs, *tex, *mags;
  int directed;
  
  int nDirRows, nDirCols, nDirElems;
  int nTexRows, nTexCols;
  int magsIsScalar, freeMagnitudes = 0;
  int computeEnergies = 0;
  int elem;
  
  int *brokenStreams, nBrokenStreams = 0, bufSize = INITBUFSIZE;
  int stream;
  
  // Initalize and verify variables
  
  int argi = 4;
  
  if (nrhs > argi) mexErrMsgTxt("Too many input arguments.");
  
  if (nrhs < argi--) directed = 0;
  else directed = (int) mxGetScalar(prhs[argi]);
  
  if (nrhs < argi--) {
    magnitudes = mxCreateDoubleMatrix(1, 1, mxREAL);
    freeMagnitudes = 1;
    mxGetPr(magnitudes)[0] = 10;
  }
  else magnitudes = prhs[argi];
  
  if (nrhs < argi) mexErrMsgTxt("Not enough input arguments.");
  
  directions = prhs[1];
  texture = prhs[0];
  
  nDirRows = mxGetM(directions);
  nDirCols = mxGetN(directions);
  nDirElems = nDirRows*nDirCols;
  
  nTexRows = mxGetM(texture);
  nTexCols = mxGetN(texture);
  
  // If there are two output params, user wants energies
  if (nlhs == 2) {
    computeEnergies = 1;
    energies = mxCreateDoubleMatrix(nDirRows, nDirCols, mxREAL);
    enrgs = mxGetPr(energies);
  }
  else if (nlhs > 2) mexErrMsgTxt("Too many output arguments.");
  
  magsIsScalar = (mxGetM(magnitudes) == 1 && mxGetN(magnitudes) == 1);
  if (!magsIsScalar && (nDirRows != mxGetM(magnitudes) ||
                        nDirCols != mxGetN(magnitudes))) {
    mexErrMsgTxt("Magnitudes input must either be a scalar, or have the same"
                 "dimensions as the directions matrix.");
  }
  
  output = mxCreateDoubleMatrix(nDirRows, nDirCols, mxREAL);
  
  dirs = mxGetPr(directions);
  tex = mxGetPr(texture);
  mags = mxGetPr(magnitudes);
  out = mxGetPr(output);
  
  brokenStreams = mxMalloc(bufSize*sizeof(int));
  
  // For each element of the vector field ...
  for (elem = 0; elem < nDirElems; elem++) {
    double accum = 0, length = 0;
    double len = magsIsScalar ? mags[0] : mags[elem];
    int dirSign, terminatedEarly = 0;
    
    // ... and for both the positive and negative directions ...
    for (dirSign = -1; dirSign <= 1; dirSign += 2) {
      int row = elem%nDirRows, col = elem/nDirRows;
      double posX = col + 0.5, posY = row + 0.5;
      double lastVecX = 0, lastVecY = 0;
      double curlen = 0;
      
      // ... advect!  Until length traveled is len.
      do {
        double s; // How far we have to travel to the next intersection
        double dir = dirs[col*nDirRows + row];
        double vecX = dirSign*cos(dir), vecY = -dirSign*sin(dir);
        double val = tex[mod(col, nTexCols)*nTexRows + mod(row, nTexRows)];
        
        // Go along path of least resistance if not directed
        if (!directed) {
          double dot = lastVecX*vecX + lastVecY*vecY;
          double dotSign = sign(dot);
          vecX *= dotSign; vecY *= dotSign;
        }
        
        // If the vector is almost horizontal or vertical, make it fully so
        if (abs(vecX) > COSSMALLTHETA) {
          vecX = sign(vecX); vecY = 0;
        }
        else if (abs(vecY) > COSSMALLTHETA) {
          vecX = 0; vecY = sign(vecY);
        }
        
        s = findIntx(posX, posY, vecX, vecY) + NUDGE;
        
        // If we went nowhere, try going parallel to an edge
        if (s < MINDIST) {
          double combinedX = lastVecX + vecX;
          double combinedY = lastVecY + vecY;
          
          if (abs(combinedX) > abs(combinedY)) {
            vecX = sign(combinedX); vecY = 0;
          }
          else {
            vecX = 0; vecY = sign(combinedY);
          }
          
          s = findIntx(posX, posY, vecX, vecY) + NUDGE;
          
          // If we still went nowhere, set flag to add to broken streams
          if (s < MINDIST) {
            terminatedEarly = 1;
            break;
          }
        }
        
        curlen += s;        
        accum += val*s; // Convolve!
        if (computeEnergies) enrgs[elem] += s*s;
        
        // Update positions        
        lastVecX = vecX; lastVecY = vecY;
        posX += s*vecX; posY += s*vecY;
        row = floor(posY); col = floor(posX);
      } while (curlen < len && in(row, 0, nDirRows) && in(col, 0, nDirCols));
      
      length += curlen;
    }
    
    // If stream is broken, add it to brokenStreams
    if (terminatedEarly) {
      brokenStreams[nBrokenStreams++] = elem;
      if (nBrokenStreams >= bufSize) {
        bufSize *= 2;
        brokenStreams = mxRealloc(brokenStreams, bufSize*sizeof(int));
      }
    }
    
    if (computeEnergies) enrgs[elem] /= length*length;
    out[elem] = accum/length;
  }
  
  // Fix broken streams by blurring surroundings
  for (stream = 0; stream < NSMOOTHS*nBrokenStreams; stream++) {
    int row, col;
    elem = brokenStreams[stream%nBrokenStreams];
    row = elem%nDirRows; col = elem/nDirRows;
    out[elem] = getNbhdAvgValue(output, row, col, 3);
    if (computeEnergies) enrgs[elem] = getNbhdAvgValue(energies, row, col, 3);
  }
  
  // Free memory
  if (freeMagnitudes) mxDestroyArray((mxArray *) magnitudes);
  mxFree(brokenStreams);
  
  plhs[0] = output;
  if (computeEnergies) plhs[1] = energies;
}

double findIntx(double posX, double posY, double vecX, double vecY) {
  double sHor, sVer;
  
  sHor = (vecY != 0 ? (floor(posY) - posY)/vecY : mxGetInf());
  if (sHor < 0)
    sHor = (ceil(posY) - posY)/vecY;
  sVer = (vecX != 0 ? (floor(posX) - posX)/vecX : mxGetInf());
  if (sVer < 0)
    sVer = (ceil(posX) - posX)/vecX;
  
  return min(sHor, sVer);
}

double getNbhdAvgValue(const mxArray *image, int row, int col, double size) {
  int nrows = mxGetM(image);
  int rowlim = nrows - 1;
  int collim = mxGetN(image) - 1;
  double *img = mxGetPr(image);
  int convRadius = floor(size/2);
  double sum = 0, windowSum = 0;
  int r, c, i = 0;
  
  for (r = row - convRadius; r <= row + convRadius; r++) {
    for (c = col - convRadius; c <= col + convRadius; c++) {
      int indx = bound(c, 0, collim)*nrows + bound(r, 0, rowlim);
      if (r != row || c != col) {
        double val, dist, window;
        val = img[indx];
        dist = sqrt((row - r)*(row - r) + (col - c)*(col - c));
        dist = (dist > size/2 ? 0 : dist);
        window = hann(dist, size);
        sum += val*window;
        windowSum += window;
      }
    }
  }
  
  return sum/windowSum;
}