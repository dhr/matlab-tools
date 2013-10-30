function cols = calcDoubleOpponencyFlow(img, dogPlanes, nthetas, dogSigma, wavelen)

argdefaults('nthetas', 16, 'dogSigma', 3.5, 'wavelen', 22);

pos = @(x) x.*(x > 0);
dogs = differenceOfGaussian(img, dogSigma, 2*dogSigma, dogPlanes);
dogs = pos(cat(3, dogs, -dogs));
n = size(dogPlanes, 1);
gaborPlanes = zeros(n, 2);
for i = 1:n
  gaborPlanes(i, 1) = i;
  gaborPlanes(i, 2) = i + n;
%   gaborPlanes(2*i, 1) = i + n;
%   gaborPlanes(2*i, 2) = i;
end
do = pos(separatedGabor(dogs, wavelen, nthetas, gaborPlanes, 0));
cols = zeros(size(do(:,:,:,1)));
for i = 1:2:2*n
  cols = max(cols, pos(do(:,:,:,i) - do(:,:,:,i + 1)));
end
cols = localNonMaximaSuppression(max(cols(:,:,1:nthetas), cols(:,:,nthetas + 1:end)), 3);
