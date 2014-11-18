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

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
  mxArray *output;
  double *out;
  const mxArray *directions, *points, *magnitudes;
  double *dirs, *ps, *mags;
  int directed;
  
  int nDirRows, nDirCols, nDirElems;
  int nPoints;
  int magsM, magsN;
  int magsIsScalar;
  int magsForPoints;
  int pt;
  
  // Initalize and verify variables
  
  int argi = 4;
  
  if (nrhs > argi) mexErrMsgTxt("Too many input arguments.");
  
  if (nrhs < argi--) directed = 0;
  else directed = (int) mxGetScalar(prhs[argi]);
  
  if (nrhs < argi) mexErrMsgTxt("Not enough input arguments.");
  
  magnitudes = prhs[2];
  points = prhs[1];
  directions = prhs[0];
  
  nDirRows = mxGetM(directions);
  nDirCols = mxGetN(directions);
  nDirElems = nDirRows*nDirCols;
  
  nPoints = mxGetM(points);
  
  if (nlhs > 1) mexErrMsgTxt("Too many output arguments.");
  
  magsM = mxGetM(magnitudes), magsN = mxGetN(magnitudes);
  magsIsScalar = magsM*magsN == 1;
  magsForPoints = magsM*magsN == nPoints && (magsM == 1 || magsN == 1);
  if (!magsIsScalar && !magsForPoints &&
      (nDirRows != magsM || nDirCols != magsN)) {
    mexErrMsgTxt("Magnitudes input must either be a scalar, or correspond"
                 " to the points or directions inputs.");
  }
  
  output = mxCreateDoubleMatrix(nPoints, 2, mxREAL);
  
  dirs = mxGetPr(directions);
  ps = mxGetPr(points);
  mags = mxGetPr(magnitudes);
  out = mxGetPr(output);
  
  // For each point ...
  for (pt = 0; pt < nPoints; pt++) {
    double posX = ps[pt], posY = nDirRows - ps[pt + nPoints] - 1;
    int col = floor(posX);
    int row = floor(posY);
    int valid = in(row, 0, nDirRows) && in(col, 0, nDirCols);
    double lastVecX = 0, lastVecY = 0;
    
    double length = 0;
    double len = magsIsScalar ? mags[0] :
                magsForPoints ? mags[pt] :
                        valid ? mags[col*nDirRows + row] :
                                0;
    int dirSign = sign(len);
    double curlen = 0;
    
    len *= dirSign;

    // ... advect!  Until length traveled is len.
    while (curlen < len && in(row, 0, nDirRows) && in(col, 0, nDirCols)) {
      double s; // How far we have to travel to the next intersection
      double dir = dirs[col*nDirRows + row];
      double vecX = dirSign*cos(dir), vecY = -dirSign*sin(dir);

      // Go along path of least resistance if not directed, i.e.,
      // don't suddenly turn around
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

        // If we still went nowhere, give up
        if (s < MINDIST)
          break;
      }

      curlen += s;

      // Update positions        
      lastVecX = vecX; lastVecY = vecY;
      posX += s*vecX; posY += s*vecY;
      row = floor(posY); col = floor(posX);
    }

    out[pt] = posX;
    out[pt + nPoints] = nDirRows - posY - 1;
  }
  
  plhs[0] = output;
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