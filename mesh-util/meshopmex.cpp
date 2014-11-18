#include <mex.h>
#include "TriMesh_algo.h"

using namespace trimesh;

void fillTriMesh(const mxArray* mxVs,
                 const mxArray* mxTris,
                 const mxArray* mxNs,
                 TriMesh* mesh) {
  if (mxGetM(mxVs) != 3) {
    mexErrMsgTxt("Vertices array should be 3 x n");
  }
  
  if (mxGetM(mxTris) != 3) {
    mexErrMsgTxt("Tris array should be 3 x n");
  }
  
  if (mxNs != NULL && (mxGetM(mxNs) != 3 || mxGetN(mxNs) != mxGetN(mxVs))) {
    mexErrMsgTxt("Normals array should be 3 x number of vertices");
  }
  
  double* verts = mxGetPr(mxVs);
  int nVerts = mxGetN(mxVs);
  
  unsigned int* tris = (unsigned int*) mxGetData(mxTris);
  int nTris = mxGetN(mxTris);
  
  for (int i = 0; i < 3*nVerts; i += 3) {
    mesh->vertices.push_back(point(verts[i], verts[i + 1], verts[i + 2]));
  }
  
  for (int i = 0; i < 3*nTris; i += 3) {
    mesh->faces.push_back(TriMesh::Face(tris[i], tris[i + 1], tris[i + 2]));
  }
  
  if (mxNs != NULL) {
    double* normals = mxGetPr(mxNs);
    for (int i = 0; i < 3*nVerts; i += 3) {
      mesh->normals.push_back(vec(normals[i], normals[i + 1], normals[i + 2]));
    }
  } else {
    mesh->need_normals();
  }
}

void unpackTriMesh(TriMesh& mesh,
                   mxArray** mxVsPtr,
                   mxArray** mxTrisPtr,
                   mxArray** mxNsPtr) {
  if (mxVsPtr != NULL) {
    *mxVsPtr = mxCreateDoubleMatrix(3, mesh.vertices.size(), mxREAL);
    double* verts = mxGetPr(*mxVsPtr);
    
    for (int i = 0; i < mesh.vertices.size(); ++i) {
      verts[3*i] = mesh.vertices[i][0];
      verts[3*i + 1] = mesh.vertices[i][1];
      verts[3*i + 2] = mesh.vertices[i][2];
    }
  }
  
  if (mxTrisPtr != NULL) {
    int nfaces = mesh.faces.size();
    *mxTrisPtr = mxCreateNumericMatrix(3, nfaces, mxUINT32_CLASS, mxREAL);
    unsigned int* tris = (unsigned int*) mxGetData(*mxTrisPtr);
    
    for (int i = 0; i < nfaces; ++i) {
      tris[3*i] = mesh.faces[i][0];
      tris[3*i + 1] = mesh.faces[i][1];
      tris[3*i + 2] = mesh.faces[i][2];
    }
  }
  
  if (mxNsPtr != NULL) {
    mesh.need_normals();
    *mxNsPtr = mxCreateDoubleMatrix(3, mesh.normals.size(), mxREAL);
    double* normals = mxGetPr(*mxNsPtr);
    
    for (int i = 0; i < mesh.normals.size(); ++i) {
      normals[3*i] = mesh.normals[i][0];
      normals[3*i + 1] = mesh.normals[i][1];
      normals[3*i + 2] = mesh.normals[i][2];
    }
  }
}

void mexFunction(int nlhs, mxArray* plhs[], int nrhs, const mxArray* prhs[]) {
  if (nrhs < 3) {
    mexErrMsgTxt("Insufficient number of arguments.");
  }

  TriMesh mesh;
  fillTriMesh(prhs[1], prhs[2],
              nrhs == 4 && !mxIsEmpty(prhs[3]) ? prhs[3] : NULL,
              &mesh);
  
  char command[256];
  mxGetString(prhs[0], command, 256);
  
  if (!strcmp(command, "smooth normals")) {
    diffuse_normals(&mesh, 0.5 * mesh.feature_size());
  } else if (!strcmp(command, "calculate normals")) {
    mesh.need_normals();
  } else if (!strcmp(command, "subdivide mesh")) {
    subdiv(&mesh);
  } else {
    mexErrMsgTxt("Unrecognized command.");
  }
  
  unpackTriMesh(mesh,
                nlhs >= 1 ? plhs + 0 : NULL,
                nlhs >= 2 ? plhs + 1 : NULL,
                nlhs >= 3 ? plhs + 2 : NULL);
}
