function out = separatedGabor(img, wavelength, norientations, channels, phase)

if ~exist('norientations', 'var')
  norientations = 8;
end

if ~exist('channels', 'var')
  channels = [1 2];
end

if ~exist('phase', 'var')
  phase = 0;
end

out = zeros([size(img, 1) size(img, 2) 2*norientations size(channels,1)]);

for j = 1:size(channels, 1)
  for i = 1:2*norientations
    theta = mod(i - 1, norientations)/norientations*pi;
    sign = iif(i <= norientations, 1, -1);
    gabor = sign*makeGabor(theta, wavelength, phase, wavelength/4, 1.5);
    posPart = gabor.*(gabor > 0);
    negPart = gabor.*(gabor < 0);
    out(:,:,i,j) = filter2(posPart, img(:,:,channels(j,1))) - ...
                  filter2(negPart, img(:,:,channels(j,2)));
  end
end
