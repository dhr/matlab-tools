function genDeformations(file, nDeformations, vs, tris, sigma, amp, view, transforms)
%GENDEFORMATIONS Generates a given number of deformations of a shape.
%   GENDEFORMATIONS(FILE, N, VS, TRIS, SIGMA, AMP, PROJ, VP, VD, VU, H, V,
%   DEFRES, TRANSFORMS) generates N deformations of the object defined by
%   vertices VS and faces TRIS, saving them as sequentially numbered files
%   with the same base name as FILE.  If file ends in 'blob.obj', the
%   sequentially numbered files will be formatted 'blob-1.obj',
%   'blob-2.obj', etc.  If VS and TRIS are both the empty matrix, then they
%   are read from FILE.
%
%   FILE should be the name of an OBJ file, that is used as a base-name for
%   saving deformations and potentially read from if VS and TRIS are both
%   empty.
%
%   N should be the number of deformations to create.  Defaults to 10.
%
%   VS should be an m x 3 matrix of vertices, or the empty matrix if it
%   should be read from FILE.  Defaults to the empty matrix.
%
%   TRIS should be an n x 3 matrix of indexes into VS, defining triangles,
%   or the empty matrix if it should be read from file.  Defaults to the
%   empty matrix.
%
%   SIGMA is a parameter controlling the spatial frequency of the
%   deformations.  Defaults to 50.  If each deformed version of the input
%   object should consist of multiple deformations (successively applied),
%   an array of values can be passed (with length equal to the desired
%   number of deformations).
%
%   AMP controls the amplitude of the deformations.  For example, a value
%   of 1 means no vertex will be moved more than 1 unit from its inital
%   position.  Defaults to 0.7.  It can also be an array corresponding to
%   the VS array, in which case the amplitude is applied on a per-vertex
%   basis.  To control each deformation when performing multiple
%   successively applied deformations, AMP should have multiple columns
%   corresponding to each deformation.
%
%   VIEW should be a view parameter structure as returned by
%   MAKEVIEWPARAMS.
%
%   DEFRES is the resolution of the image used to perform deformation.
%   This should be a scalar, and defaults to 2048.
%
%   TRANSFORMS should be a 1 or N x 4 array of quaternions, with each row a
%   quaternion.  The quaternions are used to rotate the generated object
%   before saving it.  If only one quaternion is given, then it is used for
%   all deformations.  If N are given, the ith quaternion is used for the
%   ith deformation (since there are N deformed objects).
%
%   See also MESHDEFORM.

nTimesToDeform = 1;

if file(1) == '~'
  file = [getenv('HOME') file(2:end)];
end

if nargin < 2
  nDeformations = 10;
elseif nDeformations < 1
  error('nDeformations must be greater than or equal to 1.');
else
  nDeformations = round(nDeformations);
end

if nargin < 3 || nargin < 4 || isempty(vs) || isempty(tris)
  [vs, tris] = readObj(file);
end

if nargin < 5
  sigma = 50;
elseif length(sigma) > 1
  nTimesToDeform = length(sigma);
end

if ~exist('amp', 'var')
  amp = 0.7;
else  
  nCols = size(amp, 2);
  
  if nCols ~= 1
    if nTimesToDeform > 1 && nCols ~= nTimesToDeform
      error(['The number of rows in the ''amp'' argument must either' ...
             'be 1 or match the number of seperate deformations' ...
             'specified by other parameters.']);
    else
      nTimesToDeform = nCols;
    end
  end
end

if ~exist('view', 'var')
  view = makeViewParams;
elseif length(view) > 1 && length(view) ~= nDeformations
  error(['The number of view parameter structures should either be 1 ' ...
         'or match the number of deformations specified by the N' ...
         'parameter.']);
end

if ~exist('transforms', 'var')
  transforms = [1 0 0 0];
else
  if numel(transforms) == 4
    transforms = transforms(:)';
  end
  
  nRows = size(transforms, 1);
  
  if nRows ~= 1 && nRows ~= nDeformations
    error(['The length of the ''transforms'' argument must either ' ...
           'be 1 or match the number of deformations specified by the ' ...
           'N parameter.']);
  end
end

if ~isempty(regexpi(file, '\.obj$'))
  file = file(1:end - 4);
end

xbnd = (view.w - 1)/2;
ybnd = (view.h - 1)/2;
[xs, ys] = meshgrid(linspace(-xbnd, xbnd, view.w), ...
                    linspace(-ybnd, ybnd, view.h));

formatStr = [file '-%0' num2str(floor(log10(nDeformations)) + 1) 'd.obj'];

for i = 1:nDeformations
  deformedVs = vs;
  for j = 1:nTimesToDeform
    s = sigma(min(j, length(sigma)));
    gaussian = exp(-(xs.^2 + ys.^2)/(2*s^2));
    blurredNoise = ifft2(fft2(gaussian).*fft2(rand(view.h, view.w)));
    lfwaves = normalizeImage(blurredNoise)*2 - 1;
    deformedVs = meshDeform(deformedVs, lfwaves, ...
                            amp(:,min(j, size(amp, 2))), ...
                            view(min(j, length(view))));
  end
  xform = quat2dcm(transforms(min(j, size(transforms, 1)),:));
  deformedVs = deformedVs*xform';
  ns = normalsFromMesh(deformedVs, tris);
  saveObj(sprintf(formatStr, i), deformedVs, tris, ns);
end