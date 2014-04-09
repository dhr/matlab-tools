function [components, loglikelihood] = fitgmm(data, k)
%Fits a Gaussian mixture model (GMM) to data, using EM.

[d, n] = size(data);
memberships = rand(n, k);
memberships = bsxfun(@rdivide, memberships, sum(memberships, 2));

template = struct('weight', 1/k, 'mean', zeros(d, 1), 'cov', zeros(d, d));
components = repmat(template, 1, k);

lastll = nan;
loglikelihood = -inf;
minllchange = 1e-10;

numits = 0;
maxits = 100;
while ~(loglikelihood - lastll < minllchange) && numits < maxits
  lastll = loglikelihood;
  wtotal = sum(memberships);
  for i = 1:k
    components(i).weight = wtotal(i)/n;
    components(i).mean = data*memberships(:,i)/wtotal(i);
    demeaned = bsxfun(@minus, data, components(i).mean);
    covi = demeaned*bsxfun(@times, memberships(:,i), demeaned')/wtotal(i);
    components(i).cov = 0.5*(covi + covi');
    % Use cholesky decomposition to get log likelihoods...
    fx = mvnpdf(data', components(i).mean', components(i).cov);
    memberships(:,i) = components(i).weight*fx;
  end
  likelihoods = sum(memberships, 2);
  loglikelihood = sum(log(likelihoods))
  memberships = bsxfun(@rdivide, memberships, likelihoods);
  numits = numits + 1;
end

end
