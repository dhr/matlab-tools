function dfdv = directionalDerivative(f, vx, vy, sigma)

if ~exist('sigma')
  sigma = 0.5;
end

[fx, fy] = imageGradient(f, sigma);

dfdv = fx.*vx + fy.*vy;
