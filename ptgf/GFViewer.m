function GFViewer(data, image, mask, controller)

global GFSettings;

GFSettings = gfMakeSettings('PopulateInteriorByContractingBoundary', false, 'FovY', 20.5, ...
                            'HoverCursor', 9, 'AddPtCursor', [], 'MinNumberOfFigsForReconstruction', -1, ...
                            'FigureMultirotationEnabled', true, 'InterpMethod', 'cubic', ...
                            'FigureSelectionEnabled', true);

if ~iscell(image)
  image = {image};
end

if ~iscell(mask)
  mask = {logical(mask)};
end

figures = data.TaskLog.FinalFigSet;
figures.setVisibilities(1:figures.NFigures, true);
figures.setActivations(1:figures.NFigures, true);

if ~exist('controller', 'var')
  controller = @GFFCModifiedTaskController;
end

ListenChar(2);
GaugeFigures(image, mask, {figures}, controller, {[]}, @(a,b,c,d) []);
ListenChar(0);