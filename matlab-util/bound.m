function a = bound(a, low, hi)
%BOUND Limits the maximum and minimum values of a matrix.
%   B = BOUND(A, LOW, HI) bounds the values in A so that they are all
%   greater than or equal to LOW and less than or equal to HI.

a(a < low) = low;
a(a > hi) = hi;