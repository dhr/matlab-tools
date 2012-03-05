function [depmtx dirs] = calcdeps

toplevel = fileparts(mfilename('fullpath'));
old = cd(toplevel);
basepart = @(x) x(length(toplevel) + 2:end);

files = dir;
dirs = {files([files.isdir]).name};
dirs = dirs(~strncmp('.', dirs, 1));

depmtx = false(length(dirs));
cd(old);

for i = 1:length(dirs)
  mfiles = dir([dirs{i} filesep '*.m']);
  names = {mfiles.name};
  mfiles = strcat([dirs{i} filesep], names(~strcmp('Contents.m', names)));
  deps = depdir(mfiles{:}, '-toponly');
  deps = deps(strncmp(toplevel, deps, length(toplevel)));
  deps = cellfun(basepart, deps, 'UniformOutput', false);
  
  depmtx(i,:) = cellfun(@(x) any(strcmp(x, deps)), dirs);
end
