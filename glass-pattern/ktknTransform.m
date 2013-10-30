function f = ktknTransform(w, h, theta, kt, kn, amt)
  f = @doTransform;
  [xs ys] = meshgrid(linspace(-w/2, w/2, w), linspace(h/2, -h/2, h));
 
  function newPs = doTransform(ps)
    map = evalHelicoidalFlow(xs, ys, theta, kt/(h/2), kn/(w/2));
    dirsDims = [size(map, 2)/2, size(map, 1)/2];
    ps = bsxfun(@plus, ps, dirsDims);
    newPs = advect(map, ps, amt);
    newPs = bsxfun(@minus, newPs, dirsDims);
  end
end
