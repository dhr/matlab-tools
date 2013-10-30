function ind = insidePoly(x, y, xv, yv, tol, includeEdges)
  if nargin < 6
    includeEdges = false;
  end

  if nargin < 5
     tol = 1e-6;
  end

  x = x(:)';
  y = y(:)';
  xv = xv(:);
  yv = yv(:);

  nPts = length(x);
  nVerts = length(xv);

  if nPts ~= length(y)
    error('Point vectors of unequal length.');
  end
  
  if nVerts ~= length(yv)
    error('Polygon vertex vectors of unequal length.')
  end

  if xv(nVerts) ~= xv(1) || yv(nVerts) ~= yv(1)
     nVerts = nVerts + 1;
     xv(nVerts) = xv(1);
     yv(nVerts) = yv(1);
  end;

  dx = ones(nVerts, 1)*x - xv*ones(1, nPts);  
  dy = ones(nVerts, 1)*y - yv*ones(1, nPts);
  
  if nVerts == 1
     vertexPt = abs(dx) < tol & abs(dy) < tol;
     ind = includeEdges && vertexPt;
  else
    vertexPt = any(abs(dx) < tol & abs(dy) < tol);
    angs = rem(diff(atan2(dy, dx)) + 3*pi + eps, 2*pi) - pi - eps;

    dxv = (xv(2:nVerts) - xv(1:nVerts - 1))*ones(1, nPts);
    dyv = (yv(2:nVerts) - yv(1:nVerts - 1))*ones(1, nPts);
    dxl = dx(1:nVerts - 1,:);
    dyl = dy(1:nVerts - 1,:);

    lgt = (dxl.*dxv + dyl.*dyv)./(dxv.*dxv + dyv.*dyv);
    distx = 2*tol*ones(nVerts - 1, nPts);
    disty = distx;

    ii = (lgt > 0 & lgt < 1);
    distx(ii) = dxl(ii) - lgt(ii).*dxv(ii);
    disty(ii) = dyl(ii) - lgt(ii).*dyv(ii);

    edgePt = any(abs(distx) < tol & abs(disty) < tol);
    interiorPt = logical(abs(round(sum(angs)/(2*pi))));

    ind = includeEdges & edgePt';
    ind(vertexPt) = includeEdges;
    ind(interiorPt) = true;
  end
end