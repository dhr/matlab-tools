function genODTTexImages(fileBase, ns, size, maxScale, anisoScale, odtAmt, vp, vd, vu, v)

if nargin < 2
  ns = [];
end

if nargin < 3
  size = 750;
end

if nargin < 4
  maxScale = 2;
end

if nargin < 5
  anisoScale = 5;
end

if nargin < 6
  odtAmt = 5;
end

if nargin < 7
  vp = [0 -3 0];
end

if nargin < 8
  vd = [0 1 0];
end

if nargin < 9
  vu = [0 0 1];
end

if nargin < 10
  v = 45;
end

useManualRender = false;

[path name] = fileparts(fileBase);
dirListing = dir(path);
dirListing = {dirListing.name};
matches = cellfun('isempty', regexp(dirListing, [name '-\d+\.obj']));
matchIndices = find(~matches);

if isempty(matchIndices)
  error(['Could not find any files derived from ' name ' containing objects.']);
end

if useManualRender
  viewOptsStr = sprintf('-vp %f %f %f -vd %f %f %f -vu %f %f %f', [vp vd vu]);
else
  InitializeMatlabOpenGL;
  window = Screen('OpenWindow', max(Screen('Screens')), [0 0 0], [0 0 size size]);
end

for i = matchIndices
  number = regexp(dirListing{i}, '-(\d+)\.obj$', 'tokens');
  number = number{1}{1};
  
  if ~isempty(ns) && (isempty(number) || all(str2double(number) ~= ns))
    continue;
  end
  
  if useManualRender
    [intxs normals] = manualRender([path filesep dirListing{i}], viewOptsStr, 750, 'pn');
    depths = depthsFromIntxs(intxs, vp);
  else
    [verts tris] = readObj([path filesep dirListing{i}]);
    vnorms = normalsFromMesh(verts, tris);
    [normals depths] = getDenseMeshInfo(window, size, verts, tris, vnorms, 'v', vp, vd, vu, v);
    normals = permute(normals, [3 1 2]);
  end
  
  mask = squeeze(sum(normals.^2) ~= 0);
  [tmajdirs tmajlens tmindirs tminlens] = foreshorteningFromNormals(normals, 'v', vd, vu);
  tscales = tminlens;
  tanisos = 1 - tminlens./tmajlens;
  
  todt = makeODT([], tmajdirs, tscales, maxScale, tanisos*anisoScale, mask);
  todt = anisotropicDiffusion(todt, tmajdirs, tanisos, odtAmt);
  todt(~mask) = 0;
  imwrite(todt, [path filesep name '-' number '-tex-odt.png']);
  
  tmajdirs = tmajdirs + pi/2;
  todt = makeODT([], tmajdirs, tscales, maxScale, tanisos*anisoScale, mask);
  todt = anisotropicDiffusion(todt, tmajdirs, tanisos, odtAmt);
  todt(~mask) = 0;
  imwrite(todt, [path filesep name '-' number '-tex-odt-theta-offset.png']);
end

imwrite(mask, [path filesep name '-mask.png']);

if ~useManualRender
  Screen('Close', window);
end