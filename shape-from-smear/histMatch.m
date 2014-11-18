function matched = histMatch(src, dest, mask, nbins)
%HISTMATCH Rescale image intensities to match a histogram
%   MATCHED = HISTMATCH(SRC, DEST, MASK, NBINS) rescales the values of DEST
%   so that DEST has a histogram approximately matching that of SRC.
%   Optionally, a mask MASK can be supplied, restricting the rescaling
%   operation to only consider the histogram of values lying inside the
%   mask. NBINS controls how many bins to use in computing histograms.

if size(src) ~= size(dest)
  srcmask = true(size(src));
  destmask = true(size(dest));
else
  if nargin < 3
    mask = true(size(src));
  end
  
  srcmask = mask;
  destmask = mask;
end

if nargin < 4
  nbins = 200;
end

srchist = hist(src(srcmask), nbins);
cumsrc = cumsum(srchist);
cumsrc = cumsrc/max(cumsrc);

desthist = hist(dest(destmask), nbins);
cumdest = cumsum(desthist);
cumdest = cumdest/max(cumdest);

inds = minDiffInds(cumdest, cumsrc);
normeddest = normalizeImage(dest(destmask));
destvalinds = round(normeddest*(nbins - 1) + 1);
reassignedinds = inds(destvalinds);
matched = zeros(size(dest));
high = max(src(srcmask));
low = min(src(srcmask));
matched(destmask) = (reassignedinds - 1)/(nbins - 1)*(high - low) + low;
