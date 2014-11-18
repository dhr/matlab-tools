function [slants tilts] = normalsToSlantTilt(normals, varargin)
%NORMALSTOSLANTTILT Convert normals to slant and tilt.
%   [S T] = NORMALSTOSLANTTILT(N, VD, VU, HORFOV, VERFOV) converts
%   normals N into slants S and tilts T.  View direction VD is assumed to
%   be [0 1 0] if not provided.  View up vector VU defaults to [0 0 1] if
%   not provided.
%
%   View direction and up vectors VD and VU specify the viewing plane, and
%   default to [0 1 0] and [0 0 1], respectively.
%
%   HORFOV and VERFOV are the horizontal and vertical fields of view, in
%   degrees.  If not provided, these default to 45 degrees.
%
%   [S T] = NORMALSTOSLANTTILT(N, VIEW) encapsulates the view parameters in
%   a structure VIEW. This structure must have the fields 'vd', containing
%   the view direction; 'vu', containing the view up direction, and 'va',
%   containing the (horizontal) view angle.
%
%   See also MANUALRENDER, FORESHORTENINGFROMNORMALS,
%   PERCEIVEDTEXTUREFLOW, MAKEVIEWPARAMS.

h = size(normals, 2);
w = size(normals, 3);

if isstruct(varargin{1}) && all(isfield(varargin{1}, {'vd', 'vu', 'va'}))
  v = varargin{1};
  vd = v.vd;
  vu = v.vu;
  viewRays = makeViewRays(w, h, 'l', v.vd, v.vu, v.va);
else
  vd = varargin{1};
  vu = varargin{2};
  viewRays = makeViewRays(w, h, 'l', varargin{:});
end

vr = cross(vd, vu);

nDotVd = squeeze(sum(bsxfun(@times, normals, vd(:))));
vDotVd = squeeze(sum(bsxfun(@times, viewRays, vd(:))));
amts = nDotVd./vDotVd;
projNs = normals - bsxfun(@times, shiftdim(amts, -1), viewRays);

projNsDotVu = squeeze(sum(bsxfun(@times, projNs, vu(:))));
projNsDotVr = squeeze(sum(bsxfun(@times, projNs, vr(:))));

slants = acos(squeeze(sum(-normals.*viewRays)));
tilts = atan2(projNsDotVu, projNsDotVr);
