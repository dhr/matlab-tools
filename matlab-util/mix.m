function out = mix(coeffs, varargin)

if length(coeffs) == 1 && length(varargin) == 2
  coeffs(2) = coeffs(1);
  coeffs(1) = 1 - coeffs(1);
end

if length(coeffs) ~= length(varargin)
  error('Number of mixing coefficients differs from number of inputs');
end

out = coeffs(1)*varargin{1};
for i = 2:length(coeffs)
  out = out + coeffs(i)*varargin{i};
end
