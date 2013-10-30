function so = convolveGabors(img, wavelength, phase, norientations, sigma)

if ~exist('norientations', 'var')
  norientations = 8;
end

if ~exist('sigma', 'var')
  sigma = wavelength/4;
end

so = zeros([size(img) 2*norientations]);

for j = 1:size(img, 3)
  for i = 1:2*norientations
    theta = (i - 1)/norientations*pi;
    p = phase + (theta >= pi)*pi;
    gabor = makeGabor(mod(theta, pi), wavelength, p, sigma, 1.5);
    so(:,:,i,j) = imfilter(img(:,:,j), gabor, 'replicate');
  end
end
