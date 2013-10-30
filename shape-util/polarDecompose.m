function [q, s] = polarDecompose(m, thresh)
%POLARDECOMPOSE Computes the polar decomposition of a matrix.
%   [Q,S] = POLARDECOMPOSE(M,ACC) computes the polar decomposition of a
%   square matrix M into orthogonal component Q and symmetric component S.
%   Optionally, accuracy ACC can be specified---the default is 1e-10.

if nargin < 2
  thresh = 1e-10;
end

prev = zeros(size(m));
cur = (m + inv(m)')/2;
while norm(cur - prev, 'fro') > thresh
  prev = cur;
  cur = (cur + inv(cur)')/2;
end

q = cur;
s = q \ m;