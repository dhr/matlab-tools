#include <stdio.h>
#include <string.h>
#include <mex.h>

int readLine(char **line, int *bufLengthPtr, FILE *file);

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
  char *fileName;
  int fileNameLen;
  FILE *filePtr;
  char *line = NULL;
  int lineBufLength = 4;
  char *tok;
  char delims[] = " \t\n\r\f\v";
  double *vertices;
  int vi = 0;
  int vertBufSize = 3*10000;
  mxArray *vsArray;
  double *faces;
  int fi = 0;
  int faceBufSize = 3*10000;
  mxArray *trisArray;
  
  if (!mxIsChar(prhs[0]))
    mexErrMsgTxt("The first argument must be a character array.");
  
  fileNameLen = mxGetM(prhs[0])*mxGetN(prhs[0]) + 1;
  fileName = mxMalloc(fileNameLen*sizeof(char));
  mxGetString(prhs[0], fileName, fileNameLen);
  filePtr = fopen(fileName, "r");
  mxFree(fileName);
  
  if (filePtr == NULL) {
    mexErrMsgTxt("Couldn't open input file for reading.  Note that "
                 "tilde expansions are not supported.");
  }
  
  if (!readLine(&line, &lineBufLength, filePtr))
    mexErrMsgTxt("Empty file.");
  
  vertices = mxMalloc(vertBufSize*sizeof(double));
  faces = mxMalloc(faceBufSize*sizeof(double));
  
  do {
    int i;
    
    if ((tok = strtok(line, delims)) == NULL)
      continue;
    
    if (!strcmp(tok, "v")) {
      if (vi >= vertBufSize - 3) {
        vertBufSize += vertBufSize;
        vertices = mxRealloc(vertices, vertBufSize*sizeof(double));
      }
      
      for (i = 0; i < 3; ++i) {
        tok = strtok(NULL, delims);
        vertices[vi++] = atof(tok);
      }
    }
    else if (!strcmp(tok, "f")) {
      if (fi >= faceBufSize - 6) {
        faceBufSize += faceBufSize;
        faces = mxRealloc(faces, faceBufSize*sizeof(double));
      }
      
      // Read in a triangle
      for (i = 0; i < 3; ++i) {
        tok = strtok(NULL, delims);
        faces[fi++] = atof(tok);
      }
      
      // Check if it was actually a quad, and if so add another triangle
      if ((tok = strtok(NULL, delims)) != NULL) {
        faces[fi] = faces[fi - 3];
        faces[fi + 1] = faces[fi - 1];
        faces[fi + 2] = atof(tok);
        fi += 3;
      }
    }
  } while (readLine(&line, &lineBufLength, filePtr));
  
  fclose(filePtr);
  mxFree(line);
  
  vsArray = mxCreateDoubleMatrix(3, vi/3, mxREAL);
  trisArray = mxCreateDoubleMatrix(3, fi/3, mxREAL);
  
  mxFree(mxGetPr(vsArray));
  mxFree(mxGetPr(trisArray));
  
  mxSetPr(vsArray, vertices);
  mxSetPr(trisArray, faces);
  
  mexCallMATLAB(1, plhs, 1, &vsArray, "transpose");
  mexCallMATLAB(1, plhs + 1, 1, &trisArray, "transpose");
}

int readLine(char **line, int *bufLengthPtr, FILE *file) {
  int end = 0;
  int bufLength = *bufLengthPtr;
  
  if (*line == NULL || *(line)[0] == '\0')
    *line = mxMalloc(bufLength*sizeof(char));
  
  if (fgets(*line, bufLength, file) == NULL)
    return 0;
  
  end = strlen(*line);
  
  while (!feof(file) && (*line)[end - 1] != '\n') {
    bufLength += *bufLengthPtr;
    *line = mxRealloc(*line, bufLength*sizeof(char));
    fgets(*line + end, bufLength - end, file);
    while ((*line)[++end] != '\0');
  }
  
  if (!feof(file))
    (*line)[end - 1] = '\0';
  
  *bufLengthPtr = bufLength;
  
  return 1;
}