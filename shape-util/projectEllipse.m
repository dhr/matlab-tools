function [majDirs majLens minDirs minLens] = ...
  projectEllipse(srcMajors, srcMinors, projDirs, targRights, targUps)
%PROJECTELLIPSE Parallel projection of ellipses onto a plane.
%   [MAJDIRS MAJLENS MINDIRS MINLENS] = 
%      PROJECTELLIPSE(SRCMAJ, SRCMIN, DIR, TARGRIGHT, TARGUP) projects
%   the ellipse defined by major axes SRCMAJ and minor axes SRCMIN along
%   the directions DIR onto the plane(s) defined by the vectors TARGRIGHT
%   and TARGUP, returning the directions and lengths of the major and
%   minor axes (MAJDIRS, MAJLENS, MINDIRS, and MINLENS) of the
%   projected ellipse, with respect to the target plane coordinate system
%   (TARGRIGHT and TARGUP).
%
%   All input arguments should be either 3 element vectors, or arrays of 3
%   element vectors (specifically, 3 x m x n matrices).
%
%   Output directions range from -pi/2 to pi/2, with 0 lying parallel to
%   TARGRIGHT.
%
%   See also FORESHORTENINGFROMNORMALS.

if numel(srcMajors) == 3
  srcMajors = mxarray(srcMajors(:));
else
  srcMajors = mxarray(srcMajors);
end

if numel(srcMinors) == 3
  srcMinors = mxarray(srcMinors(:));
else
  srcMinors = mxarray(srcMinors);
end

nrows = size(srcMajors, 3);
ncols = size(srcMajors, 4);

if numel(projDirs) == 3
  projDirs = mxarray(repmat(projDirs(:), [1 1 nrows ncols]));
else
  projDirs = mxarray(projDirs);
end

if numel(targRights) == 3
  targRights = mxarray(repmat(targRights(:), [1 1 nrows ncols]));
else
  targRights = mxarray(targRights);
end

if numel(targUps) == 3
  targUps = mxarray(repmat(targUps(:), [1 1 nrows ncols]));
else
  targUps = mxarray(targUps);
end

targNormals = cross(targUps, targRights);

jp = [targRights targUps];
je = [srcMajors srcMinors];
a = jp'*(eye(3) - projDirs*targNormals'./sum(projDirs.*targNormals))*je;
del2 = [1./sum(srcMajors.^2) mxarray(zeros(1, 1, nrows, ncols)); ...
        mxarray(zeros(1, 1, nrows, ncols)) 1./sum(srcMinors.^2)];
inva = inv(a);
m = inva'*del2*inva; %#ok<MINV>
mask = ~isfinite(m);
m(mask) = 0;
[v d] = eig(m);
[d indxs] = sort(d);
indxBases = reshape(0:4:4*(nrows*ncols - 1), [1 1 nrows ncols]);
indxBases = repmat(indxBases, [2 2 1 1]);
indxs = 2*mxarray(indxs).' - 1;
v = v([indxs; indxs + 1] + indxBases);
majDirs = squeeze(atan2(v(2,1,:,:), v(1,1,:,:)));
majLens = squeeze(1./sqrt(d(1,1,:,:)));
minDirs = squeeze(atan2(v(2,2,:,:), v(1,2,:,:)));
minLens = squeeze(1./sqrt(d(2,1,:,:)));
mask = squeeze(sum(sum(mask)) ~= 0);
majDirs(mask) = 0;
minDirs(mask) = 0;
majLens(mask) = 1;
minLens(mask) = 1;
majDirs = cmod(majDirs, pi);
minDirs = cmod(minDirs, pi);