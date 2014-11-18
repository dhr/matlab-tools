function [gamma, rgbCoeffs] = ColorCalibrate(window, gamma, doColor, reps)

close = false;
if ~exist('window', 'var') || isempty(window)
  close = true;
  window = Screen('OpenWindow', 0, [0 0 0]);
end

if ~exist('gamma', 'var')
  gamma = [];
end

if ~exist('doColor', 'var')
  doColor = true;
end

if ~exist('reps', 'var')
  reps = 1;
end

winRect = Screen('Rect', window);
w = winRect(3);
h = winRect(4);

if isempty(gamma)
  nStripes = 20;
  stripes = sin(linspace(0, nStripes*pi, w)) > 0;
  alternating = mod(1:w, 2);
  lumDisplay = alternating.*stripes + 0.5.*~stripes;
  
  for j = 1:reps
    invGamma = rand(1, 3)*0.9 + 0.1;
    for i = 1:3
      buttons = [];
      displayImg = cat(3, lumDisplay, zeros([size(lumDisplay) 2]));
      displayImg = circshift(displayImg, [0 0 i - 1]);

      [ignore, y] = GetMouse(window);
      SetMouse(w/2, ceil(invGamma(i)*h), window);
      while ~any(buttons)
        Screen('PutImage', window, 255*displayImg.^invGamma(i), winRect);
        Screen('Flip', window);

        [ignore, y, buttons] = WaitForMouse(window);
        invGamma(i) = bound(2*(y + 1)/h, 0, 2);
      end
      
      while any(buttons)
        [ignore, ignore, buttons] = GetMouse(window);
        WaitSecs(0.05);
      end
    end

    gamma(j,:) = 1./invGamma;
  end
  gamma = median(gamma, 1);
end

if doColor
  alpha = makeSmoothedRotatedCircleGrating(3*pi/16, pi/8, 200, 0);
  imgRect = [0 0 fliplr(size(alpha))];
  dstRect = CenterRect(imgRect, winRect);
  blank = ones(size(alpha));
  tex1 = Screen('MakeTexture', window, 255*cat(3, blank, 1 - alpha));
  tex2 = Screen('MakeTexture', window, 255*cat(3, blank, alpha));
  
  rgbCoeffs = zeros(reps, 3);
  for i = 1:reps
    [cr, cg] = colorLoop([1 0 0], [0 1 0]);
    [cy, cb] = colorLoop([1 1 0], [0 0 1]);
    rgbCoeffs(i,:) = [1 cr/cg cy*(1 + cr/cg)/cb];
  end
  rgbCoeffs = mean(rgbCoeffs, 1);
  rgbCoeffs = rgbCoeffs/sum(rgbCoeffs);
  
  Screen('Close', [tex1, tex2]);
end

if close
  Screen('Close', window);
end

function [coeff1, coeff2] = colorLoop(inds1, inds2)
  inds1 = logical(inds1);
  inds2 = logical(inds2);
  coeff1 = 1;
  coeff2 = 1;
  
  if any(inds1 & inds2)
    error('Channel indices should be disjoint.');
  end
  
  Screen('BlendFunction', window, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
  
  buttons = [];
  while ~any(buttons)
    if isempty(buttons)
      [ignore, y, buttons] = GetMouse(window);
      y = ceil(rand*h);
      SetMouse(w/2, y, window);
    else
      [ignore, y, buttons] = GetMouse(window);
    end
    
    if y <= h/2
      coeff2 = ((y + 1)/(h/2));
      coeff1 = 1;
    else
      coeff1 = (2 - y/(h/2));
      coeff2 = 1;
    end
    
    color1 = 255*(coeff1*inds1).^(1./gamma);
    color2 = 255*(coeff2*inds2).^(1./gamma);
    Screen('DrawTexture', window, tex1, imgRect, dstRect, 0, 0, 1, color1);
    Screen('DrawTexture', window, tex2, imgRect, dstRect, 0, 0, 1, color2);
    Screen('Flip', window);
    WaitSecs(1/60);
  end
      
  while any(buttons)
    [ignore, ignore, buttons] = GetMouse(window);
    WaitSecs(0.05);
  end
end

function alpha = makeSmoothedRotatedCircleGrating(rot1, rot2, rad, sigma)
  grating1 = makeGrating([h w], 30, rot1);
  grating2 = makeGrating([h w], 30, rot2);
  [xs, ys] = meshgrid(linspace(-w/2, w/2, w), linspace(h/2, -h/2, h));
  inCircle = xs.^2 + ys.^2 < rad^2;
  grating = double((grating1.*~inCircle + grating2.*inCircle) > 0);
  if sigma > 0
    grating = imfilter(grating, fspecial('gaussian', ceil(6*sigma), sigma), 'replicate');
  end
  alpha = grating > 0.5;
end

function alpha = getNamedImage(imgName) %#ok<*DEFNU>
  imgPath = fullfile(fileparts(mfilename('fullpath')), imgName);
  alpha = double(readGray(imgPath) > 0.5);
end

end
