function logs = GaugeFigures(images, masks, figs, taskControllerConstructor, ids, nextStimSetupFun)
  AssertOpenGL;
  InitializeMatlabOpenGL;
  
  if ~exist('nextStimSetupFun', 'var')
    nextStimSetupFun = @(a,b,c,d) [];
  end
  
%   window = Screen('OpenWindow', max(Screen('Screens')), [0 0 0]);
  window = Screen('OpenWindow', 0, [0 0 0]);
  uiLoop = PTUILoop(window);
  
  taskController = taskControllerConstructor(uiLoop);
  data = struct('Id', [], 'TaskLog', []);

  escape = KbName('escape');
  leftshift = KbName('leftshift');
  leftalt = KbName('leftalt');
  
  listeners(1) = addlistener(uiLoop.ContainerView, 'KeyUp', @handleKeys);
  listeners(2) = addlistener(taskController, 'StimulusCompleted', @stimulusCompleted);
  
  if ~exist('data', 'file')
    mkdir('data');
  end
  
  i = 0;
  nextStimulus;
  
  try
    uiLoop.run;
  catch exc
    if ~isempty(ids{i})
      save(fullfile('data', ['tasklog-' ids{i} '-err']), 'data');
    end
    
    cleanup;
    Screen('Close', window);
    rethrow(exc);
  end
  
  cleanup;  
  Screen('Close', window);
  
  % ---------- Internal functions ---------- %
  
  function cleanup
    listeners = []; %#ok<SETNU>
    taskController = [];
    uiLoop = [];
  end

  function handleKeys(src, evnt) %#ok<*INUSL>
    if evnt.Delta(escape) && evnt.KeyCodes(leftshift) && evnt.KeyCodes(leftalt)
      uiLoop.stop;
      if ~isempty(ids{i})
        save(fullfile('data', ['tasklog-' ids{i}]), 'data');
      end
    end
    
    if evnt.Delta(escape) && evnt.KeyCodes(leftshift) && ~evnt.KeyCodes(leftalt)
      nextStimulus;
    end
  end

  function stimulusCompleted(src, evnt) %#ok<*INUSD>
    nextStimulus;
  end

  function nextStimulus
    if i > 0 && ~isempty(ids{i})
      save(fullfile('data', ['tasklog-' ids{i}]), 'data');
    end
    
    i = i + 1;
    
    if i <= numel(images)
      ptImage = PTImage(images{i});
      ptMask = PTImage(masks{i});
      stimulus = GFImStim(window, [0 0], ptImage, ptMask);
      
      if isempty(figs) || isempty(figs{i}) || ~isa(figs{i}, 'GFFigSet')
        if isempty(figs) || isempty(figs{i})
          figsCopy = [];
        else
          figsCopy = figs{i};
        end

        [figsCopy figSetBoundary] = gfInitFigs(figsCopy, masks{i});
        figSet = GFFigSet(figsCopy, figSetBoundary);
        figSet.setRemovables(1:figSet.NFigures, false);
      else
        figSet = GFFigSet(figs{i}.Figs, figs{i}.BoundaryPoly);
      end
      
      nextStimSetupFun(i, taskController, stimulus, figSet);
      taskController.nextStimulus(stimulus, figSet);
      
      data.Id = ids{i};
      data.TaskLog = taskController.TaskLog;
      
      if nargout > 0
        logs{i} = data.TaskLog;
      end
    else
      uiLoop.stop;
    end
  end
end
