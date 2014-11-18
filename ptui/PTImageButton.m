classdef PTImageButton < PTButton
  properties (Access = protected)
    ComponentViews
    Tightness = 20
    Sizeable
  end
  
  methods
    function obj = PTImageButton(window, pos, fileBase, contents, tightness)
      images = PTImageButton.loadImages(fileBase);
      
      w = sum(cellfun(@(x) x.Width, images(1,:)));
      h = images{1,1}.Height;
      rect = [pos, pos + [w h]];
      
      obj = obj@PTButton(window, rect, contents, PTTextFormat(24));
      obj.DepressedOffset = [0 1];
      
      obj.Sizeable = size(images, 2) > 1;
      
      if exist('tightness', 'var')
        obj.Tightness = tightness;
      end
      
      for i = 1:numel(images)
        if ~isempty(images{i})
          obj.ComponentViews{i} = PTImageView(obj.Window, pos, images{i});
        else
          obj.ComponentViews{i} = [];
        end
      end
      
      obj.ComponentViews = reshape(obj.ComponentViews, size(images));
      obj.autosize;
    end
    
    function render(obj)
      if obj.Enabled
        if obj.Depressed % && ~isempty(obj.ComponentViews{2})
          cellfun(@(v) v.render, obj.ComponentViews(2,:));
        elseif obj.Hovered % && ~isempty(obj.ComponentViews{3})
          cellfun(@(v) v.render, obj.ComponentViews(3,:));
        else
          cellfun(@(v) v.render, obj.ComponentViews(1,:));
        end
      else
        cellfun(@(v) v.render, obj.ComponentViews(4,:));
      end
      
      obj.renderContents;
    end
    
    function viewReshaped(obj, source, event)
      obj.viewReshaped@PTButton(source, event);
      obj.layoutButtonComponents;
    end
    
    function autosize(obj)
      if obj.Sizeable
        obj.Width = max(RectWidth(obj.ContentsBounds) - obj.Tightness, 0) + ...
                    obj.ComponentViews{1,1}.Width + ...
                    obj.ComponentViews{1,3}.Width;
      end
    end
  end
  
  methods (Access = protected)
    function layoutButtonComponents(obj)
      w = obj.Width;
      p = obj.Pos;
      
      for i = 1:size(obj.ComponentViews, 1)
        obj.ComponentViews{i,1}.Pos = p;
        
        if obj.Sizeable
          lw = obj.ComponentViews{i,1}.Width;
          rw = obj.ComponentViews{i,3}.Width;
          obj.ComponentViews{i,2}.Pos = [p(1) + lw, p(2)];
          obj.ComponentViews{i,2}.Width = max(w - lw - rw, 0);
          obj.ComponentViews{i,3}.Pos = [p(1) + lw + obj.ComponentViews{i,2}.Width, p(2)];
        end
      end
    end
  end
  
  methods (Static, Access = protected)
    function images = loadImages(baseName)
      [path name ext] = fileparts(baseName);
      
      dirListing = dir(path);
      dirListing = {dirListing.name};
      fmt = [name '-(?<state>up|down|over|disabled)-(?<component>left|middle|right|full)\' ext];
      matches = regexp(dirListing, fmt, 'names');
      matchIndices = find(~cellfun('isempty', matches));

      if isempty(matchIndices)
        error(['Could not find any files derived from ' name '.']);
      end

      numMatches = length(matchIndices);
      
      if numMatches == 16
        numMatches = 12;
      end
      
      if numMatches ~= 12 && numMatches ~= 4
        error('Incorrect number of images supplied for button states/components');
      end
      
      sizeable = numMatches > 4;
      images = cell(4, numMatches/4);
      
      imIndx = 1;
      indxMap = struct('up', 1, 'down', 2, 'over', 3, 'disabled', 4, ...
                       'full', 1, 'left', 1, 'middle', 2, 'right', 3);
      for i = matchIndices
        if sizeable && strcmp(matches{i}.component, 'full')
          continue;
        end
        
        image = PTImage([path filesep dirListing{i}]);
        images{indxMap.(matches{i}.state), indxMap.(matches{i}.component)} = image;
        imIndx = imIndx + 1;
      end
    end
  end
end
