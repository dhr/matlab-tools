function [fx fy] = normalsToGradients(normals)

normals([1 3],:,:) = mxarray(normals([1 3],:,:))./mxarray(normals(2,:,:));
normals(isnan(normals)) = 0;
fx = squeeze(double(normals(1,:,:)));
fy = squeeze(double(normals(3,:,:)));