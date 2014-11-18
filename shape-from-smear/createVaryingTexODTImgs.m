function stims = createVaryingTexODTImgs(shapeData, varargin)

unrecognized = parsearglist({'anisosScale', 'scalesScale', 'diffIters'}, varargin, false);

if ~exist('anisosScale', 'var') && ~exist('scalesScale', 'var')
  error('Specify a list of anisotropy scale values to use.');
end

nStims = length(anisosScale);
stims = repmat(struct('img', [], 'anisosScale', []), nStims, 1);
for i = 1:nStims
  params = {};
  if exist('anisosScale', 'var')
    params = [params{:} {'AnisosScale', anisosScale(i)}];
  end
  if exist('scalesScale', 'var')
    params = [params{:} {'ScalesScale', scalesScale(i)}];
  end
  if exist('diffIters', 'var')
    params = [params{:} {'DiffIters', diffIters(i)}];
  end
  stim = createTextureODTImg(shapeData, params{:}, unrecognized{:});
  stim.anisosScale = anisosScale(i);
  stims(i) = stim;
end