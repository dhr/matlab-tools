function samples = samplepdf(pdf, n)

cdf = cumsum(pdf(:));
nzi = find(cdf > 0, 1);
pts = rand(n, 1)*cdf(end);
samples = bsearch(cdf, pts, -1, -1);
samples(samples == 0) = nzi;
