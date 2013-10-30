function [dirs, amts] = perceivedShadingFlow(normals, lightSource)

shaded = shadeLambertian(normals, lightSource);
[dx, dy] = gradient(shaded);
amts = sqrt(dx.^2 + dy.^2);
dirs = atan2(-dy, dx) + pi/2;
