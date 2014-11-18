function K = gaussianCurvatureFromNormals(normals, sigma)

if nargin == 1
  sigma = 1;
end

fx = -normals(:,:,1)./normals(:,:,3);
fy = -normals(:,:,2)./normals(:,:,3);
fx(~isfinite(fx)) = 0;
fy(~isfinite(fy)) = 0;
[fxx, fxy] = gaussianDiff(fx, sigma);
[fyx, fyy] = gaussianDiff(fy, sigma);

K = (fxx.*fyy - fxy.^2).*normals(:,:,3).^4;
