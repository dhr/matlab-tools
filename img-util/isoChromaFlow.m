function [ts, cs] = isoChromaFlow(rg, by, sigma)

if ~exist('sigma', 'var')
  sigma = 1;
end

if ~exist('by', 'var')
  rgb = rg;
  rg = rgb(:,:,1) - rgb(:,:,2);
  by = rgb(:,:,3) - (rgb(:,:,1) + rgb(:,:,2))/2;
end

[rgx, rgy] = imageGradient(rg, sigma);
[byx, byy] = imageGradient(by, sigma);

vx = rg.*rgx + by.*byx;
vy = rg.*rgy + by.*byy;

ts = atan2(-vx, vy);
cs = sqrt(vx.^2 + vy.^2);
