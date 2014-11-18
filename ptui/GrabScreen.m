function image = GrabScreen(window, rect, buffer)
%GRABSCREEN Takes a screenshot of a PsychToolbox window.
%   IMG = GRABSCREEN(WIN, RECT, BUFFER) takes a screenshot of the
%   PsychToolbox window WIN, optionally capturing only the rectangle RECT
%   (following PsychToolbox conventions for rectangles -- [left top right
%   bottom]) and reading from the buffer BUFFER, which can be either
%   'front' (the default) or 'back'.  If RECT is not specified, the entire
%   window is captured.
%
%   To use this function, InitializeMatlabOpenGL must be called prior to
%   any invocation of the Screen function (or this function) in your code.
%
%   See also InitializeMatlabOpenGL.

global GL;

AssertOpenGL;

winRect = Screen('Rect', window);
winWidth = winRect(3) - winRect(1);
winHeight = winRect(4) - winRect(2);

if nargin < 2
  rect = [0 0 winWidth winHeight];
end

if nargin < 3
  buffer = GL.FRONT;
else
  if strcmpi(buffer, 'front')
    buffer = GL.FRONT;
  elseif strcmpi(buffer, 'back')
    buffer = GL.BACK;
  else
    error('The buffer argument should be either ''front'' or ''back''.');
  end
end

saved = glGetIntegerv(GL.READ_BUFFER);
glReadBuffer(buffer);
image = glReadPixels(rect(1), winHeight - rect(4), rect(3) - rect(1), rect(4) - rect(2), GL.RGB, GL.UNSIGNED_BYTE);
glReadBuffer(saved);

image = double(imrotate(image, 90))/255;