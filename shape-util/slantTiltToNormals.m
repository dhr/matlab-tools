function normals = slantTiltToNormals(slant, tilt, viewDir, viewUp)

if nargin < 3
  viewDir = [0 1 0];
  viewUp = [0 0 1];
end

if size(viewDir, 2) ~= 1
  viewDir = viewDir';
end

if size(viewUp, 2) ~= 1
  viewUp = viewUp';
end

viewDir = viewDir./norm(viewDir);

if sum(viewDir.*viewUp) ~= 0
  viewUp = viewUp - sum(viewUp.*viewDir).*viewDir;
end

viewUp = viewUp./norm(viewUp);
viewRight = cross(viewDir, viewUp);

nRows = size(slant, 1);
nCols = size(slant, 2);

viewDirs = repmat(viewDir, [1 nRows nCols]);
viewUps = repmat(viewUp, [1 nRows nCols]);
viewRights = repmat(viewRight, [1 nRows nCols]);

initNormals = zeros(3, nRows, nCols);
initNormals(1,:,:) = cos(tilt).*sin(slant);
initNormals(2,:,:) = -cos(slant);
initNormals(3,:,:) = sin(tilt).*sin(slant);

normals = initNormals;
normals(1,:,:) = sum(initNormals.*viewRights);
normals(2,:,:) = sum(initNormals.*viewDirs);
normals(3,:,:) = sum(initNormals.*viewUps);

nonFinites = ~isfinite(tilt) | ~isfinite(slant);
normals(repmat(nonFinites, [3 1 1])) = 0;