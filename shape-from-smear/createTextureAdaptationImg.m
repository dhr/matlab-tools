function stimImg = createTextureAdaptationImg(shapeData, varargin)

scale = 1;
anisoScale = 15;
diffIters = 5;
saturation = 1;

parsearglist({'scale', 'anisoScale', 'diffIters', 'saturation'}, varargin);

[m n] = size(shapeData.mask);

scales = scale + zeros(m, n);
anisos = anisoScale + zeros(m, n);

majDirs = shapeData.foreshortening.majDirs;

odt = makeODT([], majDirs + pi/2, scales, [], anisos, shapeData.mask, saturation);
odt = anisotropicDiffusion(odt, majDirs + pi/2, ones(m, n), diffIters);
odt(~shapeData.mask) = 0;

stimImg = struct('img', odt);