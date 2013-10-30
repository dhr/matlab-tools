function Fs = gradientFilter(sigma)

if sigma == 0
  sigma = eps;
end

Fs = {conv2(fspecial('gaussian', round(6*sigma) + 1, sigma), [-1 0 1]/2, 'full')};
Fs = [Fs; {rot90(Fs{1})}];
