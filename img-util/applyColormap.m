function cimg = applyColormap(img, cmap, freqScale)

if ~exist('freqScale', 'var')
  freqScale = 1;
end

n = size(cmap, 1);
cimg = ind2rgb(round(1 + mod(freqScale*img*(n - 1), n)), cmap);
