function [figs boundaryPoly] = gfInitFigs(figs, mask)

global GFSettings;
  
if GFSettings.IncludeBoundaryPolyInMask || GFSettings.PopulateEdge
  shrunkMask = filter2(ones(3), ~mask) == 0;
  populationMask = filter2(ones(round(GFSettings.FigSep)), ~shrunkMask) == 0;
  edges = edge(double(shrunkMask), 'canny');
  boundaryPoly = populateBoundary(double(edges), GFSettings.FigSep);
end

if isempty(figs)
  if GFSettings.PopulateInterior || GFSettings.PopulateEdge
    if GFSettings.PopulateEdge
      boundaries = boundaryPoly;
    else
      populationMask = flippedMask;
      boundaries = zeros(0, 2);
    end
    
    if GFSettings.PopulateInterior
      [imHeight imWidth] = size(mask);
      
      if GFSettings.PopulateEdge && GFSettings.PopulateInteriorByContractingBoundary
        [xs ys] = meshgrid(linspace(-imWidth/2, imWidth/2, imWidth), ...
                           linspace(imHeight/2, -imHeight/2, imHeight));
        circleFilt = xs.^2 + ys.^2 <= GFSettings.FigSep^2;
        circleFiltFT = fft2(circleFilt);
        xs = []; ys = [];
        while any(shrunkMask(:))
          shrunkMask = abs(fftshift(ifft2(circleFiltFT.*fft2(~shrunkMask)))) < 1e-5;
          edges = edge(double(shrunkMask), 'canny');
          additional = populateBoundary(double(edges), GFSettings.FigSep);
          xs = [xs; additional(:,1)]; %#ok<AGROW>
          ys = [ys; additional(:,2)]; %#ok<AGROW>
        end
      else
        % Weird order for meshgrid args makes keyboard navigation better...
        [ys xs] = meshgrid(imHeight:-GFSettings.FigSep:0, 0:GFSettings.FigSep:imWidth);
        xs(:,1:2:end) = xs(:,1:2:end) + GFSettings.FigSep/4;
        xs(:,2:2:end) = xs(:,2:2:end) - GFSettings.FigSep/4;
        valid = xs >= 0 & ys >= 0 & xs < imWidth & ys < imHeight;
        xs = xs(valid);
        ys = ys(valid);
        inside = populationMask(sub2ind(size(populationMask), round(ys + 1), round(xs + 1)));
        xs = xs(inside);
        ys = ys(inside);
      end
    else
      xs = [];
      ys = [];
    end

    xs = round([xs; boundaries(:,1)]);
    ys = round([ys; boundaries(:,2)]);
    nFigures = length(xs);
    figs = [xs ys zeros(nFigures, 2)];
  else
    figs = zeros(0, 4);
  end
else
  if size(figs, 2) < GFFigSet.S
    figs(:,GFFigSet.S) = 0;
  end

  if size(figs, 2) < GFFigSet.T
    figs(:,GFFigSet.T) = 0;
  end
end