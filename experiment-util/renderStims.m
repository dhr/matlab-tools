function renderStims(shapes, rs, viewParams, stimNames)

cwd = cd([radianceroot '/stim-renderer']);

for i = 1:length(shapes)
  fid = fopen('surface.rad', 'w');
  fprintf(fid, 'void mesh blob\n');
  fprintf(fid, '7 %s -rx %f -ry %f -rz %f\n', strrep(shapes{i}, 'obj', 'rtm'), rs{i});
  fprintf(fid, '0\n0\n');
  mask = makeMask([2250 2250], shapes{i}, rs{i}, viewParams(i).vp, viewParams(i).vd, viewParams(i).vu, viewParams(i).va);
  matlabToRadiance(mask, [odtgfroot '/Radiance/stim-renderer/bigmask.pic']);
  if exist('stimNames', 'var')
    unix(['./makestim ' stimNames{i}]);
  else
    unix(['./makestim stim-' num2str(i, '%02d')]);
  end
end

cd(cwd);
