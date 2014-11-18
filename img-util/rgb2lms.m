function lms = rgb2lms(rgb, linear)

if ~exist('linear', 'var')
  linear = false;
end

if ~linear
  rgb = rgb.^2.2;
end

mat = ...
 inv([ 5.3958   -4.3710    0.1852
      -0.6788    1.8257   -0.1963
      -0.0755   -0.0733    1.0893]);
lms = applyPixelTransform(rgb, mat);
