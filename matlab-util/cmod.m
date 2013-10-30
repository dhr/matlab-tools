function d = cmod(t, r)
%CMOD Centered modulus.
%   D = CMOD(X, M) performs a centered modulus around 0, such that D lies
%   within the range -M/2 to M/2.

d = mod(t, r);
d = (d ~= r/2).*(d - (d > r/2).*r) + (d == r/2).*(sign(t).*d);