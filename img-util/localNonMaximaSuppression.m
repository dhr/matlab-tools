function flow = localNonMaximaSuppression(flow, n)

if ~exist('n', 'var')
  n = size(flow, 3);
end

indxs = 1:size(flow, 3);
indxs = indxs';

for shift = -n:n
  if shift == 0
    continue;
  end
  
  flow(abs(flow) < abs(flow(:,:,circshift(indxs, shift)))) = 0;
end
