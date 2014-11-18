function b = ctz(a, b)
%CTZ Return the number with the smaller absolute value.
%   X = CTZ(A, B) returns elements of A where abs(A) < abs(B), and elements
%   of B where the reverse is true.
%
%   See also MIN, MAX.

altb = abs(a) < abs(b);
b(altb) = a(altb);