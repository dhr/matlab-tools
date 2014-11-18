function BasicUI(setupFun, cleanupFun, screen, window)
  AssertOpenGL;
  InitializeMatlabOpenGL;

  ListenChar(2);
  KbName('UnifyKeyNames');

  if ~exist('screen', 'var') || isempty(screen)
    screen = max(Screen('Screens'));
  end
  
  closeWindow = false;
  if ~exist('window', 'var')
    window = Screen('OpenWindow', screen, [51 51 51]);
    closeWindow = true;
  end
  
  uiLoop = PTUILoop(window);
  
  setupFun(uiLoop);
  
  uiLoop.run;
  
  if exist('cleanupFun', 'var')
    cleanupFun();
  end
  
  ListenChar(0);
  ShowCursor;
  ReleaseCursor;
  
  if closeWindow
    Screen('Close', window);
  end
end
