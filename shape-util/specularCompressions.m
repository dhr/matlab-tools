function [mindirs, minspds, maxspds] = ...
  specularCompressions(normals, sigma, rays, dus, dvs, covuvs, covvvs, mask)

nrows = size(normals, 2);
ncols = size(normals, 3);

normals = mxarray(normals);
rays = mxarray(rays);
dus = mxarray(dus);
dvs = mxarray(dvs);
covuvs = mxarray(covuvs);
covvvs = mxarray(covvvs);

[dnxdu, dnxdv] = gaussianDiff(double(squeeze(normals(1,:,:,:))), sigma, dus, dvs);
[dnydu, dnydv] = gaussianDiff(double(squeeze(normals(2,:,:,:))), sigma, dus, dvs);
[dnzdu, dnzdv] = gaussianDiff(double(squeeze(normals(3,:,:,:))), sigma, dus, dvs);
covuns = mxarray(cat(1, dnxdu, dnydu, dnzdu));
covvns = mxarray(cat(1, dnxdv, dnydv, dnzdv));

dvdp = [covuvs covvvs];
dndp = [covuns covvns];

j = dvdp - 2*dot(normals, rays)*dndp - 2*(normals*normals.')*dvdp - 2*normals*rays.'*dndp;
g = j.'*j;

[v, d] = eig(g);
[d, indxs] = sort(abs(d));
indxBases = repmat(reshape(0:4:4*(nrows*ncols - 1), [1 1 nrows ncols]), [2 2 1 1]);
indxs = 2*mxarray(indxs).' - 1;
v = v([indxs; indxs + 1] + indxBases);
d = sqrt(d);

mindirs = cmod(squeeze(atan2(v(2,1,:,:), v(1,1,:,:))), pi); mindirs(~mask) = 0;
minspds = double(squeeze(d(1,1,:,:))); minspds(~mask) = 1;
maxspds = double(squeeze(d(2,1,:,:))); minspds(~mask) = 1;
