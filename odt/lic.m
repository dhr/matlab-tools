%LIC Perform line integral convolution of a texture.
%   [LIC ENRGS] = LIC(TEX, THETAS, MAGS, D) performs line integral
%   convolution of the texture TEX, using the orientation field THETAS, and
%   optionally the magnitudes MAGS and directedness flag D.
%   
%   TEX should be a 2-D double matrix, with each element specifying an
%   intensity value.  If it is not of the same size as THETAS, it will be
%   treated as a "circular" texture (opposite edges will be stitched
%   together).
%   
%   THETAS should be a 2-D double matrix, with each element specifying a
%   direction in radians.
%   
%   MAGS should be either a 2-D double matrix of the same size as THETAS or
%   a scalar, specifying a "magnitude" determining the length of the
%   streamline over which integration is to be performed.  The default
%   value is 10.
%   
%   D is a flag specifying whether THETAS should be treated as being
%   "directed", i.e., whether theta and theta + pi should be treated as
%   different directions.  The default value is false (0).
%   
%   LIC is the resulting image.
%   
%   ENRGS give the energy of the "filter" used in the convolution for each
%   pixel, to be used in a call to SATURATELIC.
%
%   See also SATURATELIC, MULTISCALENOISE.
