function [thetas, rs, cs] = isoHueFlow(rg, by, sigma)

if ~exist('by', 'var') || isempty(by)
  rgb = rg;
  rg = rgb(:,:,1) - rgb(:,:,2);
  by = rgb(:,:,3) - (rgb(:,:,1) + rgb(:,:,2))/2;
end

if ~exist('sigma', 'var')
  sigma = 1;
end

if false
  rgcols = convolveGabors(rgso, 22, 0, 16); %#ok<*UNRCH>
  bycols = convolveGabors(byso, 22, 0, 16);
  [rgthetas, rgconfs] = maxthetas(rgcols, true);
  [bythetas, byconfs] = maxthetas(bycols, true);

  rgx = rgconfs.*cos(rgthetas);
  rgy = rgconfs.*sin(rgthetas);
  byx = byconfs.*cos(bythetas);
  byy = byconfs.*sin(bythetas);

  vx = rgx.*byso + byx.*rgso;
  vy = rgy.*byso + byy.*rgso;
else
  [rgsox, rgsoy] = imageGradient(rg, sigma);
  [bysox, bysoy] = imageGradient(by, sigma);

  vx = by.*rgsox - rg.*bysox;
  vy = by.*rgsoy - rg.*bysoy;
end

thetas = atan2(-vx, vy);
rs = sqrt(vx.^2 + vy.^2);
cs = sqrt(rg.^2 + by.^2);
