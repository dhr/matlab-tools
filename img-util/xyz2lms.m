function lms = xyz2lms(xyz)

mat = ...
  [ 0.2471    0.7800   -0.0321
   -0.4348    1.3127    0.1158
    0.0389   -0.0449    0.9759];
%     [ 0.4002 0.7076 -0.0808
%      -0.2263 1.1653 0.0457
%       0.0 0.0 0.9182]; % Hunt-Pointer-Estevez
lms = applyPixelTransform(xyz, mat);
