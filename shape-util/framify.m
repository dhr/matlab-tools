function [vd vu] = framify(vd, vu)

vd = vd(:)./norm(vd);
vu = vu(:)./norm(vu);

vdDotVu = sum(vd.*vu);
if abs(vdDotVu) == 1
  error('View direction and view up vector are parallel.');
elseif vdDotVu ~= 0
  vu = vu - sum(vu.*vd).*vd;
  vu = vu./norm(vu);
end
