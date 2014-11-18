function [sdLeft, sdRight] = ...
  makeStereoShapeDataPair(shapes, rs, view, fp, pupDist, varargin)

normalize = @(v) v./norm(v);

dist = norm(fp - view.vp);
offset = pupDist/2;
right = cross(view.vd, view.vu);

viewLeft = view;
viewRight = view;
viewLeft.vp = view.vp - offset*right;
viewRight.vp = view.vp + offset*right;
viewLeft.vd = normalize(fp - viewLeft.vp);
viewRight.vd = normalize(fp - viewRight.vp);

sdLeft = makeShapeData(shapes, rs, viewLeft, varargin{:});
sdRight = makeShapeData(shapes, rs, viewRight, varargin{:});
