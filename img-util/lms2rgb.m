function rgb = lms2rgb(lms, linear)

if ~exist('linear', 'var')
  linear = false;
end

mat = ...
 [ 5.3958   -4.3710    0.1852
  -0.6788    1.8257   -0.1963
  -0.0755   -0.0733    1.0893];
rgb = applyPixelTransform(lms, mat);

if ~linear
  rgb = bound(rgb, 0, 1);
  rgb = rgb.^(1/2.2);
end
