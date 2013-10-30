function [normals, depths] = getDenseMeshInfo(window, sz, vs, tris, ns, r, proj, vp, vd, vu, v)
%GETDENSEMESHINFO Get interpolated normals and depths for a mesh.
%   [N D] = GETDENSEMESHINFO(W, SZ, VS, TRIS, NS, R, PROJ, VP, VD, VU, V)
%   renders the mesh specified by VS, TRIS, and NS (vertices, triangles,
%   and normals, respectively, as m x 3 lists) and rotated by the
%   quaternion R into the PsychToolbox window W (can be left empty for
%   automatic creation of a window) using a viewing plane of size SZ under
%   a projection type PROJ from view-point VP, with view direction VD, with
%   view up vector VU, and with view angle V (in the vertical direction).
%
%   W should be the PsychToolbox window you want to use for OpenGL
%   rendering.  If it is left empty, a new window will be created and
%   closed.  Note that InitializeMatlabOpenGL should be called before any
%   PsychToolbox Screen calls are made if a pre-created window is used.
%
%   SZ should be a two-element size vector specifying the size of the
%   viewing plane in pixels (e.g. as would be returned by SIZE).
%
%   VS are the vertices of the mesh as an m x 3 list.
%
%   TRIS is an n x 3 list of indices into VS, specifying the faces of the
%   mesh.
%
%   NS is an m x 3 list of normals corresponding with VS.
%
%   R is a quaternion used to rotate the mesh before rendering.  Defaults
%   to [1 0 0 0] (no rotation).
%
%   PROJ is the projection type to use, can be either 'v' for perspective
%   or 'l' for orthographic.  Defaults to 'v'.
%
%   VP is the view point, defaults to [0 -3 0].
%
%   VD is the view direction, defaults to [0 1 0].
%
%   VU is the view up direction, defaults to [0 0 1].
%
%   V is the horizontal field of view, in degrees, defaults to 45.

global GL;

AssertOpenGL;
InitializeMatlabOpenGL;

Screen('Preference', 'SkipSyncTests', 1);

close = false;

if isscalar(sz)
  sz = [sz sz];
end

if isempty(window)
  window = Screen('OpenWindow', max(Screen('Screens')));
  close = true;
end

if nargin < 5
  error('Not enough input arguments.');
end

if nargin < 6
  r = [1 0 0 0];
end

if nargin < 7
  proj = 'v';
end

if nargin < 8
  vp = [0 -3 0];
end

if nargin < 9
  vd = [0 1 0];
end

if nargin < 10
  vu = [0 0 1];
end

if nargin < 11
  v = 45;
end

if strcmpi(proj, 'v')
  v = atan(sz(1)/sz(2)*tan(v*pi/180))*180/pi; % Convert horizontal FOV to vertical FOV
end

vs = vs';
ns = ns';
tris = uint32(tris - 1)';

Screen('BeginOpenGL', window);

haveFBOs = ~isempty(strfind(glGetString(GL.EXTENSIONS), '_framebuffer_object')) && ...
           ~isempty(strfind(glGetString(GL.EXTENSIONS), '_texture_float'));
         
if ~haveFBOs
  Screen('EndOpenGL', window);
  Screen('Close', window);
  error('Frame buffer objects not available.');
end

fpInternalFormat = GL.RGBA_FLOAT32_ATI;

fbo = glGenFramebuffersEXT(1);
colorRBO = glGenRenderbuffersEXT(1);
depthRBO = glGenRenderbuffersEXT(1);

glBindFramebufferEXT(GL.FRAMEBUFFER_EXT, fbo);
glBindRenderbufferEXT(GL.RENDERBUFFER_EXT, colorRBO);
glRenderbufferStorageEXT(GL.RENDERBUFFER_EXT, fpInternalFormat, sz(2), sz(1));
glFramebufferRenderbufferEXT(GL.FRAMEBUFFER_EXT, GL.COLOR_ATTACHMENT0_EXT, ...
                             GL.RENDERBUFFER_EXT, colorRBO);
glBindRenderbufferEXT(GL.RENDERBUFFER_EXT, depthRBO);
glRenderbufferStorageEXT(GL.RENDERBUFFER_EXT, GL.DEPTH_COMPONENT, sz(2), sz(1));
glFramebufferRenderbufferEXT(GL.FRAMEBUFFER_EXT, GL.DEPTH_ATTACHMENT_EXT, ...
                             GL.RENDERBUFFER_EXT, depthRBO);

shaderbase = fullfile(fileparts(mfilename('fullpath')), 'shaders', 'NormalInterpolation');
normalInterpShader = LoadGLSLProgramFromFiles({[shaderbase '.vert'], [shaderbase '.frag']});
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

glViewport(0, 0, sz(2), sz(1));

aspect = sz(2)/sz(1);

glMatrixMode(GL.PROJECTION);
glLoadIdentity;

if strcmp(proj, 'l')
  glOrtho(-aspect, aspect, -1, 1, 1, 10);
elseif strcmp(proj, 'v')
  gluPerspective(v, aspect, 1, 10);
else
  error('The ''proj'' parameter must be one of ''v'' or ''l''.');
end

glMatrixMode(GL.MODELVIEW);

glClearColor(0, 0, 0, 1);
glClear(GL.COLOR_BUFFER_BIT);
glClear(GL.DEPTH_BUFFER_BIT);

glPolygonMode(GL.FRONT_AND_BACK, GL.FILL);

glPushMatrix;
gluLookAt(vp(1), vp(2), vp(3), vp(1) + vd(1), vp(2) + vd(2), vp(3) + vd(3), vu(1), vu(2), vu(3));
if r(1) ~= 1
  glRotatef(2*acos(r(1))*180/pi, r(2), r(3), r(4));
end
glDrawElements(GL.TRIANGLES, numel(tris), GL.UNSIGNED_INT, tris);
glPopMatrix;

info = double(glReadPixels(0, 0, sz(2), sz(1), GL.RGBA, GL.FLOAT));

normals = info(:,:,1:3);

normals(:,:,1) = rot90(normals(:,:,1));
normals(:,:,2) = rot90(normals(:,:,2));
normals(:,:,3) = rot90(normals(:,:,3));

depths = rot90(info(:,:,4));
  
glUseProgram(0);
glBindFramebufferEXT(GL.FRAMEBUFFER_EXT, 0);
glDeleteFramebuffersEXT(1, fbo);
glDeleteRenderbuffersEXT(1, colorRBO);
glDeleteRenderbuffersEXT(1, depthRBO);

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
