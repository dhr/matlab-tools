function [dx, dy] = calcDxDyStepSizes(depths, normals, mask)

fx = -normals(:,:,1)./normals(:,:,3);
fy = -normals(:,:,2)./normals(:,:,3);

emask = imerode(mask, strel('disk', 20, 0));

[estfx, estfy] = gaussianDiff(-depths, 0);
dxs = estfx./fx;
dys = estfy./fy;
dx = median(dxs(emask));
dy = median(dys(emask));
