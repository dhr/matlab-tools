function [unmixing, mixing] = fastica(data, varargin)
%FASTICA Implements FastICA algorithm for finding independent components.
%   A = FASTICA(DATA) performs independent component analysis on the data
%   in DATA. DATA is assumed to be a matrix whose columns contain samples
%   from a multivariate dataset formed via mixing of non-gaussian
%   "independent components" by the matrix A, i.e.:
%
%     DATA = A*S
%
%   where S is a matrix representing the relative activities of the
%   different components. The matrix A is estimated and returned.

tol = 1e-9;
svalcutoff = 1e-8;
dimreduce = -1;
maxits = 1000;
numics = -1;
gfunc = 'tanh';

parsearglist({'tol', 'svalcutoff', 'numics', 'gfunc', 'maxits', ...
              'dimreduce'}, varargin);

switch lower(gfunc)
  case 'pow3'
    update = @pow3update;
  case 'tanh'
    update = @tanhupdate;
  case 'gauss'
    update = @gaussupdate;
end

% Step 1: De-mean the columns
data = bsxfun(@minus, data, mean(data, 2));
nsamples = size(data, 2);

% Step 2: Whiten the data/reduce dimensionality
[u, s, v] = svd(data, 'econ');
besselcorrection = sqrt(nsamples - 1);
ds = diag(s);
if dimreduce > 0
  if dimreduce > size(data, 1)
    dimreduce = size(data, 1);
  end
  svalcutoff = ds(dimreduce);
end
selected = ds >= svalcutoff;
if ~any(selected)
  error('Singular value cutoff too high (dimensionality reduced to 0).');
end
ds = ds(selected);
s = diag(ds);
invs = diag(1./ds);
u = u(:,selected);
v = v(:,selected);
whitening = besselcorrection*invs*u';
unwhitening = 1/besselcorrection*u*s;
whitened = besselcorrection*v';

dim = size(whitened, 1);
if numics <= 0 || numics > dim
  numics = dim;
end

% Step 3: Find independent components
W = zeros(numics, size(whitened, 1));
proj = 0;
for i = 1:numics
  w = randn(1, size(whitened, 1));
  lastw = 0*w;
  w = w./norm(w);
  it = 0;
  while abs(w*lastw') < 1 - tol && it < maxits
    lastw = w;
    wplus = update(w, whitened);
    wplus = wplus - wplus*proj;
    w = wplus./norm(wplus);
    it = it + 1;
  end
  proj = proj + w'*w;
  W(i,:) = w;
  fprintf('Recovered IC%d (%d iterations)\n', i, it);
end

% Step 4: Recover mixing/unmixing matrices
unmixing = W*whitening;
mixing = unwhitening*W';

function wplus = pow3update(w, X)
  wplus = (w*X).^3*X'/size(X, 2) - 3*w;
end

function wplus = tanhupdate(w, X)
  temp = tanh(w*X);
  wplus = temp*X' - sum(1 - temp.^2)*w;
end

function wplus = gaussupdate(w, X)
  wX = w*X;
  wX2 = wX.^2;
  temp = exp(-wX2/2);
  wplus = (wX.*temp)*X' - sum(temp.*(1 - wX2))*w;
end

end
