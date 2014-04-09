function [normals, depths] = renderDenseMeshInfo(mesh, r, view, window)
%RENDERDENSEMESHINFO Get interpolated normals and depths for a mesh.
%   [N D] = RENDERDENSEMESHINFO(MESH, R, VIEW, WINDOW) renders the mesh
%   specified by MESH and rotated by the quaternion R into the PsychToolbox
%   window WINDOW (can be left empty for automatic creation of a window),
%   using viewing parameters specified by VIEW.
%
%   MESH should be a struct containing the fields 'vs', 'tris', and 'ns',
%   containing the vertices, triangles, and normals, respectively, as m x 3
%   lists.
%
%   R is a quaternion used to rotate the mesh before rendering.  Defaults
%   to [1 0 0 0] (no rotation).
%
%   VIEW should be a struct containing the viewing parameters. See
%   makeViewParams for more information.
%
%   WINDOW should be the PsychToolbox window you want to use for OpenGL
%   rendering.  If it is not provided, a new window will be created and
%   closed.  Note that InitializeMatlabOpenGL should be called before any
%   PsychToolbox Screen calls are made if a pre-created window is used.
%
%   See also: MAKEVIEWPARAMS.

global GL;

AssertOpenGL;
InitializeMatlabOpenGL;

if ~GL.VERSION_3_0
  error('Requires OpenGL 3.0 or later.');
end

Screen('Preference', 'SkipSyncTests', 1);

if ~exist('r', 'var')
  r = [1 0 0 0];
end

if ~exist('view', 'var')
  view = makeViewParams;
end

close = false;
if ~exist('window', 'var') || isempty(window)
  window = Screen('OpenWindow', max(Screen('Screens')));
  close = true;
end

if strcmpi(view.proj, 'v')
  % Convert horizontal FOV to vertical FOV
  v = atan(view.h/view.w*tan(view.va*pi/180))*180/pi;
end

vs = mesh.vs';
ns = mesh.ns';
tris = uint32(mesh.tris - 1)';

Screen('BeginOpenGL', window);

fbo = glGenFramebuffers(1);
colorRBO = glGenRenderbuffers(1);
depthRBO = glGenRenderbuffers(1);

glBindFramebuffer(GL.FRAMEBUFFER, fbo);
glBindRenderbuffer(GL.RENDERBUFFER, colorRBO);
glRenderbufferStorage(GL.RENDERBUFFER, GL.RGBA32F, view.w, view.h);
glFramebufferRenderbuffer(GL.FRAMEBUFFER, GL.COLOR_ATTACHMENT0, ...
                          GL.RENDERBUFFER, colorRBO);
glBindRenderbuffer(GL.RENDERBUFFER, depthRBO);
glRenderbufferStorage(GL.RENDERBUFFER, GL.DEPTH_COMPONENT, view.w, view.h);
glFramebufferRenderbuffer(GL.FRAMEBUFFER, GL.DEPTH_ATTACHMENT, ...
                          GL.RENDERBUFFER, depthRBO);

shaderbase = fullfile(fileparts(mfilename('fullpath')), ...
                      'shaders', 'NormalInterpolation');
shaders = {[shaderbase '.vert'], [shaderbase '.frag']};
normalInterpShader = LoadGLSLProgramFromFiles(shaders);
clampedLoc = glGetUniformLocation(normalInterpShader, 'Clamped');
transformLoc = glGetUniformLocation(normalInterpShader, 'TransformNormal');

glUseProgram(normalInterpShader);
glUniform1i(clampedLoc, false);
glUniform1i(transformLoc, true);

glClearDepth(1000);
glDepthFunc(GL.LEQUAL);
glEnable(GL.DEPTH_TEST);

glEnableClientState(GL.VERTEX_ARRAY);
glEnableClientState(GL.NORMAL_ARRAY);

glVertexPointer(3, GL.DOUBLE, 0, vs);
glNormalPointer(GL.DOUBLE, 0, ns);

% Draw everything in the lower left corner of the window

glViewport(0, 0, view.w, view.h);
aspect = view.w/view.h;

glMatrixMode(GL.PROJECTION);
glLoadIdentity;

if strcmp(view.proj, 'l')
  glOrtho(-aspect, aspect, -1, 1, 1, 10);
elseif strcmp(view.proj, 'v')
  gluPerspective(v, aspect, 1, 10);
else
  error('The ''proj'' parameter must be one of ''v'' or ''l''.');
end

glClearColor(0, 0, 0, 1);
glClear(bitor(GL.COLOR_BUFFER_BIT, GL.DEPTH_BUFFER_BIT));

glMatrixMode(GL.MODELVIEW);
glPushMatrix;
vp = view.vp;
vd = view.vd;
vu = view.vu;
gluLookAt(vp(1), vp(2), vp(3), ...
          vp(1) + vd(1), vp(2) + vd(2), vp(3) + vd(3), ...
          vu(1), vu(2), vu(3));
if r(1) ~= 1
  glRotatef(2*acos(r(1))*180/pi, r(2), r(3), r(4));
end
glDrawElements(GL.TRIANGLES, numel(tris), GL.UNSIGNED_INT, tris);
glPopMatrix;

info = double(glReadPixels(0, 0, view.w, view.h, GL.RGBA, GL.FLOAT));

normals = info(:,:,1:3);

normals(:,:,1) = rot90(normals(:,:,1));
normals(:,:,2) = rot90(normals(:,:,2));
normals(:,:,3) = rot90(normals(:,:,3));

depths = rot90(info(:,:,4));

glUseProgram(0);
glBindFramebuffer(GL.FRAMEBUFFER, 0);
glDeleteFramebuffers(1, fbo);
glDeleteRenderbuffers(1, colorRBO);
glDeleteRenderbuffers(1, depthRBO);

Screen('EndOpenGL', window);

if close
  Screen('Close', window);
end

normals = permute(normals, [3 1 2]);
normals = normals([1 3 2],:,:);
normals(2,:,:) = -normals(2,:,:);

frameInv = transpose([cross(vd(:), vu(:)), vd(:), vu(:)]);
normals = cat(1, ...
  sum(bsxfun(@times, normals, frameInv(:,1)), 1), ...
  sum(bsxfun(@times, normals, frameInv(:,2)), 1), ...
  sum(bsxfun(@times, normals, frameInv(:,3)), 1));
