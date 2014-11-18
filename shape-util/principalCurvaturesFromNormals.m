function [k1, k2] = principalCurvaturesFromNormals(normals, sigma, dx, dy)
%PRINCIPALCURVATURESFROMNORMALS Calculate principle curvatures.
%   [K1, K2] = PRINCIPALCURVATURESFROMNORMALS(N,S) calculates the principal
%   curvatures K1 and K2 given normals N. When taking derivatives, it blurs
%   using a Gaussian filter with standard deviation S. K1 is the first
%   principal curvature value, K2 is the second (abs(K1) > abs(K2)).
%
%   The spacing between pixels can be supplied via DX and DY, to be used
%   when calculating derivatives. These parameters are optional.

if ~exist('sigma', 'var')
  sigma = 1;
end

if ~exist('dx', 'var')
  dx = 1;
end

if ~exist('dy', 'var')
  dy = dx;
end

fx = -normals(:,:,1)./normals(:,:,3);
fy = -normals(:,:,2)./normals(:,:,3);
fx(~isfinite(fx)) = 0;
fy(~isfinite(fy)) = 0;
[fxx, fxy] = gaussianDiff(fx, sigma, dx, dy);
[fyx, fyy] = gaussianDiff(fy, sigma, dx, dy);

K = (fxx.*fyy - fxy.^2).*normals(:,:,3).^4;
H = 0.5*((1 + fy.^2).*fxx - 2*fx.*fy.*fxy + (1 + fx.^2).*fyy).* ...
    normals(:,:,3).^3;

H(~isfinite(H)) = 0;

% Choose signs to be positive for bumps/hills
k1 = -(H + sqrt(H.^2 - K));
k2 = -(H - sqrt(H.^2 - K));

swaplocs = abs(k1) < abs(k2);
tmp = k1;
k1(swaplocs) = k2(swaplocs);
k2(swaplocs) = tmp(swaplocs);
