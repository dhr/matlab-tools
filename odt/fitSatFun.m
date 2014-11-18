sqrtFit = 0;
is1d = true;
nsamples = 50;
density = 5000;
boxes = (linspace(0, 1 - 1/density, density) + linspace(1/density, 1, density))./2;
xs = linspace(0, 1, density)';
sigmas = linspace(0.5, 30, nsamples)';
coefs = zeros(nsamples, 1);
energy = zeros(nsamples, 1);
satFun = @(p, x) saturateContrast(x, p(1));
betaFun = @(p, x) betainc(x, p(1), p(2));
alpha = 5/(12*sqrt(2));

niters = 1;
for iters = 1:niters
  if is1d
    noise = rand(250000, 1);
  else
    noise = rand(500);
  end

  for i = 1:nsamples
    sigma = sigmas(i);
    radius = max(ceil(3*sigma), 5);
    if is1d
%       filter = exp(-(-radius:radius).^2./(2*sigma.^2))';
      filter = rand(2*ceil(sigma) + 1, 1);
      filter = filter./sum(filter(:));
    else
      filter = fspecial('gaussian', 2*radius + 1, sigma);
    end
    energy(i) = sum(filter(:).^2);
    noiseSmoothed = imfilter(noise, filter, 'circular');
    counts = histc(noiseSmoothed(:), boxes)';
    partsums = cumsum(counts)./sum(counts(:));
    coefs(i,:) = nlinfit(xs, partsums', satFun, alpha*sqrt(energy(i)));
    plot(xs, partsums);
    hold on;
    plot(xs, satFun(coefs(i,:), xs), 'Color', 'r');
    hold off;
    drawnow;
  end

  sqrtFun = @(p, x) p(1)*sqrt(x);
  sqrtFit = sqrtFit + nlinfit(energy, coefs, sqrtFun, alpha);
end

sqrtFit = sqrtFit/niters;

plot(energy, coefs);
hold on;
plot(energy, sqrtFun(sqrtFit, energy), 'Color', 'r');

clear partsums i counts density nsamples satFun xs ...
      is1d filter radius noiseSmoothed niters;