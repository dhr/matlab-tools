function stimuli = makeODTStimuli(shapeData, typeCreators, params, typeIDs, window)
%MAKEODTSTIMULI Makes a set of ODT stimuli.
%   STIMS = MAKEODTSTIMULI(SD, CREATORS, PARAMS, TYPEIDS, WINDOW) creates a
%   set of ODT stimuli using the shape data in SD and the creator functions
%   in CREATORS.
%
%   SD should be an array of shape data structs as returned by
%   MAKESHAPEDATA.
%
%   CREATORS should be a cell array of function handles (if only one
%   creator is used it needn't be wrapped in a cell array). See all of the
%   CREATE*IMG functions for different creator functions. These creators
%   will be run for each shape data structure.
%
%   PARAMS should be a cell array of cell arrays providing a parameter set
%   to each of the creator functions in CREATORS. Defaults to {{}}.
%
%   TYPEIDS should be a cell array of names corresponding to the creator
%   functions. These names will be used as the fields of the STIMS output.
%   Defaults to {'odt'}.
%
%   WINDOW is a matrix which windows the output of the creator functions
%   (i.e. acts as a multiplicative mask). Can also be false to prevent
%   windowing altogether. Defaults to the mask of the current shape
%   provided in the shape data structure.
%   
%   STIMS will be a an array of structs. Each element of the array will
%   have the fields 'shapeIndx' (an index into the shape data array),
%   'mask' (the mask of the object from the shape data array), and fields
%   corresponding to the output of the creators using names provided by the
%   TYPEIDS argument (each of these fields will be either a structure or an
%   array of structures containing at least the field 'img', which contains
%   the actual stimulus image).
%
%   See also MAKESHAPEDATA.

  stimuli = repmat(struct, length(shapeData), 1);
  
  argdefaults('params', {{}}, 'typeIDs', {'odt'});
  
  if ~iscell(typeCreators)
      typeCreators = {typeCreators};
  end
  
  if isempty(params) || (length(params) == 1 && ~iscell(params{1}))
      params = {params};
  end
  
  if ~iscell(typeIDs)
      typeIDs = {typeIDs};
  end
  
  performWindowing = nargin < 5 || ~isscalar(window) || ~islogical(window) || window;
  
  for i = 1:length(shapeData)
    sd = shapeData(i);
    
    if nargin < 5 || (isscalar(window) && islogical(window) && window)
      window = sd.mask;
    end
    
    for j = 1:length(typeCreators)
      stimImg = typeCreators{j}(sd, params{j}{:});
      
      if performWindowing
        for k = 1:length(stimImg)
          stimImg(k).img = bsxfun(@times, stimImg(k).img, window);
        end
      end
      
      stimuli(i).shapeIndx = i;
      stimuli(i).mask = sd.mask;
      stimuli(i).(typeIDs{j}) = stimImg;
    end
  end
end