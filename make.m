function make(varargin)

dirbase = fileparts(mfilename('fullpath'));
old = cd(dirbase);

s = load('dependencies');
deps = s.deps;
dirs = s.dirs;
ndirs = length(dirs);

have = containers.Map(dirs, num2cell(false(1, ndirs)));
dirnum = containers.Map(dirs, num2cell(1:ndirs));

clonefmt = 'git clone git://github.com/dhr/%s.git';
pullfmt = 'cd %s; git pull; cd ..';

if nargin == 0
  disp('Specify one or more targets for make. Available targets are:');
  disp('  all (install all available tools)');
  disp('  update (update all installed tools)');
  fprintf('  %s\n', dirs{:});
  return;
end

cellfun(@domake, varargin);

cd(old);

function domake(target)
  switch lower(target)
    case 'all'
      targs = dirs;
      quatloc = which('angle2quat');
      ourloc = fullfile(dirbase, 'quaternions');
      if ~isempty(quatloc) && ~strncmp(ourloc, quatloc, length(ourloc))
        targs = setdiff(targs, 'quaternions');
      end
      cellfun(@domake, targs);
    
    case 'update'
      files = dir;
      targs = {files([files.isdir]).name};
      targs = targs(cellfun(@(s) any(strcmp(s, dirs)), targs));
      cellfun(@domake, targs);
      
    otherwise
      if ~have.isKey(target)
        warning('Skipping unrecognized target ''%s''', target); %#ok<WNTAG>
        return;
      end
      
      if ~have(target)
        fulldir = fullfile(dirbase, target);
        
        if isdir(fulldir)
          fprintf('Updating %s... ', target);
          [status, output] = system(sprintf(pullfmt, target));
        else
          fprintf('Installing %s and adding it to the path... ', target);
          [status, output] = system(sprintf(clonefmt, target));
        end
        
        pathitems = regexp(path, '(?:^|:)([^:]+)(?:$|:)', 'tokens');
        
        if ~any(strcmp(fulldir, pathitems))
          addpath(fulldir);
          savepath;
        end
        
        if status == 0
          fprintf('done.\n');
        else
          fprintf('error! Output was:\n');
          disp(output);
          error('Error with command, see above for details.');
        end
        
        have(target) = true;
        cellfun(@domake, dirs(deps(dirnum(target),:)));
      end
  end
end

end
