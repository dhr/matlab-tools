function xyz = lms2xyz(lms)

mat = ...
  inv([ 0.4002 0.7076 -0.0808
       -0.2263 1.1653 0.0457
        0.0 0.0 0.9182]); % Hunt-Pointer-Estevez
%   inv([ 0.7328    0.4296   -0.1624
%        -0.7036    1.6975    0.0061
%         0.0030   -0.0136    0.9834]);

xyz = applyPixelTransform(lms, mat);
