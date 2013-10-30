classdef PTLinearLayoutContainer < PTContainerView
  properties
    Direction = 1
    Spacing = 0
    Padding = [0 0 0 0]
    Gravity1 = 'center'
    Gravity2
    FitToContents = true
  end
  
  properties (Constant)
    HORIZONTAL = 1
    VERTICAL = 2
  end
  
  methods
    function obj = PTLinearLayoutContainer(window, rect, views, dir, spacing, grav1, grav2)
      if ~exist('views', 'var')
        views = {};
      end
      
      obj = obj@PTContainerView(window, rect, views);
      
      if exist('dir', 'var')
        obj.Direction = dir;
      end
      
      if exist('spacing', 'var')
        obj.Spacing = spacing;
      end
      
      if exist('grav1', 'var')
        obj.Gravity1 = grav1;
      end
      
      if exist('grav2', 'var')
        obj.Gravity2 = grav2;
      else
        obj.Gravity2 = [];
      end
    end
    
    function doLayout(obj)
      numViews = numel(obj.Views);
      
      if numViews == 0
        return;
      end
      
      rects = zeros(numViews, 4);
      
      rects(1,:) = obj.Views{1}.Rect;
      totalRect = rects(1,:);
      
      side = obj.Direction + 2; % See RectRight, RectBottom
      offset = repmat([0 0], numViews - 1, 1);
      
      if ischar(obj.Spacing) && strcmpi(obj.Spacing, 'flexible') && numViews > 1
        totalDim = 0;
        for i = 1:numViews
          totalDim = totalDim + obj.Views{i}.Dimensions(obj.Direction);
        end
        
        diff = obj.Dimensions(obj.Direction) - totalDim;
        diff = diff - obj.Padding(obj.Direction) - obj.Padding(obj.Direction + 2);
        for i = 1:(numViews - 1)
          amt = max(round(diff/(numViews - i)), 0);
          diff = diff - amt;
          offset(i,obj.Direction) = amt;
        end
      else
        offset(:,obj.Direction) = obj.Spacing;
      end
      
      aligns = {obj.Gravity1};
      if ~isempty(obj.Gravity2)
        aligns{2} = obj.Gravity2;
      end
      
      for i = 2:numViews
        rect = obj.Views{i}.Rect;
        rect = AlignRect(rect, totalRect, aligns{:});
        rect = AdjoinRect(rect, totalRect, side);
        rect = OffsetRect(rect, offset(i - 1,1), offset(i - 1,2));
        rects(i,:) = rect;
        totalRect = UnionRect(totalRect, rect);
      end
      
      positionedRect = AlignRect(totalRect, obj.Rect, aligns{:});
      offset = positionedRect(1:2) - totalRect(1:2);
      
      if obj.FitToContents
        obj.MoveSubviewsOnReshape = false;
        obj.Rect = positionedRect + [-obj.Padding(1:2), obj.Padding(3:4)];
        obj.MoveSubviewsOnReshape = true;
      end
      
      for i = 1:numViews
        rects(i,:) = OffsetRect(rects(i,:), offset(1), offset(2));
        obj.Views{i}.Rect = rects(i,:);
      end
    end
  end
end
