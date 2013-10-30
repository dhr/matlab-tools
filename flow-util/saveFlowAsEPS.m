function saveFlowAsEPS(filename, directions, mags, sample, mask, maxlen, color, stroke)

nrows = size(directions, 1);
ncols = size(directions, 2);

if nargin < 3
  mags = ones(size(directions));
end

if nargin < 4
  sample = 1;
end

if nargin < 5
  mask = true(size(directions));
end

if nargin < 6
  maxlen = 0.8*sample;
end

if nargin < 7
  color = [0 0 0];
end

if nargin < 8
  stroke = 0.1;
end

if numel(mags) == 1
  mags = repmat(mags, nrows, ncols);
end

if ~isnan(maxlen)
  mags = mags./max(mags(mask))*maxlen;
end

[xs, ys] = meshgrid(1:ncols, nrows:-1:1);

sampling = ~mod(xs - 1, sample) & ~mod(ys - 1, sample) & mask;

if isempty(regexp(filename, '\.eps$', 'once'))
  filename = [filename '.eps'];
end
file = fopen(filename, 'w');

fprintf(file, '%%!PS-Adobe-3.0 EPSF-3.0\n');
fprintf(file, '%%%%BoundingBox: 1 1 %i %i\n', ncols + 1, nrows + 1);
fprintf(file, sprintf('%f setlinewidth\n', stroke));
fprintf(file, '1 setlinecap\n');
fprintf(file, '%f %f %f setrgbcolor\n', color(1), color(2), color(3));

linefmtstring = '%f %f moveto %f %f lineto stroke\n';

args = [xs(sampling) + 0.5 - cos(directions(sampling)).*mags(sampling)/2 ...
        ys(sampling) + 0.5 - sin(directions(sampling)).*mags(sampling)/2 ...
        xs(sampling) + 0.5 + cos(directions(sampling)).*mags(sampling)/2 ...
        ys(sampling) + 0.5 + sin(directions(sampling)).*mags(sampling)/2];

nlines = size(args, 1);

for i = 1:nlines
  fprintf(file, linefmtstring, args(i,1), args(i,2), args(i,3), args(i,4));
end

fprintf(file, 'showpage\n');

fclose(file);
