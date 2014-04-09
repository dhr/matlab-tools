function [dzDx, dzDy] = gaussianDiff(z, sigma, dxs, dys)
%GAUSSIANDIFF Calculate derivatives using Gaussians.
%   [DZDX, DZDY] = GAUSSIANDIFF(Z, SIGMA, DX) computes the regularized
%   partial derivatives (DZDX and DZDY) of an image Z using a gaussian
%   with standard deviation SIGMA, assuming pixel spacing DX.

if nargin < 2
  sigma = 1;
end

if nargin < 3
  dxs = 1;
  dys = 1;
end

if nargin < 4
  dys = dxs;
end

if sigma == 0
  sigma = eps;
end

gaussian = fspecial('gaussian', [1, 6*ceil(sigma) + 1], sigma);
gaussian = gaussian(gaussian ~= 0);
dgD = conv([-1 0 1]/2, gaussian);
dzDx = imfilter(z, dgD, 'replicate')./dxs;
dzDy = imfilter(z, rot90(dgD), 'replicate')./dys;
