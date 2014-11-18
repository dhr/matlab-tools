sqrtFit = 0;
is1d = false;
nsamples = 25;
density = 5000;
boxes = (linspace(0, 1 - 1/density, density) + linspace(1/density, 1, density))./2;
xs = linspace(0, 1, density)';
sigmas = linspace(1, 10, nsamples)';
coefs = zeros(nsamples, 1);
energy = zeros(nsamples, 1);
satFun = @(p, x) saturateContrast(x, p(1));
betaFun = @(p, x) betainc(x, p(1), p(2));
alpha = 5/(12*sqrt(2));

niters = 10;
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
      filter = exp(-(-radius:radius).^2./(2*sigma.^2))';
%       filter = rand(2*ceil(sigma) + 1, 1);
      filter = filter./sum(filter(:));
    else
      filter = fspecial('gaussian', 2*radius + 1, sigma);
    end
    energy(i) = sum(filter(:).^2);
    noiseSmoothed = imfilter(noise, filter, 'circular');
    noiseSmoothed = saturateContrast(noiseSmoothed, alpha*sqrt(energy(i)));
    [noiseSmoothed energies] = lic(zeros(size(noiseSmoothed)), noiseSmoothed, 1, 20);
    counts = histc(noiseSmoothed(:), boxes)';
    partsums = cumsum(counts)./sum(counts(:));
    e = energies(floor(size(energies, 1)/2), floor(size(energies, 2)/2));
    c = nlinfit(xs, partsums', satFun, alpha*sqrt(e))./(alpha*sqrt(e));
    plot(xs, partsums);
    hold on;
    plot(xs, satFun(c*alpha*sqrt(e), xs), 'Color', 'r');
    hold off;
    drawnow;
    coefs(i,:) = coefs(i,:) + c;
  end
end

coefs = coefs/10;
plot(sigmas, coefs/niters);

clear partsums i counts density nsamples satFun xs ...
      is1d filter radius noiseSmoothed niters e c;