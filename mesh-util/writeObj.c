#include <mex.h>
#include <stdio.h>
#include <math.h>

#define VS 1
#define TRIS 2
#define NS 3

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
  char *name = mxArrayToString(prhs[0]);
  double *vs = mxGetPr(prhs[VS]);
  double *tris = mxGetPr(prhs[TRIS]);
  double *ns = mxGetPr(prhs[NS]);
  
  size_t nVs = 3*mxGetN(prhs[VS]);
  size_t nTris = 3*mxGetN(prhs[TRIS]);
  size_t nNs = 3*mxGetN(prhs[NS]);
  
  if (mxGetM(prhs[VS]) != 3 || mxGetM(prhs[TRIS]) != 3 || (mxGetM(prhs[NS]) != 3 && nNs))
    mexErrMsgTxt("The supplied vertices, faces, and normals, must all be 3 x n matrices.");
  
  if (nVs != nNs && nNs)
    mexErrMsgTxt("The supplied number of normals does not match the supplied number of vertices.");
  
  FILE *file = fopen(name, "w");
  mxFree(name);
  
  if (file == NULL)
    mexErrMsgTxt("Couldn't open file for writing.");
  
  int i;
  
  for (i = 0; i < nVs; i += 3)
    fprintf(file, "v %f %f %f\n", vs[i], vs[i + 1], vs[i + 2]);
  
  if (nNs) {
    for (i = 0; i < nNs; i += 3) {
      if (isnan(ns[i]) || isnan(ns[i + 1]) || isnan(ns[i + 2]))
        fprintf(file, "vn 0 0 0\n");
      else
        fprintf(file, "vn %f %f %f\n", ns[i], ns[i + 1], ns[i + 2]);
    }
    fprintf(file, "g foo\n");
    for (i = 0; i < nTris; i += 3) {
      fprintf(file, "f %d//%d %d//%d %d//%d\n", (int) tris[i], (int) tris[i],
                                                (int) tris[i + 1], (int) tris[i + 1],
                                                (int) tris[i + 2], (int) tris[i + 2]);
    }
  }
  else {
    fprintf(file, "g foo\n");
    for (i = 0; i < nTris; i += 3)
      fprintf(file, "f %d %d %d\n", (int) tris[i], (int) tris[i + 1], (int) tris[i + 2]);
  }
  
  fprintf(file, "g\n");
  
  fclose(file);
}