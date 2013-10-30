function [majDirs majLens minDirs minLens] = foreshorteningFromNormals(varargin)
%FORESHORTENINGFROMNORMALS Calculate foreshortening given normals.
%   [MAJDIRS MAJLENS MINDIRS MINLENS] =
%      FORESHORTENINGFROMNORMALS(N, PROJ, VD, VU, HFOV, VFOV)
%   calculates the foreshortening for a given projection type PROJ given
%   normals N, view direction VD, view up vector VU, and (horizontal) field
%   of view HFOV, returning the directions and lengths of the major and
%   minor axes of ellipses resulting from projection of circles on the
%   surface (one for each normal) onto the viewing plane (MAJDIRS, MAJLENS,
%   MINDIRS, and MINLENS).
%
%   Normals N should be an 3 x m x n matrix containing normal vectors for
%   each point in an image.
%
%   The projection type PROJ can be one of {'perspective', 'v'} for
%   perspective projection, or {'parallel', 'orthographic', 'l'} for
%   parallel (orthographic) projection.  The default if not specified is
%   parallel.
%
%   View direction and up vectors VD and VU specify the viewing plane, and
%   default to [0 1 0] and [0 0 1], respectively.
%
%   HFOV is the horizontal field of view, in degrees.  If not provided, it
%   defaults to 45 degrees.  If the vertical field of view (VFOV) is not
%   provided then it is calculated as atan(m/n*tan(HFOV)) (where m and n are
%   the dimensions of N).
%
%   Output directions (MAJDIRS and MINDIRS) are calculated with respect to
%   "horizontal" in the image plane, i.e., cross(viewDir, viewUp).
%
%   [MAJDIRS MAJLENS MINDIRS MINLENS] =
%      FORESHORTENINGFROMNORMALS(N, PROJ, VD, VU, VRAYS) is the same as the
%   above, except that instead of specifying the view angle directly, a set
%   of view rays is passed.  This should be an m x n x 3 matrix as returned
%   by MAKEVIEWRAYS.
%
%   [MAJDIRS MAJLENS MINDIRS MINLENS] =
%      FORESHORTENINGFROMNORMALS(N, C, ...)
%   includes the effect of non-uniform compression along the vector C, the
%   magnitude of which specifies the magnitude of compression.
%
%   See also SLANTTILTFROMNORMALS, PERCEIVEDTEXTUREFLOW, MAKEVIEWRAYS,
%   MANUALRENDER.

normals = varargin{1};
normals = bsxfun(@rdivide, normals, sqrt(sum(normals.^2)));

if length(varargin) > 1 && ischar(varargin{2})
  compression = [1 0 0];
  start = 2;
else
  compression = varargin{2};
  start = 3;
end

viewDir = [0 1 0];
viewUp = [0 0 1];

if length(varargin) > start
  viewDir = varargin{start + 1};

  if length(varargin) > start + 1
    viewUp = varargin{start + 2};
  end
end

[viewDir viewUp] = framify(viewDir, viewUp);
viewRight = cross(viewDir, viewUp);

if length(varargin) - start + 1 == 4 && ~isscalar(varargin{end})
  viewRays = varargin{end};
else
  viewRays = makeViewRays(size(normals, 2), size(normals, 3), varargin{start:end});
end

if sum(compression.^2) == 1
  viewRightDotNormals = sum(bsxfun(@times, viewRight, normals));
  surfaceRights = bsxfun(@minus, viewRight, bsxfun(@times, viewRightDotNormals, normals));
  surfaceRights = bsxfun(@rdivide, surfaceRights, sqrt(sum(surfaceRights.^2)));
  surfaceUps = cross(normals, surfaceRights);
  upLen = 1;
else
  compression = compression(:);
  compressionMag = sqrt(sum(compression.^2));
  compressionDotNormals = sum(bsxfun(@times, compression, normals));
  compressionNormalComponents = bsxfun(@times, compressionDotNormals, normals);
  surfaceUps = bsxfun(@minus, compression, compressionNormalComponents);
  surfaceUps = bsxfun(@rdivide, surfaceUps, sqrt(sum(surfaceUps.^2)));
  surfaceRights = cross(surfaceUps, normals);
  intersectionEl = acos(sum(bsxfun(@times, surfaceUps, compression./compressionMag)));
  upLen = sqrt(sin(intersectionEl).^2 + (cos(intersectionEl)./compressionMag).^2);
end

[majDirs majLens minDirs minLens] = ...
  projectEllipse(surfaceRights, bsxfun(@times, surfaceUps, upLen), -viewRays, viewRight, viewUp);