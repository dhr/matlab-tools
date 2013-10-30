function viewParams = makeViewParams(varargin)
%MAKEVIEWPARAMS Creates view parameters used by ODT generation procedures.
%   PARAMS = MAKEVIEWPARAMS(...) creates a struct PARAMS containing view
%   parameters in a format used by ODT generation procedures.
%
%   Inputs are property/value pairs of the form
%
%     MAKEVIEWPARAMS('property1', value1, 'property2', value2, ...)
%
%   Valid properties are:
%
%     'ViewPoint': Specifies the view point. Value should be a three
%       element matrix with the [x y z] components of the view point.
%       Defaults to [0 -7 0].
%
%     'ViewDir': Specifies the view direction. Defaults to [0 1 0].
%
%     'ViewUp': The up direction. Defaults to [0 0 1].
%
%     'Projection': The projection type. Valid values are 'v' for
%       perspective and 'l' for orthographic. Defaults to 'v'.
%
%     'ViewAngle': The horizontal viewing angle in degrees. Defaults to
%     20.5.
%
%     'ImDims': The size of the viewing plane in pixels, in the format
%       [width height]. If a scalar is passed it is used as both the width
%       and the height. Defaults to [750 750].
%
%     'ImSize': The size of the viewing plane in pixels, in the format
%       [height width].
%
%   See also MAKESHAPEDATA.

parsearglist({'viewPoint', 'viewDir', 'viewUp', 'projection', ...
              'viewAngle', 'imDims', 'imSize'}, varargin);
argdefaults('viewPoint', [0 -7 0], 'viewDir', [0 1 0], 'viewUp', [0 0 1], ...
            'projection', 'v', 'viewAngle', 20.5, 'imDims', [750 750]);

if exist('imSize', 'var')
  imDims = imSize(end:-1:1); %#ok<COLND>
end

if isscalar(imDims)
  imDims = [imDims imDims];
end

viewParams = struct('vp', viewPoint, 'vd', viewDir, 'vu', viewUp, ...
                    'proj', projection, 'va', viewAngle, ...
                    'w', imDims(1), 'h', imDims(2));