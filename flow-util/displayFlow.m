function displayFlow(directions, mags, sample, mask, maxlen, color)
%DISPLAYFLOW Display a flow.
%   DISPLAYFLOW(DIRS, AMTS, SAMPLE, MASK, MAXLEN) displays
%   the flow given by directions DIRS as a field of non-oriented vectors,
%   sampled every SAMPLE elements, optionally (SCALELENS) scaled by amounts
%   AMTS, with maximum length MAXLEN, and also optionally (PLOTAMTS) with
%   amounts plotted in the background.
%
%   DIRS should be an m x n matrix of angles in radians.
%
%   MAGS should be an m x n matrix of scalar values.  If not specified, it
%   defaults to a matrix of ones.
%
%   SAMPLE should be an integer indicating the sample spacing - e.g., a
%   value of 1 means use every value, a value of 5 means use only every 5th
%   value.  Defaults to 1.
%
%   MASK should be a logical mask indicating which directions should be
%   plotted.  Can be used in conjunction with the SAMPLE parameter.  The
%   default is true(size(DIRS)).
%
%   MAXLEN specifies the maximum length of a vector element for display. If
%   a value of NaN is given then no rescaling of the MAGS matrix takes
%   place (i.e., MAGS should represent absolute vector lengths in pixels).
%   It defaults to 0.8*SAMPLE.
%
%   COLOR is the color of the drawn vectors.  This can be either a 1 x 3
%   vector of RGB values, or a color name understood by the LINE function.
%   Defaults to 'red'.
%
%   See also PERCEIVEDTEXTUREFLOW.

nrows = size(directions, 1);
ncols = size(directions, 2);

if nargin < 2
  mags = ones(size(directions));
end

if nargin < 3
  sample = 1;
end

if nargin < 4
  mask = true(size(directions));
end

if nargin < 5
  maxlen = 0.8*sample;
end

if nargin < 6
  color = 'red';
end

if isscalar(mags)
  mags = repmat(mags, nrows, ncols);
end

if ~isnan(maxlen)
  mags = mags./max(mags(:))*maxlen;
end

[xs, ys] = meshgrid(1:ncols, 1:nrows);

sampling = ~mod(xs - 1, sample) & ~mod(ys - 1, sample) & mask;

newplot;

xlim([0 ncols + 1]);
ylim([0 nrows + 1]);

axis image;
axis ij;
axis off;

line([xs(sampling) - cos(directions(sampling)).*mags(sampling)/2 ...
      xs(sampling) + cos(directions(sampling)).*mags(sampling)/2]', ...
     [ys(sampling) + sin(directions(sampling)).*mags(sampling)/2 ...
      ys(sampling) - sin(directions(sampling)).*mags(sampling)/2]', ...
     'Color', color, 'LineWidth', 1);
