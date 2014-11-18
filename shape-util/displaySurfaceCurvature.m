function displaySurfaceCurvature(v1, v2, resample)

[x,y] = meshgrid(1:ncols, 1:nrows);

if nargin < 3
  resample = 5;
end

v1s = v1(resample:resample:end - resample + 1,resample:resample:end - resample + 1,:);
v2s = v2(resample:resample:end - resample + 1,resample:resample:end - resample + 1,:);
xs = x(resample:resample:end - resample + 1,resample:resample:end - resample + 1,:);
ys = y(resample:resample:end - resample + 1,resample:resample:end - resample + 1,:);

figure;
subplot(121);
colormap(gray(256));
hold on;
quiver(xs, ys, v1s(:,:,1), v1s(:,:,2), 0, 'r');
quiver(xs, ys, -v1s(:,:,1), -v1s(:,:,2), 0, 'r');
quiver(xs, ys, v2s(:,:,1), v2s(:,:,2), 0);
quiver(xs, ys, -v2s(:,:,1), -v2s(:,:,2), 0);
axis('equal');
axis('tight');

[startx, starty] = meshgrid(10:20:ncols - 10, 10:20:nrows - 10);
U = v2(:,:,1);
V = v2(:,:,2);

subplot(122);
streamline(x, y, U, V, startx, starty);
axis('equal');
axis('tight');