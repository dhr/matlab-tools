function lines = RasterLines(window, image, mask, lines, types)
  AssertOpenGL;
  KbName('UnifyKeyNames');
  ListenChar(2);

  [imHeight imWidth] = size(image);

  if any([imHeight imWidth] ~= size(mask))
    error('Mask must have same dimensions as image.');
  end
  
  if ~islogical(mask)
    mask = logical(mask);
  end
  
  flippedMask = flipud(mask);
  
  enumc = 1;
  X = enumc; enumc = enumc + 1;
  TYPE = enumc;

  if ~isstruct(lines)
    ys = lines;
    lines = repmat(struct('y', 0, 'points', []), numel(lines), 1);
    ysCell = num2cell(ys);
    [lines.y] = deal(ysCell{:});
  else
    ys = [lines.y];
  end

  if any(ys < 0 | ys >= imHeight)
    error('Raster line value is out of range.');
  end

  nLines = numel(lines);

  if ~isstruct(types) && iscell(types)
    typeNames = types;
    nTypes = numel(types);
    types = repmat(struct('name', [], 'color', []), nTypes, 1);
    [types.name] = deal(typeNames{:});

    for i = 1:nTypes
      types(i).color = hsv2rgb([(i - 1)/nTypes 1 1]);
    end
  else
    error('The types parameter should be either a structure or a cell array.');
  end

  close = false;
  if isempty(window)
    window = Screen('OpenWindow', max(Screen('Screens')));
    close = true;
  end

  [winWidth winHeight] = Screen('WindowSize', window);
  halfWinWidth = round(winWidth/2);
  halfWinHeight = round(winHeight/2);

  halfImWidth = round(imWidth/2);
  halfImHeight = round(imHeight/2);

  imLeft = halfWinWidth - halfImWidth;
  imBottom = halfWinHeight - halfImHeight - 50;
  
  typesWidth = 600;
  typesRad = 32;
  typesHeight = typesRad*2;
  halfTypesWidth = typesWidth/2;
  halfTypesHeight = typesHeight/2;
  typesLeft = halfWinWidth - halfTypesWidth;
  typesBottom = winHeight - 1 - typesHeight - 40;
  typesCentersX = typesLeft + typesWidth/nTypes/2*(1:2:2*nTypes - 1);
  typesCentersY = repmat(typesBottom + halfTypesHeight, 1, nTypes);

  imTexPtr = Screen('MakeTexture', window, cat(3, image, mask)*255);

  nextLineKey = KbName('return');
  deleteKey = KbName('delete');
  quitKey = KbName('escape');
  nextPtKey = KbName('tab');
  shiftKey = [KbName('leftshift') KbName('rightshift')];
  moveRightKey = KbName('rightarrow');
  moveLeftKey = KbName('leftarrow');
  numberKey = KbName('1!'):KbName('0)');
  
  lineColor = [0.25 1 0 0.75];
  ptRad = 7;

  Screen('BlendFunction', window, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
  
  Screen('FillRect', window, [0 0 0]);
  
  [keyDown secs keyCodes] = KbCheck;
  
  [x y buttons] = GetMouse(window); y = winHeight - y - 1;

  lineOrder = Shuffle(1:nLines);
  indx = 1;
  
  curLine = lines(lineOrder(indx));
  nPts = size(curLine.points, 1);
  validXs = find(flippedMask(curLine.y + 1,:)) - 1;
  minX = min(validXs);
  maxX = max(validXs);
  curPt = 0;
  hoveredPt = 0;
  
  while true
    currentY = winHeight - imBottom - 1 - curLine.y;

    Screen('DrawLine', window, lineColor*255, 0, currentY, winWidth, currentY, 2);

    Screen('DrawTexture', window, imTexPtr, [0 0 imWidth imHeight], ...
           [imLeft ...
            winHeight - (imBottom + imHeight) - 1 ...
            imLeft + imWidth ...
            winHeight - imBottom - 1]);
    
    for i = 1:nTypes
      Screen('DrawDots', window, ...
             [typesCentersX(i) winHeight - typesCentersY(i) - 1], typesRad*2, ...
             [types(i).color 1]*255, [0 0], 2);
      
      oldTextSize = Screen('TextSize', window, 16);
      bounds = Screen('TextBounds', window, types(i).name);
      Screen('DrawText', window, types(i).name, ...
             typesCentersX(i) - round(bounds(3)/2), winHeight - typesBottom - 1 + 5, ...
             [1 1 1]*255);
      Screen('TextSize', window, oldTextSize);
    end
    
    ptsOrder = [(1:nPts)' ones(nPts,1)];
    
    if curPt
      ptsOrder(curPt,2) = 2;
    end
    
    if hoveredPt
      ptsOrder(hoveredPt,2) = 3;
    end
    
    ptsOrder = sortrows(ptsOrder, 2)';
    
    for i = ptsOrder(1,:)
      if i == curPt
        alpha = 1;
      elseif i == hoveredPt
        alpha = 0.75;
      else
        alpha = 0.5;
      end
      
      ptX = curLine.points(i,X) + imLeft;
      ptY = currentY;
      Screen('DrawDots', window, [ptX ptY], ptRad*2, ...
             [types(curLine.points(i,TYPE)).color alpha]*255, [0 0], 2);
    end
    
    Screen('Flip', window);
    
    lastKeyCodes = keyCodes;
    [keyDown secs keyCodes] = KbCheck;
    
    if keysWereReleased(nextLineKey);
      lines(lineOrder(indx)) = curLine;
      indx = indx + 1;
      
      if indx > nLines
        break;
      end
      
      curLine = lines(lineOrder(indx));
      nPts = size(curLine.points, 1);
      validXs = find(flippedMask(curLine.y + 1,:)) - 1;
      minX = min(validXs);
      maxX = max(validXs);
      
      curPt = 0;
    end
    
    if keysWereReleased(nextPtKey)
      if nPts
        curPt = curPt + ~keysAreDown(shiftKey) - keysAreDown(shiftKey);

        if curPt > nPts
          curPt = 1;
        end
        
        if curPt < 1
          curPt = nPts;
        end
      end
    end
    
    if keysWereReleased(deleteKey)
      if curPt
        curLine.points = curLine.points((1:nPts) ~= curPt,:);
        nPts = nPts - 1;
        curPt = 0;
      end
    end
    
    if keysWereReleased(numberKey)
      type = find(lastKeyCodes(numberKey), 1);
      
      if type <= nTypes
        addPt(type);
      end
    end
    
    if keysAreDown([moveLeftKey moveRightKey])
      off = keysAreDown(moveRightKey) - keysAreDown(moveLeftKey);
      
      if curPt
        newX = curLine.points(curPt,X) + off;
        newX = max(minX, min(newX, maxX));
        curLine.points(curPt,X) = newX;
      end
    end

    if keysAreDown(quitKey)
      lines(lineOrder(indx)) = curLine;
      break;
    end
    
    lastX = x;
    lastY = y;
    lastButtons = buttons;
    [x y buttons] = GetMouse(window); y = winHeight - y - 1;
    handleMouseInput;
  end

  ListenChar(0);
  
  if close
    Screen('Close', window);
  end
  
  function addPt(type)    
    nPts = nPts + 1;
    curLine.points(nPts,:) = [round((minX + maxX)/2) type];
  end
  
  function handleMouseInput
    hasMoved = lastX ~= x || lastY ~= y;
    relX = x - imLeft;
    relY = y - imBottom;
    
    if buttons(1)
      if ~lastButtons(1)
        if hoveredPt
          curPt = hoveredPt;
        else
          typeDistsSquared = (x - typesCentersX).^2 + (y - typesCentersY).^2;
          [minDist minIndx] = min(typeDistsSquared);
          if minDist < typesRad^2
            addPt(minIndx);
          end
        end
      else
        if hasMoved
          if hoveredPt
            curLine.points(hoveredPt,X) = max(minX, min(relX, maxX));
          end
        end
      end
    else
      if ~isempty(curLine.points)
        distsSquared = (curLine.points(:,X) - relX).^2 + (curLine.y - relY).^2;
        [minDist minIndx] = min(flipud(distsSquared));
        if minDist < ptRad^2
          hoveredPt = nPts - minIndx + 1;
        else
          hoveredPt = 0;
        end
      end
    end
  end
  
  function yesno = keysAreDown(keys)
    yesno = any(keyCodes(keys));
  end

  function yesno = keysWereReleased(keys)
    yesno = ~any(keyCodes(keys)) && any(lastKeyCodes(keys));
  end
end