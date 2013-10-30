function rgb = xyz2rgb(xyz)

cform = makecform('xyz2srgb');
rgb = applycform(xyz, cform);
