function varargout = makeViewRays(varargin)
%MAKEVIEWRAYS Create a set of view rays for a given projection type.
%   [RAYS DU DV COVUV COVVV] = MAKEVIEWRAYS(U, V, PROJ, VD, VU, HFOV, VFOV)
%   creates a U x V set of view rays RAYS for projection type PROJ,
%   centered on the view direction VD and oriented with respect to view up
%   vector VU, with (horizontal) field of view HFOV.
%
%   U and V are the horizontal vertical resolutions (RAYS is then a 3 x V x
%   U matrix).
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
%   defaults to 45 degrees.  The vertical field of view is then
%   calculated as atan(U/V*tan(FOV)), if not provided explicity as HFOV.
%
%   When using the perspective projection type, additional optional output
%   arguments are available:
%
%   Output arguments DU and DV return the spacing between adjacent elements
%   of the image plane (for coordinates u and v, respectively).
%
%   Output arguments COVUV and COVVV return the covariant derivative (at each
%   point in the image plane) of the view vector, with respect to the u and
%   v coordinates respectively.
%
%   See also FORESHORTENINGFROMNORMALS, NORMALSTOSLANTTILT,
%   PERCEIVEDTEXTUREFLOW.

if length(varargin) < 6
  vh = 45;
else
  vh = varargin{6};
  if length(varargin) > 6
    vv = varargin{7};
  end
end

if length(varargin) < 5
  viewUp = [0 0 1];
else
  viewUp = varargin{5};
end

if length(varargin) < 4
  viewDir = [0 1 0];
else
  viewDir = varargin{4};
end

if length(varargin) < 3
  projType = 'l';
else
  projType = varargin{3};
end

resU = varargin{1};
resV = varargin{2};

[viewDir viewUp] = framify(viewDir, viewUp);
viewRight = cross(viewDir, viewUp);

switch projType
  case {'perspective', 'v'}
    vh = vh*pi/180;
    if ~exist('vv', 'var')
      vv = atan(tan(vh)*resU/resV);
    end
    uMax = tan(vh/2);
    vMax = tan(vv/2);
    du = 2*uMax/(resU - 1);
    dv = 2*vMax/(resV - 1);
    [us vs] = meshgrid(-uMax:du:uMax, vMax:-dv:-vMax);
    
    viewRays = ...
      bsxfun(@plus, viewDir, ...
        bsxfun(@times, shiftdim(us, -1), viewRight) + ...
        bsxfun(@times, shiftdim(vs, -1), viewUp));
    varargout{1} = bsxfun(@rdivide, viewRays, sqrt(sum(viewRays.^2)));

    if nargout > 1
      varargout{2} = du;
    end

    if nargout > 2
      varargout{3} = dv;
    end
    
    if nargout > 3
      rotation = [viewRight viewDir viewUp];
      normFactor = sqrt(us.^2 + vs.^2 + 1);
      normFactor3 = normFactor.^3;
      covuv = rotation*[mxarray(-us.^2./normFactor3 + 1./normFactor);
                        mxarray(us./normFactor3);
                        mxarray(-us.*vs./normFactor3)];
      varargout{4} = squeeze(double(covuv));
    
      if nargout > 4
        covv = rotation*[mxarray(-us.*vs./normFactor3);
                         mxarray(vs./normFactor3);
                         mxarray(-vs.^2./normFactor3 + 1./normFactor)];
        varargout{5} = squeeze(double(covv));
      end
    end
  case {'parallel', 'l'}
    varargout{1} = repmat(viewDir(:), [1 resV resU]);
    varargout{2} = 1/resU;
    varargout{3} = 1/resV;
    varargout{4} = 0;
    varargout{5} = 0;
end