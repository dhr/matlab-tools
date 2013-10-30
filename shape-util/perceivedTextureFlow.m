function [directions amounts] = perceivedTextureFlow(varargin)
%PERCEIVEDTEXTUREFLOW Calculate perceived texture flow given normals.
%   [DIRS AMTS] = PERCEIVEDTEXTUREFLOW(N, PROJ, VD, VU, HORFOV, VERFOV)
%   calculates the perceived texture flow for a given projection type PROJ
%   given normals N, view direction VD, view up vector VU, and horizontal
%   and vertical fields of view HORFOV and VERFOV, returning the
%   directions and "strengths" of the flow (DIRS and AMTS).
%
%   Normals N should be an m x n x 3 matrix containing normal vectors for
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
%   HORFOV and VERFOV are the horizontal and vertical fields of view, in
%   degrees.  If not provided, these default to 45 degrees.
%
%   [DIRS AMTS] = 
%      PERCEIVEDTEXTUREFLOW(N, C, PROJ, VD, VU, HORFOV, VERFOV)
%      includes the effect of non-uniform compression along the
%   vector C, the magnitude of which specifies the magnitude of
%   compression.
%
%   See also FORESHORTENINGFRONNORMALS, SLANTTILTFROMNORMALS,
%   MAKEVIEWRAYS, MANUALRENDER.

[majDirs majLens minDirs minLens] = foreshorteningFromNormals(varargin{:});
directions = majDirs;
amounts = majLens./minLens;