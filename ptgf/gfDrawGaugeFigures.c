#include <math.h>
#include <mex.h>
#include <OpenGL/gl.h>

#define PI 3.141592653589793

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
  double *objXs, *objYs, *tiltsX, *tiltsY, *slants, scale, *colors;
  int usePerspective, circleListID;
  int i, nFigures, nColors;
  double defaultNormal[3] = {0, 0, 1};
  
  nFigures = mxGetM(prhs[0]);
  objXs = mxGetPr(prhs[0]);
  objYs = mxGetPr(prhs[1]);
  tiltsX = mxGetPr(prhs[2]);
  tiltsY = mxGetPr(prhs[3]);
  slants = mxGetPr(prhs[4]);
  scale = mxGetScalar(prhs[5]);
  colors = mxGetPr(prhs[6]);
  nColors = mxGetN(prhs[6]);
  circleListID = (int) mxGetScalar(prhs[7]);
  
  for (i = 0; i < nFigures; ++i) {
    double *color = colors + i*3*(nColors > 1);
      
    glPushMatrix();
      glTranslatef(objXs[i], objYs[i], -1);
      glRotated(slants[i]*180/PI, -tiltsY[i], tiltsX[i], 0);
      glScaled(scale, scale, scale);
      
      glColor4d(color[0], color[1], color[2], 0.1);
      glBegin(GL_POLYGON);
        glCallList(circleListID);
      glEnd();
      
      glColor4d(color[0], color[1], color[2], 1);
      glBegin(GL_LINE_STRIP);
        glCallList(circleListID);
      glEnd();
      glBegin(GL_LINES);
        glVertex3d(0, 0, 0);
        glVertex3d(0, 0, 1);
      glEnd();
      glBegin(GL_POINTS);
        glVertex3d(0, 0, 1);
      glEnd();
    glPopMatrix();
  }
}