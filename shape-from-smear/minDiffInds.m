function indxs = minDiffInds(a, b)
%MINDIFFINDS Find indices of elements minimizing differences.
%   I = MINDIFFINDS(A, B) finds the element in B closest to each element in
%   A and returns its index.  In otherwords, |A - B(I)| is minimized.

a = a(:)';
b = b(:);

diffs = abs(bsxfun(@minus, a, b));
[ignore indxs] = min(diffs); %#ok<ASGLU>
