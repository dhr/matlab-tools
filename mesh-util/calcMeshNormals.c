#include <math.h>
#include <mex.h>
#include <OpenGL/OpenGL.h>

#define setTriple(a, b, c, d) ((a)[0] = (b), \
                               (a)[1] = (c), \
                               (a)[2] = (d))

#define plusEquals(a, b) ((a)[0] += (b)[0], \
                          (a)[1] += (b)[1], \
                          (a)[2] += (b)[2])

#define crossProd(a, b, c) ((a)[0] = (b)[1]*(c)[2] - (c)[1]*(b)[2], \
                            (a)[1] = (b)[2]*(c)[0] - (c)[2]*(b)[0], \
                            (a)[2] = (b)[0]*(c)[1] - (c)[0]*(b)[1])

#define sqr(a) ((a)*(a))

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
  double *verts = mxGetPr(prhs[0]);
  int nVerts = mxGetM(prhs[0])*mxGetN(prhs[0]), vert;
  mxArray *vertNormalsArray = mxCreateDoubleMatrix(3, nVerts/3, mxREAL);
  double *vertNormals = mxGetPr(vertNormalsArray);
  unsigned int *tris = (unsigned int *) mxGetData(prhs[1]), tri;
  int nTriVerts = mxGetM(prhs[1])*mxGetN(prhs[1]);
  double vert1[3], vert2[3], vert3[3], edge1[3], edge2[3], normal[3];
  
  for (tri = 0; tri < nTriVerts; tri += 3) {
    setTriple(vert1, verts[tris[tri]*3], verts[tris[tri]*3 + 1], verts[tris[tri]*3 + 2]);
    setTriple(vert2, verts[tris[tri + 1]*3], verts[tris[tri + 1]*3 + 1], verts[tris[tri + 1]*3 + 2]);
    setTriple(vert3, verts[tris[tri + 2]*3], verts[tris[tri + 2]*3 + 1], verts[tris[tri + 2]*3 + 2]);
    setTriple(edge1, vert2[0] - vert1[0], vert2[1] - vert1[1], vert2[2] - vert1[2]);
    setTriple(edge2, vert3[0] - vert2[0], vert3[1] - vert2[1], vert3[2] - vert2[2]);
    crossProd(normal, edge1, edge2); // normal = edge1 x edge2;
    plusEquals(&vertNormals[tris[tri]*3], normal);
    plusEquals(&vertNormals[tris[tri + 1]*3], normal);
    plusEquals(&vertNormals[tris[tri + 2]*3], normal);
  }
  
  for (vert = 0; vert < nVerts; vert += 3) { // Normalize the normals...
    double mag = sqrt(sqr(vertNormals[vert]) + sqr(vertNormals[vert + 1]) + sqr(vertNormals[vert + 2]));
    vertNormals[vert] /= mag;
    vertNormals[vert + 1] /= mag;
    vertNormals[vert + 2] /= mag;
  }
  
  plhs[0] = vertNormalsArray;
}