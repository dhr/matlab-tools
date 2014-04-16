function make(varargin)

if nargin == 0
  disp('At the MATLAB command prompt:');
  disp('  make update (update tools)');
  disp('  make install (add tools to MATLAB path)');
  return;
end

dirbase = fileparts(mfilename('fullpath'));
[~, dirs] = calcdeps;

for command = varargin
  switch command{1}
    case 'install'
      targs = dirs;
      quatloc = which('angle2quat');
      ourloc = fullfile(dirbase, 'quaternions');
      if ~isempty(quatloc) && ~strncmp(ourloc, quatloc, length(ourloc))
        targs = setdiff(targs, 'quaternions');
      end
      
      pathitems = regexp(path, '(?:^|:)([^:]+)(?:$|:)', 'tokens');
      for target = targs
        fulldir = fullfile(dirbase, target{1});

        if ~any(strcmp(fulldir, pathitems))          
          addpath(fulldir);
          savepath;
          fprintf('Added %s to path\n', target{1});
        end
      end
    
    case 'update'
      fprintf('Updating... ');
      [status, output] = system('git pull');
      if status == 0
        fprintf('done.\n');
        fprintf('%s', output);
      else
        fprintf('error!\n');
        fprintf('%s', output);
        error('Error during update, see above for details.');
      end
  end
end

end
