function [responses, responseTimes] = ...
  DepthComparisons(window, trials, stims, pairs, colors, keys, jitter)

AssertOpenGL;
KbName('UnifyKeyNames');

if ~exist('colors', 'var')
  colors = [1 0 0; 0 1 0];
end

if ~exist('keys', 'var')
  keys = [KbName('r') KbName('g')];
end

if ~exist('jitter', 'var')
  jitter = 150;
end

enumc = 1;
Y1 = enumc; enumc = enumc + 1;
X1 = enumc; enumc = enumc + 1;
Y2 = enumc; enumc = enumc + 1;
X2 = enumc;

close = false;
if isempty(window)
  window = Screen('OpenWindow', max(Screen('Screens')));
  close = true;
end

[winWidth, winHeight] = Screen('WindowSize', window);
halfWinWidth = round(winWidth/2);
halfWinHeight = round(winHeight/2);

cachedIms = repmat(struct, numel(stims), 1);
cachedDims = repmat(struct, numel(stims), 1);
imTexPtrs = [];

response1Key = keys(1);
response2Key = keys(2);
undoKey = KbName('delete');
if IsWin
  undoKey = [undoKey KbName('backspace')];
end
quitKey = [KbName('leftshift') KbName('escape')];
scrGrabKey = KbName('=+');

justUndid = true;

ptRad = 7;
aColor = [colors(1,:) 1];
bColor = [colors(2,:) 1];
ringColors = [zeros(3, 2); ones(1, 2)]*255;
dotColors = [aColor(:) bColor(:)]*255;

prompt = 'At which point is the surface closer to you?';

Screen('BlendFunction', window, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

nTrials = numel(trials);
responses = cell(nTrials, 1);
responseTimes = cell(nTrials, 1);

t = 1;
while t <= nTrials
  stimIndx = trials(t).stimIndx;
  stimType = trials(t).stimType;
  typeIndx = trials(t).typeIndx;
  if isfield(trials, 'flipColor')
    flipColor = trials(t).flipColor;
  else
    flipColor = false;
  end
  pair = reshape(pairs(trials(t).pairIndx).pairSubscripts(:), 2, []);

  if ~isfield(cachedIms, stimType) || length(cachedIms(stimIndx).(stimType)) < typeIndx || ...
      isempty(cachedIms(stimIndx).(stimType){typeIndx})
    img = stims(stimIndx).(stimType)(typeIndx).img;
    imHeight = size(img, 1);
    imWidth = size(img, 2);

    texID = Screen('MakeTexture', window, 255*cat(3, img, stims(stimIndx).mask));
    cachedIms(stimIndx).(stimType){typeIndx} = texID;
    imTexPtrs(end + 1) = cachedIms(stimIndx).(stimType){typeIndx}; %#ok<AGROW>

    halfImWidth = round(imWidth/2);
    halfImHeight = round(imHeight/2);

    imLeft = halfWinWidth - halfImWidth;
    imTop = halfWinHeight - halfImHeight + 50;

    imDims = [imLeft imTop imWidth imHeight];
    cachedDims(stimIndx).(stimType){typeIndx} = imDims;
  else
    texID = cachedIms(stimIndx).(stimType){typeIndx};
    imDims = cachedDims(stimIndx).(stimType){typeIndx};
  end
  
  if trials(t).angle ~= 0
    rotAngle = trials(t).angle*pi/180;
    rotMat = [cos(rotAngle) sin(rotAngle); -sin(rotAngle) cos(rotAngle)];
    rotOrig = [imDims(3:4)' + 1 imDims(3:4)' + 1]/2;
    pair = rotMat*(pair - rotOrig) + rotOrig;
  end
  
  jitterAmt = rand*jitter;
  jitterAngle = rand*2*pi;
  jitterX = jitterAmt*cos(jitterAngle);
  jitterY = jitterAmt*sin(jitterAngle);
  
  imDims(1:2) = imDims(1:2) + [jitterX jitterY];

  destRect = [imDims(1:2) imDims(1:2) + imDims(3:4)];
  Screen('DrawTexture', window, texID, [0 0 imDims(3:4)], destRect, trials(t).angle);
  Screen('TextSize', window, 24);
  DrawFormattedText(window, prompt, 'center', 20, [1 1 1]*255);

  scrCoords = [pair([X1 X2]); pair([Y1 Y2])] + [imDims([1 1]); imDims([2 2])] - 1;
  colorOrder = [1 + flipColor, 2 - flipColor];
  Screen('DrawDots', window, scrCoords, (ptRad + 2)*2, ringColors(:,colorOrder), [0 0], 2);
  Screen('DrawDots', window, scrCoords, ptRad*2, dotColors(:,colorOrder), [0 0], 2);

  Screen('FrameRect', window, [255 255 255], [10 winHeight - 30 winWidth - 11 winHeight - 10]);
  Screen('FillRect', window, [255 255 255], [10 winHeight - 30 10 + round((winWidth - 21)*t/nTrials) winHeight - 10]);

  [~, onsetTimestamp] = Screen('Flip', window);

  [responseTimestamp, keyCode] = KbWait([], 2);
  while ~any(keyCode([response1Key response2Key undoKey])) && ~all(keyCode(quitKey))
    [responseTimestamp, keyCode] = KbWait;
  end

  responseTime = responseTimestamp - onsetTimestamp;
  if keyCode(response1Key) && ~keyCode(response2Key)
    responses{t} = 1 + flipColor;
    responseTimes{t} = responseTime;
    justUndid = false;
  elseif keyCode(response2Key) && ~keyCode(response1Key);
    responses{t} = 2 - flipColor;
    responseTimes{t} = responseTime;
    justUndid = false;
  elseif keyCode(scrGrabKey)
    img = GrabScreen(window);
    imwrite(img, ['~/Desktop/scr-' num2str(round(rand*1000)) '.png']);
  elseif any(keyCode(undoKey))
    if ~justUndid
      t = t - 2;
      justUndid = true;
    else
      t = t - 1;
    end
  elseif all(keyCode(quitKey))
    break;
  end

  t = t + 1;
end

if close
  Screen('Close', imTexPtrs);
  Screen('Close', window);
end
