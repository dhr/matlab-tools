function cmap = makeEquiluminantColormap(init, sat, n, b1dir, wts, gammas, ecc)

if isscalar(init)
  init = repmat(init, 1, 3);
end

if ~exist('b1dir', 'var')
  b1dir = 0;
end

if ~exist('wts', 'var') || isempty(wts)
  wts = [.2126 .7152 .0722];
end

if ~exist('gammas', 'var')
  gammas = 2.2;
end

if ~exist('ecc', 'var')
  ecc = 0;
end

wts = wts/norm(wts);
if isscalar(b1dir)
  basis = null(wts);
  cct = cos(b1dir); sct = sin(b1dir);
  basis1 = cct*basis(:,1) - sct*basis(:,2);
  basis2 = sct*basis(:,1) + cct*basis(:,2);
else
  basis1 = b1dir - dot(wts, b1dir)*wts;
  basis1 = basis1(:)/norm(basis1);
  basis2 = cross(wts(:), basis1(:));
  basis2 = basis2/norm(basis2);
end

if ecc >= 0
  b2scl = sqrt(1 - ecc);
  angles = linspace(0, 2*pi, n)' + pi/2;
  cmap = bsxfun(@times, cos(angles), basis1') + ...
         bsxfun(@times, b2scl*sin(angles), basis2');
else
  cmap = bsxfun(@times, linspace(-1, 1)', basis1');
end

room = 1 - init;
maxes = max(abs(cmap));
scl = min(min(room./maxes), min(init./maxes));
cmap = bsxfun(@plus, scl*sat*cmap, init);
if min(cmap(:)) < 0 || max(cmap(:)) > 1
  error('Colormap values out of range (%f %f)', min(cmap(:)), max(cmap(:)));
end
cmap = bsxfun(@power, cmap, 1./gammas);
