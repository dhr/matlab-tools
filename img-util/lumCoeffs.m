function out = lumCoeffs(inds)

coeffs = [.2126 .7152 .0722];

if ~exist('inds', 'var')
  inds = [1 2 3];
end

out = coeffs(inds);
