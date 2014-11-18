function [vs, ks] = principalDirectionsFromNormals(normals, sigma, sort)
%PRINCIPALCURVATURESFROMNORMALS Calculate principle curvatures.
%   [V1,V2,K1,K2] = PRINCIPALCURVATURESFROMNORMALS(N,S)

if nargin == 1
  sigma = 1;
end

if ~exist('sort', 'var')
  sort = true;
end

fx = -normals(:,:,1)./normals(:,:,3);
fy = -normals(:,:,2)./normals(:,:,3);
fx(~isfinite(fx)) = 0;
fy(~isfinite(fy)) = 0;
[fxx, fxy] = gaussianDiff(fx, sigma);
[fyx, fyy] = gaussianDiff(fy, sigma);

g11 = 1 + fx.^2;
g12 = fx.*fy;
g22 = 1 + fy.^2;

b11 = normals(:,:,3).*fxx;
b12 = normals(:,:,3).*fxy;
b22 = normals(:,:,3).*fyy;

I = mxarray(permute(cat(4, cat(3, g11, g12), cat(3, g12, g22)), [3 4 1 2]));
II = mxarray(permute(cat(4, cat(3, b11, b12), cat(3, b12, b22)), [3 4 1 2]));

[v, d] = eig(inv(I)*II);
vs = permute(double(v), [3 4 1 2]);
ks = -permute(double(d), [3 4 1 2]); % Choose signs to be positive at hills

if sort
  k1 = ks(:,:,1);
  k2 = ks(:,:,2);
  swap = abs(k1) < abs(k2);
  tmp = k1;
  k1(swap) = k2(swap);
  k2(swap) = tmp(swap);
  v11 = vs(:,:,1,1);
  v12 = vs(:,:,2,1);
  v21 = vs(:,:,1,2);
  v22 = vs(:,:,2,2);
  tmp1 = v11;
  tmp2 = v21;
  v11(swap) = v12(swap);
  v21(swap) = v22(swap);
  v12(swap) = tmp1(swap);
  v22(swap) = tmp2(swap);
  vs = cat(4, cat(3, v11, v21), cat(3, v12, v22));
  ks = cat(3, k1, k2);
end
