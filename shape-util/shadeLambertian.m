function shaded = shadeLambertian(normals, lightDirection, normalize, hemisphere)

if ~exist('normalize', 'var')
  normalize = true;
end

if ~exist('hemisphere', 'var')
  hemisphere = false;
end

if normalize
  lightDirection = lightDirection/norm(lightDirection);
end

dim = find(size(normals) == 3, 1);
lightDirection = shiftdim(lightDirection(:), 1 - dim);
shaded = -shiftdim(sum(bsxfun(@times, normals, lightDirection), dim));

if ~hemisphere
  shaded(shaded < 0) = 0;
else
  shaded = (shaded + 1) / 2;
end
