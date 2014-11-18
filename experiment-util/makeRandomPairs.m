function pairs = makeRandomPairs(shapeData, stims, varargin)
%MAKERANDOMPAIRS Make random dot pairs for a depth discrimination task.
%   PAIRS = MAKERANDOMPAIRS(SD, STIMS, ...)
%   creates a random set of dot pairs for the stimuli STIMS, for use in a
%   depth comparison procedure.
%
%   SD should be an array of shape data structures, as returned by
%   makeShapeData.
%
%   STIMS should be a structure array, with (at least) the fields
%   'shapeIndx'.
%
%   Subsequent arguments are 'Param', Value pairs:
%
%     'NPairsPerDepthDiff' specifies the number of dot pairs to create per
%     "depth difference category" (see ND).
%
%     'NDepthLevels' is the number of depth levels to divide the depthmap
%     into when creating dot pairs.  A value of 3, for instance, leads to 5
%     distinct "depth difference categories": one where the first dot is
%     two levels in front of the second (-2), one where it is one level in
%     front of the second (-1), etc (until it is two levels behind the
%     second dot).  Thus for a given value of ND, there will be 2*ND - 1
%     discrete depth difference categories.
%
%     'MinLateralDist' specifies the minimum lateral distance that must
%     separate the two dots, in pixels (this is to prevent dots lying
%     pretty much on top of one another).
%
%     'MaxLateralDist' specifies the maximum lateral distance that can
%     separate the two dots, in pixels.
%
%     'MinDistFromContour' specifies the minimum distance from the contour
%     for the two dots.
%
%     'DepthDiffs' should be a list of the depth differences for which to
%     generate pairs.  This defaults to 1 - ND:ND - 1 (i.e. generate pairs
%     for all possible depth difference categories).
%
%   PAIRS, the output, will be a struct array with the following fields:
% 
%     'stimIndx' - an index into the stims array specifying which stimulus
%     the pair was created for.
%
%     'pairSubscripts' - the subscripts of the dot pairs, as a 1 x 4
%     matrix, where the first two elements are the subscripts of the first
%     dot, and the second two elements are the subscripts of the second
%     dot.  The subscript values are indices into the depthmap used to
%     generate the pair (i.e., stims(pairs(i).stimIndx).depths), with the
%     first subscript being the row index, and the second subscript the
%     column index.
%
%     'depthCondition' - the depth condition for which this pair was
%     generated (see ND and DS above for a description of depth difference
%     categories).
%
%     'groundTruth' - which point has lower depth.  This is 1 if the first
%     dot is closer, and 2 if the second dot is closer.
%
%   See also DepthComparisons.

parsearglist({'nPairsPerDepthDiff', 'nDepthLevels', 'minLateralDist', 'maxLateralDist', ...
              'minDistFromContour', 'minDistFromRefPt', 'maxDistFromRefPt', ...
              'depthDiffs', 'levelEpsilon', 'sameDistFromRefPt', 'chooseMaxDepthDiff', ...
              'refPtMethod', 'sameDistFromContour'}, varargin);
argdefaults('nPairsPerDepthDiff', 2, 'nDepthLevels', 3, 'minLateralDist', 15, 'maxLateralDist', inf, ...
            'minDistFromContour', 0, 'maxDistFromRefPt', inf, 'minDistFromRefPt', 0, ...
            'sameDistFromRefPt', false, 'chooseMaxDepthDiff', false, 'sameDistFromContour', false);
argdefaults('depthDiffs', 1 - nDepthLevels:nDepthLevels - 1);

if ~exist('refPtMethod', 'var')
  if sameDistFromRefPt || minDistFromRefPt || isfinite(maxDistFromRefPt)
    refPtMethod = 'maxfromcontour';
  else
    refPtMethod = 'none';
  end
end

calcContourDists = minDistFromContour || sameDistFromContour || strcmpi(refPtMethod, 'maxfromcontour');

nPairs = nPairsPerDepthDiff*length(depthDiffs);
pairs = repmat(struct('stimIndx', [], ...
                      'pairSubscripts', [], ...
                      'depthCondition', [], ...
                      'groundTruth', [], ...
                      'refPt', []), nPairs, 1);

nStims = numel(stims);
maxDepths = zeros(nStims, 1);
minDepths = zeros(nStims, 1);

for t = 1:nStims
  shape = shapeData(stims(t).shapeIndx);
  validDepths = shape.depths(shape.mask);
  maxDepths(t) = max(validDepths);
  minDepths(t) = min(validDepths);
end

minAbsDepthDiff = min(maxDepths - minDepths);
meanDepths = (maxDepths + minDepths)/2;

chunkSize = minAbsDepthDiff/(nDepthLevels + 1);

if ~exist('levelEpsilon', 'var') && nDepthLevels > 1
  levelEpsilon = chunkSize/4;
else
  levelEpsilon = inf;
end

depthDiffMat = bsxfun(@minus, (1:nDepthLevels)', 1:nDepthLevels);

indx = 0;
for t = 1:nStims
  shape = shapeData(stims(t).shapeIndx);
  
  levelCenters = meanDepths(t) - (nDepthLevels - 1)/2*chunkSize + (0:nDepthLevels - 1)*chunkSize;
  strata = abs(bsxfun(@minus, shape.depths, shiftdim(levelCenters, -1))) < levelEpsilon;
  strata = bsxfun(@and, strata, shape.mask);
  inds = cell(nDepthLevels, 1);

  if calcContourDists
    edgePoints = edge(shape.mask, 'log');
    [edgeIs, edgeJs] = find(edgePoints);
    [imIs, imJs] = find(shape.mask);
    distList = mindist(imIs(:), imJs(:), edgeIs(:), edgeJs(:), true);
    contourDists = nan(size(shape.mask));
    contourDists(shape.mask) = distList;
  end

  for i = 1:nDepthLevels
    [is, js] = find(strata(:,:,i));
    inds{i} = [is js];
  end
  
  if strcmpi(refPtMethod, 'maskmean')
    [is, js] = find(shape.mask);
    refPt = mean([is js]);
  elseif strcmpi(refPtMethod, 'maxfromcontour')
    refPt = [0 0];
    [ignore, maxIndx] = max(contourDists(:));
    [refPt(1), refPt(2)] = ind2sub(size(contourDists), maxIndx);
  else
    refPt = [];
  end

  for diff = depthDiffs
    [firstDotLevels, secondDotLevels] = find(depthDiffMat == diff);
    
    for indx = indx + 1:indx + nPairsPerDepthDiff
      if isempty(firstDotLevels)
        break;
      end
      
      levelIndx = ceil(rand*length(firstDotLevels));
      firstDotInds = inds{firstDotLevels(levelIndx)};
      secondDotInds = inds{secondDotLevels(levelIndx)};
      validFirstDotDists = true(length(firstDotInds), 1);

      if minDistFromRefPt > 0 || maxDistFromRefPt < inf
        distsFromRefPt = sqrt(sum(bsxfun(@minus, firstDotInds, refPt).^2, 2));
        validFirstDotDists = validFirstDotDists & distsFromRefPt > minDistFromRefPt & distsFromRefPt < maxDistFromRefPt;
      end

      if minDistFromContour
        firstDotDistsFromContour = contourDists(sub2ind(size(contourDists), firstDotInds(:,1), firstDotInds(:,2)));
        validFirstDotDists = validFirstDotDists & firstDotDistsFromContour > minDistFromContour;
      end

      firstDotInds = firstDotInds(validFirstDotDists,:);

      randIndxs = Shuffle(1:size(firstDotInds, 1));
      done = false;
      passes = 1;
      for randIndx = randIndxs
        pairs(indx).pairSubscripts(1:2) = firstDotInds(randIndx,:);

        validSecondDotDists = true(length(secondDotInds), 1);

        if minLateralDist > 0 || maxLateralDist < inf
          distsFromFirstDot = sum((bsxfun(@minus, secondDotInds, pairs(indx).pairSubscripts(1:2))).^2, 2);
          validSecondDotDists = validSecondDotDists & distsFromFirstDot > minLateralDist^2 & distsFromFirstDot < maxLateralDist^2;
        end

        if minDistFromRefPt > 0 || maxDistFromRefPt < inf || sameDistFromRefPt
          distsFromRefPt = sum(bsxfun(@minus, secondDotInds, refPt).^2, 2);
          
          if minDistFromRefPt > 0 || maxDistFromRefPt < inf
            validSecondDotDists = validSecondDotDists & distsFromRefPt > minDistFromRefPt^2 & distsFromRefPt < maxDistFromRefPt^2;
          end
          
          if sameDistFromRefPt
            firstDotDistFromRefPt = sqrt(sum((pairs(indx).pairSubscripts(1:2) - refPt).^2));
            validSecondDotDists = validSecondDotDists & abs(sqrt(distsFromRefPt) - firstDotDistFromRefPt) < sameDistFromRefPt;
          end
        end

        if minDistFromContour || sameDistFromContour
          secondDotDistsFromContour = contourDists(sub2ind(size(contourDists), secondDotInds(:,1), secondDotInds(:,2)));
          
          if minDistFromContour
            validSecondDotDists = validSecondDotDists & secondDotDistsFromContour > minDistFromContour;
          end
          
          if sameDistFromContour
            firstDotDistFromContour = contourDists(pairs(indx).pairSubscripts(1), pairs(indx).pairSubscripts(2));
            validSecondDotDists = validSecondDotDists & abs(secondDotDistsFromContour - firstDotDistFromContour) < sameDistFromContour;
          end
        end

        if any(validSecondDotDists)
          validInds = secondDotInds(validSecondDotDists,:);
          
          d1 = shape.depths(pairs(indx).pairSubscripts(1), pairs(indx).pairSubscripts(2));
          
          if chooseMaxDepthDiff
            [ignore, dstIndx] = max(abs(d1 - shape.depths(sub2ind(size(shape.depths), validInds(:,1), validInds(:,2)))));
          else
            dstIndx = ceil(rand*size(validInds, 1));
          end
          
          pairs(indx).pairSubscripts(3:4) = validInds(dstIndx,:);
          d2 = shape.depths(pairs(indx).pairSubscripts(3), pairs(indx).pairSubscripts(4));

          if diff == 0 && mod(indx - 1, nPairsPerDepthDiff) > 0 && ...
             (d1 < d2 && pairs(indx - 1).groundTruth == 1 || ...
              d2 < d1 && pairs(indx - 1).groundTruth == 2)
            tmp = d1;
            d2 = d1;
            d1 = tmp;
            pairs(indx).pairSubscripts = pairs(indx).pairSubscripts([3 4 1 2]);
          end

          if d1 < d2
            pairs(indx).groundTruth = 1;
          elseif d2 < d1
            pairs(indx).groundTruth = 2;
          else % d1 == d2
            pairs(indx).groundTruth = mod(2*pairs(indx - 1).groundTruth, 3); % Turns 1 into 2, 2 into 1
          end

          if diff < 0 && pairs(indx).groundTruth ~= 1 || diff > 0 && pairs(indx).groundTruth ~= 2
            error('I''m a moron and this is my wife.');
          end

          pairs(indx).stimIndx = t;
          pairs(indx).depthCondition = diff;
          pairs(indx).refPt = refPt;
          done = true;
          break;
        else
          passes = passes + 1;
        end
      end
      
      if ~done
        firstDotLevels(levelIndx) = [];
        secondDotLevels(levelIndx) = [];
      end
    end

    if ~done
      error('Couldn''t find a random pair for depth difference %d in stimulus %d', diff, t);
    end
  end
end
