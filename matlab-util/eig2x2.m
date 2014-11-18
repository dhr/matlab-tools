function [e11s, e21s, l1s, l2s] = eig2x2(m11s, m21s, m22s)
%EIG2X2  Calculate the eigendecomposition of an array of 2x2 matrices.
%  [E11S, E21S, L1S, L2S] = EIG2X2(M11S, M21S, M22S) calculates the
%  eigendecomposition of the array of symmetric 2x2 matrices whose
%  components are given by M11S (upper left), M21S (off-diagonal), and M22S
%  (lower right). Returns the first eigenvector in E11S and E21S, and the
%  eigenvalues in L1S and L2S. Eigenvalues are sorted by decreasing
%  absolute value (and the first eigenvector corresponds to the eigenvalue
%  with largest absolute value).

if ~exist('order', 'var')
  order = true;
end

tau = 0.5*(m22s - m11s)./m21s;
t = sign(tau)./(abs(tau) + sqrt(1 + tau.^2));
c = 1./sqrt(1 + t.^2);
s = c.*t;
l1s = m11s - t.*m21s;
l2s = m22s + t.*m21s;
e11s = c;
e21s = -s;

swaps = abs(l2s) > abs(l1s);
e11s(swaps) = s(swaps);
e21s(swaps) = c(swaps);
temp = l1s(swaps);
l1s(swaps) = l2s(swaps);
l2s(swaps) = temp;

divzeros = m21s == 0;
order = m11s(divzeros) >= m22s(divzeros);
e11s(divzeros) = order;
e21s(divzeros) = 1 - order;
l1s(divzeros) = m11s(divzeros).*order + m22s(divzeros).*~order;
l2s(divzeros) = m22s(divzeros).*order + m11s(divzeros).*~order;
