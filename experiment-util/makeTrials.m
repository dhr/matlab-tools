function [trials, order] = makeTrials(stims, pairs, nPairReps, typesToUse, typeIndxsToUse, ...
                                      consecutiveStimGap, typeOrder, randomlyRotateStims, ...
                                      stimOrder, stimList, shufflePairs)

nStims = length(stims);
nTypesToUse = length(typesToUse);

argdefaults('consecutiveStimGap', floor(nStims/2), 'typeOrder', [], 'randomlyRotateStims', false, ...
            'stimOrder', [], 'stimList', [], 'shufflePairs', true);

if isempty(typeOrder)
  typeOrder = 1:nTypesToUse;
  shuffleTypes = true;
else
  typeOrder = typeOrder(end:-1:1); % Reverse it because the stim types get picked off a stack (so in reverse).
  shuffleTypes = false;
end

if isempty(stimOrder)
  shuffleStims = true;
else
  shuffleStims = false;
end

for i = 1:nTypesToUse
  if ~isfield(typeIndxsToUse, typesToUse{i})
    typeIndxsToUse.(typesToUse{i}) = 1;
  end
end

trials = struct('stimIndx', [], 'stimType', [], ...
                'typeIndx', [], 'pairIndx', [], ...
                'response', [], 'responseTime', [], ...
                'flipColor', false);

if isempty(stimList)
  stimList = 1:nStims;
else
  stimList = stimList(:)';
end

nStimsToUse = length(stimList);

stimIndxs = vertcat(pairs.stimIndx);
stimStacks = cell(1, nStims);

indx = 1;
for s = stimList
  pairsToUse = stimIndxs == s;
  pairsToUseIndxs = find(pairsToUse);
  nPairsToUse = length(pairsToUseIndxs);
  dupedPairIndxs = num2cell(repmat(pairsToUseIndxs, nPairReps, 1));
  flipPairColor = repmat(mod(1:nPairReps, 2) == 0, nPairsToUse, 1);
  flipPairColor = num2cell(flipPairColor(:));
  
  for t = 1:nTypesToUse
    nSpecifics = length(typeIndxsToUse.(typesToUse{t}));
    nPairs = nPairsToUse*nPairReps;
    nTrials = nPairs*nSpecifics;
    indices = indx:indx + nTrials - 1;
    [trials(indices).stimIndx] = deal(s);
    [trials(indices).stimType] = deal(typesToUse{typeOrder(t)});
    if shufflePairs
      pairOrder = Shuffle(1:nPairs);
    else
      pairOrder = 1:nPairs;
    end
    [trials(indices).pairIndx] = dupedPairIndxs{repmat(pairOrder, nSpecifics, 1)};
    [trials(indices).flipColor] = flipPairColor{repmat(pairOrder, nSpecifics, 1)};
    stimStacks{s} = [stimStacks{s} indices];
    for i = 1:nSpecifics
      indices = indx + (i - 1)*nPairs:indx + i*nPairs - 1;
      [trials(indices).typeIndx] = deal(typeIndxsToUse.(typesToUse{t})(i));
    end
    indx = indx + nTrials;
  end
end

nTrials = length(trials);
order = zeros(nTrials, 1);
recentStims = zeros(consecutiveStimGap, 1);
pickedYet = false(1, nStims);

if islogical(randomlyRotateStims)
  if randomlyRotateStims
    randomlyRotateStims = [0 2*pi];
  else
    randomlyRotateStims = [0 0];
  end
elseif ~isnumeric(randomlyRotateStims) && length(randomlyRotateStims) == 2
  error('Unknown randomlyRotateStims format.');
end

angles = ...
  rand(nTrials, 1)*(randomlyRotateStims(2) - randomlyRotateStims(1)) + ...
    randomlyRotateStims(1);
angles = mat2cell(angles, ones(nTrials, 1));
[trials.angle] = angles{:};

if shuffleTypes
  for i = stimList
    stimStacks{i} = Shuffle(stimStacks{i});
  end
end

stimsLeft = nStimsToUse - nnz(cellfun(@isempty, stimStacks(stimList)));
if shuffleStims
  for i = 1:nTrials
    validStims = ~ismember(stimList, recentStims) & ~pickedYet(stimList) & ~cellfun(@isempty, stimStacks(stimList));
    if ~any(validStims)
      error('The consecutive stimulus gap argument is set too high, and the requirement cannot be met.  Lower it.');
    else
      stack = Sample(stimList(validStims));
    end

    if consecutiveStimGap
      recentStims(mod(i - 1, consecutiveStimGap) + 1) = stack;
    end

    order(i) = stimStacks{stack}(end);
    stimStacks{stack}(end) = [];
    pickedYet(stack) = true;
    if ~mod(i, stimsLeft)
      pickedYet(:) = false;
      stimsLeft = nStimsToUse - nnz(cellfun(@isempty, stimStacks(stimList)));
    end
  end
else
  indx = 1;
  for i = 1:length(stimOrder)
    nStims = length(stimStacks{stimOrder(i)});
    order(indx:indx + nStims - 1) = stimStacks{stimOrder(i)}(:);
    indx = indx + nStims;
  end
end
