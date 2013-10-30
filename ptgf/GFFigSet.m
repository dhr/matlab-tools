classdef GFFigSet < handle
  properties (SetObservable, SetAccess = private)
    Figs
    BoundaryPoly
    NFigures
  end
  
  properties (Dependent)
    Xs
    Ys
    Slants
    Tilts
    Activations
    Visibilities
    Selections
    Removables
  end
  
  properties (Constant)
    X = 1
    Y = 2
    S = 3 % Slant
    T = 4 % Tilt
    A = 5
    V = 6
    L = 7
    R = 8
  end
  
  % Why use events instead of property change listeners?  Because it's more
  % efficient if the listener has access to specifically what indexes were
  % modified, which they can't have with property change listeners.
  
  events
    FiguresAdded
    FiguresRemoved
    FigurePositionsChanged
    FigureSlantsChanged
    FigureTiltsChanged
    FigureActivationsChanged
    FigureVisibilitiesChanged
    FigureSelectionsChanged
    FigureRemovablesChanged
  end
  
  methods
    function obj = GFFigSet(figs, figSetBoundary)
      if ~exist('figs', 'var') || isempty(figs)
        figs = zeros(0, 8);
      end
      
      if ~exist('figSetBoundary', 'var')
        figSetBoundary = [];
      end
      
      if isa(figs, 'GFFigSet')
        figs = figs.Figs;
      end
      
      obj.BoundaryPoly = figSetBoundary;
      
      obj.NFigures = size(figs, 1);
      
      if size(figs, 2) == 4
        obj.Figs = [figs false(obj.NFigures, 1) true(obj.NFigures, 1) false(obj.NFigures, 1) true(obj.NFigures, 1)];
      elseif size(figs, 2) == 8
        obj.Figs = figs;
      else
        error('The figure array must have four or eight columns.');
      end
    end
    
    function addFigures(obj, figures)
      if ~isempty(figures)
        if size(figures, 2) == 4
          nAddedFigs = size(figures, 1);
          figures = [figures false(nAddedFigs, 1) true(nAddedFigs, 1) false(nAddedFigs, 1) true(nAddedFigs, 1)];
        end
        obj.Figs = [obj.Figs; figures];
        startAffected = obj.NFigures + 1;
        obj.NFigures = size(obj.Figs, 1);
        endAffected = obj.NFigures;
        indxs = startAffected:endAffected;
        notify(obj, 'FiguresAdded', FigureEvent(indxs));
      end
    end
    
    function removeFigures(obj, indxs, ignoreRemovability)
      if islogical(indxs)
        indxs = find(indxs);
      end
      
      if nargin < 3 || ~ignoreRemovability
        indxs(~obj.Figs(indxs,GFFigSet.R)) = [];
      end
      
      if ~isempty(indxs)
        obj.Figs(indxs,:) = [];
        obj.NFigures = size(obj.Figs, 1);
        notify(obj, 'FiguresRemoved', FigureEvent(indxs));
      end
    end
    
    function setPositions(obj, indxs, vals)
      if islogical(indxs)
        indxs = find(indxs);
      end
      
      if ~isempty(indxs)
        obj.Figs(indxs,[GFFigSet.X GFFigSet.Y]) = vals;
        notify(obj, 'FigurePositionsChanged', FigureEvent(indxs));
      end
    end
    
    function setSlants(obj, indxs, vals)
      if islogical(indxs)
        indxs = find(indxs);
      end
      
      if ~isempty(indxs)
        obj.Figs(indxs,GFFigSet.S) = vals;
        notify(obj, 'FigureSlantsChanged', FigureEvent(indxs));
      end
    end
    
    function setTilts(obj, indxs, vals)
      if islogical(indxs)
        indxs = find(indxs);
      end
      
      if ~isempty(indxs)
        obj.Figs(indxs,GFFigSet.T) = vals;
        notify(obj, 'FigureTiltsChanged', FigureEvent(indxs));
      end
    end
    
    function setActivations(obj, indxs, vals)
      if islogical(indxs)
        indxs = find(indxs);
      end
      
      if ~isempty(indxs)
        obj.Figs(indxs,GFFigSet.A) = vals;
        notify(obj, 'FigureActivationsChanged', FigureEvent(indxs));
      end
    end
    
    function setVisibilities(obj, indxs, vals)
      if islogical(indxs)
        indxs = find(indxs);
      end
      
      if ~isempty(indxs)
        obj.Figs(indxs,GFFigSet.V) = vals;
        notify(obj, 'FigureVisibilitiesChanged', FigureEvent(indxs));
      end
    end
    
    function setSelections(obj, indxs, vals)
      if islogical(indxs)
        indxs = find(indxs);
      end
      
      if ~isempty(indxs)
        obj.Figs(indxs,GFFigSet.L) = vals;
        notify(obj, 'FigureSelectionsChanged', FigureEvent(indxs));
      end
    end
    
    function setRemovables(obj, indxs, vals)
      if islogical(indxs)
        indxs = find(indxs);
      end
      
      if ~isempty(indxs)
        obj.Figs(indxs,GFFigSet.R) = vals;
        notify(obj, 'FigureRemovablesChanged', FigureEvent(indxs));
      end
    end
    
    function val = get.Xs(obj)
      val = obj.Figs(:,GFFigSet.X);
    end
    
    function val = get.Ys(obj)
      val = obj.Figs(:,GFFigSet.Y);
    end
    
    function val = get.Slants(obj)
      val = obj.Figs(:,GFFigSet.S);
    end
    
    function val = get.Tilts(obj)
      val = obj.Figs(:,GFFigSet.T);
    end
    
    function val = get.Activations(obj)
      val = logical(obj.Figs(:,GFFigSet.A));
    end
    
    function val = get.Visibilities(obj)
      val = logical(obj.Figs(:,GFFigSet.V));
    end
    
    function val = get.Selections(obj)
      val = logical(obj.Figs(:,GFFigSet.L));
    end
    
    function val = get.Removables(obj)
      val = logical(obj.Figs(:,GFFigSet.R));
    end
  end
end