function gb = makeGabor(theta, wavelength, phase, sigma, aspect, ksize)
%MAKEGABOR Create a Gabor filter.
%   GB = MAKEGABOR(T, W, P, S, A, KSZ) creates a Gabor filter GB with
%   orientation T (in radians), wavelength W (in pixels), phase offset P
%   (in radians), envelope standard deviation S (in pixels), aspect ratio
%   A, and dimensions KSZ x KSZ. KSZ is an optional parameter, and if
%   omitted default dimensions (not necessarily square) will be selected.

xfreq2 = 0.5/(sigma)^2;
yfreq2 = 0.5/(sigma/aspect)^2;

st = sin(theta);
ct = cos(theta);

if ~exist('ksize', 'var')
  ksize = [floor(max(abs(8*sigma/aspect*ct), abs(8*sigma*st))) ...
           floor(max(abs(8*sigma*ct), abs(8*sigma/aspect*st)))];
elseif numel(ksize) == 1
  ksize = [ksize ksize];
end

xmax = floor(ksize(2)/2);
xmin = -xmax;
ymax = floor(ksize(1)/2);
ymin = -ymax;

[xs, ys] = meshgrid(xmin:xmax, ymax:-1:ymin);
 
xps = xs*ct + ys*st;
yps = -xs*st + ys*ct;
 
gb = exp(-.5*(xps.^2*xfreq2 + yps.^2*yfreq2));
if isreal(phase)
  gb = gb.*sin(2*pi/wavelength*yps + phase);
else
  gb = gb.*exp(2*pi*1i/wavelength*yps);
end

% possum = sum(gb(gb > 0));
% negsum = -sum(gb(gb < 0));
% 
% gb(gb < 0) = gb(gb < 0)*possum/negsum;
% gb = gb/possum;

gb = gb - mean(gb(:));
gb = gb/sqrt(abs(gb(:)'*gb(:)));
