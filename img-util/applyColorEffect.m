function img = applyColorEffect(lum, cvals, cmap)

if ~exist('cmap', 'var')
  cmap = 0.5;
end

if isscalar(cmap)
  cmap = makeEquiluminantColormap(cmap, 1, 128, 0);
  cmap = repmat(cmap, 4, 1);
end

img = bsxfun(@times, lum, applyColormap(cvals, cmap));
