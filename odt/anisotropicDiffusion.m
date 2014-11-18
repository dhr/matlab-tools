%ANISOTROPICDIFFUSION Perform anisotropic diffusion on a texture.
%   IM = ANISOTROPICDIFFUSION(TEX, THETAS, AMTS, ITERS, DT) performs
%   anisotropic diffusion on the texture TEX using directions THETAS,
%   amounts of diffusion AMTS, for ITERS iterations with "time" steps DT.
%
%   TEX should be a 2-D double matrix, with each element specifying an
%   intensity value.
%
%   THETAS should be a 2-D double matrix, with each element specifying a
%   direction of diffusion in radians.  TEX and THETAS should be the same
%   size.
%
%   AMTS should be a 2-D double matrix, with each element specifying the
%   amount of anisotropy of the diffusion occuring at the corresponding
%   location in TEX.  The default if not specified is 1 (perfectly
%   anisotropic diffusion).  A value of 0 is perfectly isotropic diffusion.
%
%   ITERS should be an integer scalar, specifying the number of iterations
%   of diffusion to perform.  The default if not specified is 20.
%
%   DT should be a double scalar, specifying the "time" interval between
%   successive updates of the diffusion.  The default if not specified is
%   0.1.
%
%   IM is the resulting diffused image.
%
%   See also LIC.