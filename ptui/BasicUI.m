function BasicUI(setupFun, cleanupFun, screen)
  AssertOpenGL;
  InitializeMatlabOpenGL;

  ListenChar(2);
  KbName('UnifyKeyNames');

  if ~exist('screen', 'var')
    screen = max(Screen('Screens'));
  end
  
  window = Screen('OpenWindow', screen, [51 51 51]);
  uiLoop = PTUILoop(window);
  
  setupFun(uiLoop);
  
  uiLoop.run;
  
  if exist('cleanupFun', 'var')
    cleanupFun();
  end
  
  ListenChar(0);
  ShowCursor;
  ReleaseCursor;
  
  Screen('Close', window);
end
