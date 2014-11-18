classdef PTContainerView < PTView
  properties
    Transparent = false
    DrawBackground = false
    BackgroundColor = [0 0 0 0]
  end
  
  properties (SetAccess = protected)
    Views
  end
  
  properties (Transient, Access = protected)
    MoveSubviewsOnReshape = true
    ReshapedListeners = event.listener.empty
    SubviewReshapedListeners = event.listener.empty
  end
  
  events
    SubviewReshaped
  end
  
  methods
    function obj = PTContainerView(window, rect, views)
      obj = obj@PTView(window, rect);
      obj.Views = {};
      obj.addViews(views);
      
      addlistener(obj, 'ViewReshaped', @obj.viewReshaped);
    end
    
    function addViews(obj, views, where)
      if ~exist('views', 'var')
        views = {};
      end
      
      if ~iscell(views)
        views = {views};
      end
      
      for i = 1:numel(views)
        if views{i}.Window ~= obj.Window
          error('A subview cannot be added to a container view in a different window.');
        end
        
        if obj == views{i}
          error('A view cannot be added to itself!  You have been bad.  Very very bad.');
        end
        
        obj.ReshapedListeners(end + 1) = event.listener(views{i}, 'ViewReshaped', @obj.subviewReshaped);
        
        if isa(views{i}, 'PTContainerView')
          obj.SubviewReshapedListeners(end + 1) = event.listener(views{i}, 'SubviewReshaped', @obj.subviewReshaped);
        end
      end

      if ~exist('where', 'var') || strcmpi(where, 'end')
        obj.Views = {obj.Views{:} views{:}}; %#ok<*CCAT>
      elseif isnumeric(where)
        obj.Views = {obj.Views{1:where - 1} views{:} obj.Views{where:end}};
      end
    end
    
    function replaceViews(obj, viewsToReplace, replacementViews)
      if numel(viewsToReplace) ~= numel(replacementViews)
        error('The number of views you are replacing must match the number of replacement views.');
      end
      
      if ~iscell(replacementViews)
        replacementViews = {replacementViews};
      end
      
      removed = obj.removeViews(viewsToReplace);
      for i = 1:length(removed)
        obj.addViews(replacementViews{i}, removed(i));
      end
    end
    
    function removed = removeViews(obj, views)
      if ~iscell(views)
        views = {views};
      end
      
      toRemove = false(1, numel(obj.Views));
      subviewReshapedListenersToRemove = false(size(obj.SubviewReshapedListeners));
      n = 0;
      for i = 1:numel(obj.Views)
        if isa(obj.Views{i}, 'PTContainerView')
          n = n + 1;
          isContainer = true;
        else
          isContainer = false;
        end
        
        for j = 1:numel(views)
          if views{j} == obj.Views{i}
            toRemove(i) = true;
            
            if isContainer
              subviewReshapedListenersToRemove(n) = true;
            end
          end
        end
      end
      
      obj.Views(toRemove) = [];
      obj.ReshapedListeners(toRemove) = [];
      obj.SubviewReshapedListeners(subviewReshapedListenersToRemove) = [];
      
      if nargout > 0
        removed = find(toRemove);
      end
    end
    
    function render(obj)
      if obj.DrawBackground
        Screen('FillRect', obj.Window, obj.BackgroundColor*255, obj.Rect);
      end
      
      for i = 1:numel(obj.Views)
        if obj.Views{i}.Visible
          obj.Views{i}.render;
        end
      end
    end
    
    function viewReshaped(obj, source, event) %#ok<INUSL>
      if obj.MoveSubviewsOnReshape
        offset = event.NewRect(1:2) - event.OldRect(1:2);
        if any(offset)
          for i = 1:numel(obj.Views)
            obj.Views{i}.Pos = obj.Views{i}.Pos + offset;
          end
        end
      end
    end
    
    function subviewReshaped(obj, source, event)
      if isa(event, 'PTSubviewReshapedEvent')
        source = event.SourceView;
      end
      
      notify(obj, 'SubviewReshaped', PTSubviewReshapedEvent(source, event.OldRect, event.NewRect));
    end
    
    function view = viewUnderPoint(obj, pos)
      view = 0;
      
      for i = numel(obj.Views):-1:1 % Do this backwards so that front-most drawn views are tried first
        v = obj.Views{i};
        
        if v.Visible && v.Enabled
          if isa(v, 'PTContainerView')
            view = v.viewUnderPoint(pos);
          elseif ptPtInRect(pos, v.Rect)
            view = v;
          end
          
          if view ~= 0
            break;
          end
        end
      end
      
      if view == 0 && ~obj.Transparent && ptPtInRect(pos, obj.Rect)
        view = obj;
      end
    end
    
    function dispatchEventThroughSubviews(obj, eventName, data)
      for i = 1:numel(obj.Views)
        if obj.Views{i}.Visible && obj.Views{i}.Enabled
          if isa(obj.Views{i}, 'PTContainerView')
            obj.Views{i}.dispatchEventThroughSubviews(eventName, data);
          end
          
          notify(obj.Views{i}, eventName, data);
        end
      end

      notify(obj, eventName, data);
    end
  end
end
