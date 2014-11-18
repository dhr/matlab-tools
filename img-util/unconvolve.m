function [out, temp] = unconvolve(Is, Fs)
%UNCONVOLVE Least-squares reconstruction of an image from convolutions.
%   [out, temp] = UNCONVOLVE(Is, Fs) solves the overconstrained linear
%   system of equations Fs{i}*out = Is(:,:,k) for I, where * is convolution
%   and Fs are a set of N convolution kernels in a cell array. If the
%   filters and size of the image don't change between calls to UNCONVOLVE,
%   the 'temp' output can be passed back in place of Fs to make things a
%   bit more efficient.

assert(~isempty(Is), 'No convolutions passed in Is');

if isstruct(Fs)
  temp = Fs;

  assert(all(temp.size == size(Is)), 'Image size changed.');
else
  if ~iscell(Fs)
    Fs = {Fs};
  end

  temp.size = size(Is);
  temp.num = numel(Fs);
  
  m = temp.size(1);
  n = temp.size(2);
  
  fdims = ndims(Fs);
  fsize = size(Fs);
  idims = ndims(Is) - 2;
  if any(fsize(1:idims) ~= temp.size(3:end)) || ...
     (fdims > idims && any(fsize(idims + 1:end) ~= 1))
    error('Fs and Is aren''t the same size.');
  end

  [xfreqs, yfreqs] = meshgrid(0:n - 1, 0:m - 1);
  temp.fftdFrs = cell(numel(Fs), 1);
  temp.Fnorm = 0;

  ginv = zeros(m, n);  
  for i = 1:temp.num
    filt = Fs{i};
    xshift = ceil(-size(filt, 2)/2);
    yshift = ceil(-size(filt, 1)/2);
    shiftCoeffs = exp(-2*pi*1i*(xshift.*xfreqs/n + yshift.*yfreqs/m));
    temp.fftdFrs{i} = fft2(rot90(filt, 2), m, n).*shiftCoeffs;
    temp.Fnorm = temp.Fnorm + norm(temp.fftdFrs{i});
    ginv = ginv + temp.fftdFrs{i}.*fft2(filt, m, n).*shiftCoeffs;
  end
  
  temp.tol = m*n*temp.num*temp.Fnorm*eps(class(ginv));
  temp.g = 1./ginv;
  temp.g(ginv < temp.tol) = 0;
end

out = zeros(temp.size(1:2));
for i = 1:temp.num
  out = out + temp.fftdFrs{i}.*fft2(Is(:,:,i), temp.size(1), temp.size(2));
end
out = real(ifft2(temp.g.*out));
