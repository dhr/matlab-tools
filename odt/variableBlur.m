%VARIABLEBLUR Blur an image a different amount at each pixel.
%   BLURRED = VARIABLEBLUR(IM, SIGMAS) blurs the image IM using a
%   different sized gaussian filter at each pixel, where the sizes are
%   specified by SIGMAS as the standard deviations of the gaussian.
%
%   IM should be a 2-D double matrix, with each element specifying an
%   intensity value.
%
%   SIGMAS should be a 2-D double matrix or a scalar, with each element
%   specifying a standard deviation (sigma) value.  SIGMAS should be the
%   same size as IM if it is not a scalar.
%
%   BLURRED is the blurred output image.  Pixel (i,j) of BLURRED has the
%   same intensity value as the IM(i,j) would have if IM were blurred by a
%   gaussian having standard deviation SIGMAS(i,j).