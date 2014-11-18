function vs = normalizeVerts(vs)

vs = bsxfun(@minus, vs, mean(vs));
vs = vs/max(sqrt(sum(vs.^2, 2)));
