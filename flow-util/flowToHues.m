function rgb = flowToHues(thetas, confs, directed)

if ~exist('directed', 'var')
  directed = false;
end

if ~exist('confs', 'var')
  confs = ones(size(thetas));
end

if isscalar(confs)
  confs = repmat(confs, size(thetas));
end

modamt = iif(directed, 2*pi, pi);

hues = mod(thetas, modamt)/modamt;
sats = confs;
vals = ones(size(confs));
rgb = hsv2rgb(cat(3, hues, sats, vals));
