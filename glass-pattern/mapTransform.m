function f = mapTransform(dirs, amts)
  f = @doTransform;

  function newPs = doTransform(ps)
    dirsDims = [size(dirs, 2)/2, size(dirs, 1)/2];
    ps = bsxfun(@plus, ps, dirsDims);
    newPs = advect(dirs, ps, amts, 0);
    newPs = bsxfun(@minus, newPs, dirsDims);
  end
end
