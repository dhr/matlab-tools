%SATURATECONTRAST Compensates for low contrast resulting from a blur.
%   SAT = SATURATECONTRAST(IM, COEFS, MEAN) performs contrast
%   renormalization of IM using coefficients COEFS for an ERF centered on
%   MEAN.  COEFS depend on why IM has low contrast.  In the case of a
%   gaussian blurring with variable sigmas s, for example, using COEFS =
%   1./(12*s) works well.  MEAN defaults to 0.5.

function x = saturateContrast(x, p, u)

if isscalar(p)
  p = repmat(p, size(x));
end

if nargin < 3
  u = 0.5;
end

p(p > 1e6) = 1e6;

x = (erf((x - u)./(sqrt(2).*p)) + erf(u./(sqrt(2).*p)))./ ...
    (erf((1 - u)./(sqrt(2).*p)) + erf(u./(sqrt(2).*p)));