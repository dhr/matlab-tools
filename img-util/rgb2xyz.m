function xyz = rgb2xyz(rgb)

cform = makecform('srgb2xyz');
xyz = applycform(rgb, cform);
