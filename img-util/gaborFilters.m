function [Fs, p] = gaborFilters(varargin)

if length(varargin) >= 1 && isstruct(varargin{1})
  p = varargin{1};
else
  paramNames = {'norientations', 'nscales', 'nphases', 'dilation', ...
    'wavelength', 'sigma', 'aspect', 'sampling', 'thetaoff'};
  parsearglist(paramNames, varargin);
  argdefaults('norientations', 8, 'nscales', 4, 'nphases', 2, ...
    'dilation', sqrt(2), 'wavelength', 4, 'aspect', 1.5, ...
    'sampling', 0.8, 'thetaoff', 0);
  
  p.norientations = norientations;
  p.nscales = nscales;
  p.nphases = nphases;
  p.dilation = dilation;
  p.wavelength = wavelength;
  p.aspect = aspect;
  p.sampling = sampling;
  
  if ~exist('sigma', 'var')
    p.sigma = p.wavelength/4;
  else
    p.sigma = sigma;
  end
  
  cellfun(@clear, paramNames);
end

Fs = cell(p.norientations, p.nscales, p.nphases);
for j = 1:p.nscales
  s = p.dilation^(j - 1);
  
  for i = 1:p.norientations
    theta = (i - 1)/p.norientations*pi;
    
    for k = 1:p.nphases
      phase = (k - 1)/p.nphases*pi/2;
      gabor = makeGabor(theta, s*p.wavelength, phase, s*p.sigma, p.aspect);
      Fs{i,j,k} = gabor;
    end
  end
end
