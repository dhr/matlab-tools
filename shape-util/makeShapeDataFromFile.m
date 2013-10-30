function shapeData = makeShapeDataFromFile(filename, eulerRot)

if ischar(filename)
  filename = {filename};
elseif ~iscell(filename)
  error('Improper filename argument; neither cell or char array.');
end

for i = 1:length(filename)
  [vs, tris] = loadObj(filename{i});
  rvs = rotateMesh(vs, eulerRot{i}*pi/180);
  meshInfo(i) = struct('vs', rvs, 'tris', tris, 'ns', normalsFromMesh(rvs, tris)); %#ok<*AGROW>
end
shapeData = makeShapeData(meshInfo, [1 0 0 0], makeViewParams('ImDims', 750), 'CalcForeshortening', false);
