function data = samplegmm(components, n)

k = length(components);
weights = [components.weight];
cis = datasample(1:k, n, 'Weights', weights);
data = zeros(length(components(1).mean), n);
for i = 1:n
  data(:,i) = mvnrnd(components(cis(i)).mean', components(cis(i)).cov);
end
