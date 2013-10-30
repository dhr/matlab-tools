function [v1, v2, k1, k2] = principalCurvaturesFromNormals(normals, sigma)
%PRINCIPALCURVATURESFROMNORMALS Calculate principle curvatures.
%   [V1,V2,K1,K2] = PRINCIPALCURVATURESFROMNORMALS(N,S)

if nargin == 1
  sigma = 1;
end

nrows = size(normals, 1);
ncols = size(normals, 2);

[fx, fy] = surfacePartialsFromNormals(normals);
[fxx, fxy] = gaussianDiff(fx, sigma);
[fyx, fyy] = gaussianDiff(fy, sigma);

g11 = 1 + fx.^2;
g12 = fx.*fy;
g22 = 1 + fy.^2;

b11 = normals(:,:,3).*fxx;
b12 = normals(:,:,3).*fxy;
b22 = normals(:,:,3).*fyy;

v1 = zeros(nrows, ncols, 3);
v2 = zeros(nrows, ncols, 3);
k1 = zeros(nrows, ncols);
k2 = zeros(nrows, ncols);

for i = 1:nrows;
  for j = 1:ncols;
    G = [g11(i,j) g12(i,j); g12(i,j) g22(i,j)];
    B = [b11(i,j) b12(i,j); b12(i,j) b22(i,j)];

    BinvG = inv(G)*B;

    [d, vaps] = eig(BinvG);
    vaps = diag(vaps);

    d0 = d(:,1);
    d1 = d(:,2);

    if abs(vaps(1)) > abs(vaps(2))
      v1(i,j,:) = [d1(1) d1(2) d1(1)*fx(i,j) + d1(2)*fy(i,j)];
      v2(i,j,:) = [d0(1) d0(2) d0(1)*fx(i,j) + d0(2)*fy(i,j)];

      k1(i,j) = vaps(2);
      k2(i,j) = vaps(1);
    else
      v1(i,j,:) = [d0(1) d0(2) d0(1)*fx(i,j) + d0(2)*fy(i,j)];
      v2(i,j,:) = [d1(1) d1(2) d1(1)*fx(i,j) + d1(2)*fy(i,j)];

      k1(i,j) = vaps(1);
      k2(i,j) = vaps(2);
    end
  end
end

