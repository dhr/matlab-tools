function ab = gfMakeSettings(varargin)
%GFMAKESETTINGS Create a settings structure for a gauge figure run.
%   PREFS = GFMAKESETTINGS(...) creates a settings structure (PREFS) for
%   use with the GAUGEFIGURES function.  The input parameters should be a
%   list of key-value pairs, for example:
%
%    gfMakeSettings('ClearScreenBrightness', 0, 'FovY', 30, 'LineWidth', 2)
%
%   Settings that are not specified in the arguments are given default
%   values.  It's a good idea to call this once and save the resulting
%   structure, passing that to GAUGEFIGURES, since this is most efficient.
%
%   A quick note on the keyboard settings:
%
%     1.  All key setting values should be the product of a call to KbName.
%
%     2.  A key setting can assume multiple values, by concatenating the
%     values as an array.  When this is the case, all values will trigger
%     the associated action.
%
%     3.  Setting a key setting to the empty matrix will disable the
%     associated action.
%
%   A list of all available settings, ordered very loosely by relevance:
%
%     'ClearScreenBrightness' - the background color brightness.  The
%     default is 0 (black).
%
%     'FovY' - the field of view in the vertical direction, in degrees.
%     The default is 25.
%
%     'ShapeLightPosition' - the position of the light illuminating the
%     reconstructed shape.  This defaults to [0 0 1 0], or an infinitely
%     distant light directly behind the viewer.
%
%     'ShapeUsePerspective' - whether to render the shape under perspective
%     projection or not.  Defaults to false (though this will probably
%     change soon).
%
%     'UseDenseNormals' - whether to use normal interpolation to create a
%     dense field of normals from which to reconstruct the shape.  Defaults
%     to true.
%
%     'InterpMethod' - the interpolation method used to interpolate
%     normals.  Can be one of:
%
%       'opengl' - use OpenGL to do linear interpolation via a shader.  The
%       quickest option.
%
%       'linear' - use linear interpolation, via MATLAB's griddata function.
%
%       'cubic' - use cubic interpolation, via MATLAB's griddata function.
%
%       'v4' - use the v4 method of MATLAB's griddata function.  Really
%       slow, but great results...
%
%     The default is 'opengl'.
%
%     'UpdateShapeInRealTime' - whether to update the shape in real time as
%     the user changes a gauge figure.  Defaults to false, but works really
%     well when 'UseDenseNormals' and 'ShapeUsePerspective' are both false.
%
%     'ClicklessMode' - enables a clickless mode, whereby the currently
%     hovered figure automatically rotates with mouse movements as opposed
%     to mouse drags, thus requiring no button depressing.  Obviously, this
%     only makes sense if the mouse is frozen.  Defaults to false.
%
%     'SoloActiveFigures' - when figures being manipulated, only show those
%     figures and hide other figures.  Defaults to true.
%
%     'ScreenshotSaveDir' - where to save screenshots when they are taken.
%     Defaults to '~/Desktop'.
%
%     'PopulateInterior' - whether to populate the interior of the shape
%     with gauge figures when no initial set is provided.  Defaults to
%     true.
%
%     'PopulateInteriorByContractingBoundary - whether to populate the
%     interior of the shape along scaled copies of the boundary when
%     'PopulateInterior' is turned on (and no initial gauge figure set is
%     provided).  Defaults to true.  When this is false, the interior is
%     populated by placing gauge figures on a hexagonal grid inside the
%     mask.
%
%     'PopulateEdge' - whether to populate the edge of the shape when no
%     initial gauge figure set is provided.  Defaults to true.
%
%     'FigSep' - the approximate separation between figures that should be
%     maintained during population of the interior and edge, in pixels.
%     Defaults to 50.
%
%     'IgnoreMaskWhenDrawingImage' - whether to ignore the provided mask
%     when drawing the image.  By default, this is set to false, which
%     means regions outside the mask are set to the background color in the
%     image, so that when it is drawn only the "relevant" portions of the
%     image are noticeable.
%
%     'UnactivatedFigColor' - the color of an unactivated figure.  Defaults
%     to blue ([0 0 1] -- all colors below don't contain an alpha
%     component).
%
%     'SelectedFigColor' - the color of a selected figure.  Defaults to
%     green.
%
%     'ActiveFigColor' - the color of an active figure (one the user is
%     currently manipulating but is not hovering over... for example via a
%     selection of multiple figures).  Defaults to yellow.
%
%     'ActivatedFigColor' - the color of a figure that has been manipulated
%     at some point.  Defaults to red.
%
%     'UnactivatedHoveredFigColor' - the color of an unactivated figure
%     that is currently being hovered over.  Defaults to light blue.
%
%     'SelectedHoveredFigColor' - the color of a selected figure that is
%     currently being hovered over.  Defaults to light green.
%
%     'ActiveHoveredFigColor' - the color of an active figure that is
%     currently being hovered over.  Defaults to cyan.
%
%     'ActivatedHoveredFigColor' - the color of a figure that has been
%     manipulated at some point and is currently being hovered over.
%     Defaults to light red.
%
%     'OutlineFigures' - whether to outline figures for increased
%     visibility.  Defaults to false.
%
%     'OutlineStrength' - the line width of the outline.  Defaults to 4.
%
%     'OutlineColor' - the color of the outline.  Defaults to black.
%
%     'HoveredVertexColor' - the color of the dot indicating which vertex
%     on the (sparsely) reconstructed shape a gauge figure corresponds to.
%     Defaults to yellow.
%
%     'LassoColor' - the color of the selection lasso polygon.
%     Defaults to transparent blue ([0 0 1 0.5]).
%
%     'ShapeMaterialColor' - the color of the material of the reconstructed
%     shape.  Defaults to light gray ([0.8 0.8 0.8]).
%
%     'ShapeWireColor' - the color of the shape's wireframe rendering.
%     Defaults to white.
%
%     'ShapeAmbientLightColor' - the amount and color of ambient light for
%     the shape.  Defaults to very dark gray ([0.05 0.05 0.05 1]).
%
%     'FpsTextColor' - color of the text used to display the frames per
%     second information.
%
%     'FigureStrength' - the width of the lines used to draw the figures.
%     Defaults to 2.
%
%     'LassoStrength' - the width of lines used for the selection lasso.
%     Defaults to 2.
%
%     'HoveredVertexPointSize' - the size of the point used to indicate
%     which vertex on the (sparsely) reconstructed shape corresponds to the
%     currently hovered gauge figure.  Defaults to 5.
%
%     'DefaultCursor' - the default mouse cursor.  See PsychToolbox
%     documentation for the SetCursor method for valid values.  Defaults to
%     'Arrow'.
%
%     'HoverCursor' - the mouse cursor displayed when the user hovers over
%     an object of interest (such as a gauge figure or the reconstructed
%     shape).  Defaults to 'Hand'.
%
%     'AddPtCursor' - the mouse cursor displayed when the user hovers over
%     an area of the image where a gauge figure can be added.  Default to
%     'CrossHair'.
%
%     'WaitCursor' - the mouse cursor displayed when the user must wait for
%     computations or other time consuming processes to complete.  Defaults
%     to 'SandClock'.
%
%     'DrawStress' - whether to draw "stress" values on the reconstructed
%     shape (shading the shape red in proportion to the errors between the
%     user supplied normals and those calculated from the mesh.  Only
%     applies to sparse reconstructions.
%
%     'UseShader' - whether to use a phong shader to draw the shape.  Also
%     allows for hemispherical lighting.
%
%     'DenseDepthRenderSampling' - the density of points to use when
%     rendering the dense depth map (obviously only applies when
%     'UseDenseNormals' is true).  This is given as the number of pixels to
%     skip between rendered depth values.  Default is 5 (every 5th depth
%     value is rendered).
%
%     'InitialShapeRotQuat' - the inital rotation of the reconstructed
%     shape, as a quaternion.  Defaults to [1 0 0 0], which should be
%     facing the user (i.e., same rotation as whatever is in the image).
%
%     'FigView' - the rectangle defining the figure view, formatted as
%     [left, bottom, width, height], with units normalized by the window's
%     width and height (so when the left coordinate is 0, this is the left
%     side of the screen, while a coordinate of 1 is the right side).
%     Defaults to [0 0 0.5 1], i.e. the left half of the screen.
%
%     'ShapeView' - the rectangle defining the figure view, formatted as
%     [left, bottom, width, height], with units normalized by the window's
%     width and height (so when the left coordinate is 0, this is the left
%     side of the screen, while a coordinate of 1 is the right side).
%     Defaults to [0.5 0 0.5 1], i.e. the right half of the screen.
%
%     'DefaultFigScale' - the default radius of a gauge figure's circle, in
%     pixels.  Defaults to 15.
%
%     'DeltaScale' - the amount by which the scale of a figure changes when
%     its size is increased or decreased.  Defaults to 0.5.
%
%     'MinScale' - the minimum scale value a figure can have, in pixels.
%     Defaults to 7.5.
%
%     'MaxScale' - the maximum scale value a figure can have, in pixels.
%     Defaults to 30.
%
%     'FigRotSens' - the sensitivity of rotation of gauge figures.  This is
%     provided as a pixel distance representing the distance the mouse must
%     move in order to rotate the gauge figure to full slant.  The default
%     is 200 (the user must move the mouse 200 pixels in order to rotate
%     the gauge figure to full slant).
%
%     'ShapeRotSens' - the sensitivity of rotation of the reconstructed
%     shape.  This is provided as a pixel distance representing the radius
%     of the arcball representation used for the shape rotation interface.
%     Defaults to 400.
%
%     'MinSelectAddPtDist' - the minimum distance the mouse must move for a
%     point to be added to the selection lasso polygon during selection.
%     Defaults to 5.  Setting this value too low negatively impacts
%     performance.
%
%     'StencilGrowSigma' - the sigma value used to grow the stencil mask
%     that determines what triangles to consider "invalid".  The default
%     mask is blurred by a gaussian with the supplied sigma, and all
%     non-zero elements are included in the mask.  Any triangles falling
%     outside of this mask are then removed from the triangulation.  This
%     allows for non-convex shapes to be reconstructed, since by default
%     the Delaunay triangulation connects the entire convex hull of
%     supplied points in the triangulation.  Defaults to 0.
%
%     'IncludeBoundaryInPolyMask' - whether to include the polygon defined
%     by only those points located on the edge of the shape in the mask
%     used for elimination of invalid triangles (those connecting vertices
%     such that the resulting triangle lies outside of the mask).  This
%     prevents valid triangles from being eliminated due to slight
%     concavities in the boundary of the shape between consecutive figures
%     located on the boundary, and defaults to true.  Note that this
%     doesn't affect the mask used to determine whether a gauge figure is
%     being placed in a valid location, and as such is somewhat poorly
%     named.
%
%     'MinInvalidArea' - the minimum amount of a triangle required to fall
%     outside of the mask used in invalid triangle elimination in order for
%     the triangle to be considered invalid and removed.  Defaults to 40.
%
%     'AreaType' - the type of "area" to consider with the 'MinInvalidArea'
%     parameter.  Should be one of the polygon rendering types from the GL
%     structure, namely GL.FILL or GL.LINE.  With GL.FILL, the entire area
%     of the triangle is included in the calculation (how many pixels it
%     covers).  With GL.LINE, only the boundary of the triangle is
%     considered.
%
%     'MaxSlantFraction' - the maximum slant fraction the user is allowed
%     to input.  Defaults to 1, so all slants up to the maximum allowable
%     for a given view ray (such that the normal of the gauge figure is
%     perpendicular to the view ray) are allowed.  Old hack and should
%     probably be removed.
%
%     'ShapeAnimInitiallyPaused' - whether the reconstructed shape
%     animation is paused initially when the gauge figure task begins.
%     Defaults to false (so the shape does animate... confusing).
%
%     'ShapeAnimationSpeed' - speed of shape animation in radians per
%     second.  Defaults to pi/2.
%
%     'AnimRadius' - the size of the radius of shape animation.  When the
%     shape is paused, imagine a unit-length stick pointing straight
%     towards the viewer.  The when the shape is unpaused, 'AnimRadius'
%     describes the radius of the circle that the tip of the circle draws
%     on the screen. Or something like that... don't remember if that's
%     exactly how it goes.  But anyway larger values lead to larger
%     rotations.  Defaults to 50.
%
%     'NFramesToAvgForFPS' - number of consecutive frames to include in a
%     calculation of the frames per second.  The total time to render this
%     many frames is divided into this many frames and displayed as the FPS
%     if FPS display is turned on.  Defaults to 10.
%
%     'DrawFPSInitially' - whether to draw the FPS initally when the gauge
%     figure task starts.  Defaults to false.
%
%     'LoadShaders' - whether to load the shaders.  Defaults to true, and I
%     don't know what would happen if it were false.  Probably something
%     fiery.
%
%     'QuitKey' - the key used to quit the task (signaling the figure is
%     completed).  Defaults to KbName('esc').
%
%     'SwitchRenderKey' - the key used to switch rendering settings,
%     cycling between various settings such as with wireframe, without,
%     with flat or smooth shading, etc.  Defaults to KbName('`~').
%
%     'UseDenseNormalsKey' - the key used to toggle between using dense
%     normal and sparse normal based reconstruction.  Defaults to
%     KbName('1!').
%
%     'DrawStressKey' - the key used to toggle drawing "stress"
%     values on the reconstructed surface.  Only works right now when
%     'UseDenseNormals' is false.  Defaults to KbName('2@').
%
%     'SwitchShadingKey' - the key used to toggle between regular
%     lambertian shading and hemispherical shading.  Only works if
%     'UseShader' is set to true.  Defaults to KbName('3#').
%
%     'SwitchPerspectiveKey' - the key used to toggle between drawing the
%     reconstructed shape in orthographic or perspective projection.
%     Defaults to KbName('4$').
%
%     'UseShaderKey' - the key used to toggle between using the pixel
%     shader for phong shading and hemispherical shading or not using it
%     (and using OpenGL's default Gouraud shading instead).  Defaults to
%     KbName('5^').
%
%     'DecreaseSamplingKey' - the key used to decrease the
%     'DenseDepthRenderSampling' setting.  Defaults to KbName('-_').
%
%     'IncreaseSamplingKey' - the key used to increase the
%     'DenseDepthRenderSampling' setting.  Defaults to KbName('=+').
%
%     'DeleteKey' - the key used to delete selected or hovered gauge
%     figures.  Defaults to KbName('delete').
%
%     'NextFigKey' - the key used to advance the mouse to the next gauge
%     figure.  Defaults to KbName('tab').
%
%     'HideFigsKey' - the key used to hide the gauge figures.  Figures are
%     only hidden while the key is down.  Defaults to KbName('q').
%
%     'HideImageKey' - the key used to hide the image.  The image is only
%     hidden while the key is down.  Defaults to KbName('w').
%
%     'GrowFigKey' - the key used to increase the scale of a selected or
%     hovered gauge figure.  Defaults to KbName('a').
%
%     'ShrinkFigKey' - the key used to decrease the scale of a selected or
%     hovered gauge figure.  Defaults to KbName('s').
%
%     'ResetFigSizeKey' - the key used to reset the scale of a selected or
%     hovered gauge figure to the 'DefaultFigScale' setting.  Defaults to
%     KbName('d').
%
%     'ScreenshotKey' - the key used to take a screenshot of the running
%     experiment, saving it in the directory specified by the
%     'ScreenshotSaveDir' preference setting.  Defaults to KbName('''"')
%     (this is the single quote key).
%
%     'AdditionalKey' - the key used to indicate that actions should be
%     "additional" to those already taken.  For example, adding/removing
%     figures to/from a preexisting selection instead of clearing the
%     selection.  Defaults to [KbName('leftshift') KbName('rightshift')].
%
%     'ShowFPSKey' - the key used to toggle display of FPS info.  Defaults
%     to KbName('/?').
%
%     'ModifySlantKey' - the key used to indicate group modification of a
%     selection should affect only the slants of the selected figures.
%     Defaults to [KbName('leftcontrol' KbName('rightcontrol')].
%
%     'PauseAnimKey' - the key used to toggle animation of the
%     reconstructed shape.  Defaults to KbName('space').
%
%   See also GAUGEFIGURES, GFTRIALS.

global GL;

AssertOpenGL;
InitializeMatlabOpenGL;

if numel(varargin) > 0 && isstruct(varargin{1})
  ab = varargin{1};
  return;
end

ab.UseVertexbufferObjects = true;
ab.UseFramebufferObjects = true;
ab.GL32BitFloatingPointInternalFormat = GL.RGB_FLOAT32_ATI;
ab.GFRoot = fileparts(mfilename('fullpath'));
ab.ScreenshotSaveDir = fullfile(getenv('HOME'), 'Desktop');
ab.MeshSaveDir = fullfile(getenv('HOME'), 'Desktop');
ab.ConfirmQuit = true;
ab.ShowGhostFigure = true;

%%%%%%%%%% Appearance settings

ab.ClearScreenBrightness = 0;
ab.IgnoreMaskWhenDrawingImage = false;

ab.UnactivatedFigColor = [0 0 1];
ab.SelectedFigColor = [0 1 0];
ab.ActiveFigColor = [1 1 0];
ab.ActivatedFigColor = [1 0 0];
ab.UnactivatedHoveredFigColor = [0.5 0.5 1];
ab.SelectedHoveredFigColor = [0.5 1 0.5];
ab.ActiveHoveredFigColor = [0 1 1];
ab.ActivatedHoveredFigColor = [1 0.5 0.5];

ab.OutlineFigures = true;
ab.OutlineStrength = 4;
ab.OutlineColor = [0 0 0];

ab.FigureStrength = 2;

ab.GhostFigureColor = [1 0.8 0.6];

ab.HoveredVertexColor = [1 1 0];

ab.LassoColor = [0 0 1 0.5];
ab.LassoStrength = 2;

ab.ShapeMaterialColor = 0.8*[1 1 1];
ab.ShapeWireColor = [1 1 1];

ab.ShapeAmbientLightColor = [0.05 0.05 0.05 1];
ab.ShapeLightPosition = [0 0 1 0];

ab.FpsTextColor = [1 1 1];

ab.HoveredVertexPointSize = 8;

ab.DefaultCursor = 'Arrow';
ab.HoverCursor = 'Hand';
ab.AddPtCursor = 'CrossHair';
ab.WaitCursor = 'SandClock';

ab.NCircleSegments = 30;

ab.FovY = 25; % Vertical field of view
ab.FigsUsePerspective = true;
ab.ShapeUsePerspective = false;

ab.DrawStress = false;

ab.UseShader = true;

ab.DenseDepthRenderSampling = 5;

ab.InitialShapeRotQuat = [1 0 0 0];

ab.FigView = [0 0 0.5 1];
ab.ShapeView = [0.5 0 0.5 1];

%%%%%%%%%% Behavior settings

ab.PopulateInterior = true;
ab.PopulateInteriorByContractingBoundary = true;
ab.PopulateEdge = true;
ab.IncludeBoundaryPolyInMask = true;

ab.ClicklessMode = false;
ab.SoloActiveFigures = true;
ab.MinNumberOfFigsForReconstruction = 40;
ab.FigureSelectionEnabled = true;
ab.FigureMultirotationEnabled = true;
ab.FigureAdditionEnabled = true;
ab.FigureRemovalEnabled = true;

ab.FigSep = 50;
ab.DefaultFigScale = 15;
ab.DeltaScale = 0.5;
ab.MinScale = 7.5;
ab.MaxScale = 30;

ab.UpdateShapeInRealTime = false;
ab.UseDenseNormals = true;
ab.InterpMethod = 'opengl';

ab.FigRotSens = 200;
ab.ShapeRotSens = 400;

ab.MaxAllowedMotionForClick = 4;
ab.MinSelectAddPtDist = 5;

ab.StencilGrowSigma = 0;
ab.MinInvalidArea = 40;
ab.AreaType = GL.FILL;

ab.MaxSlantFraction = 1;

ab.ShapeAnimInitiallyPaused = false;
ab.ShapeAnimationSpeed = pi/2; % Radians per second
ab.AnimRadius = 50;

ab.NFramesToAvgForFPS = 10;
ab.DrawFPSInitially = false;

ab.LoadShaders = true;

ab.QuitKey = KbName('escape');
ab.SwitchRenderKey = KbName('`~');
ab.UseDenseNormalsKey =  KbName('1!');
ab.DrawStressKey = KbName('2@');
ab.SwitchShadingKey =  KbName('3#');
ab.SwitchPerspectiveKey = KbName('4$');
ab.UseShaderKey = KbName('5%');
ab.DecreaseSamplingKey = KbName('-_');
ab.IncreaseSamplingKey = KbName('=+');
ab.DeleteKey = KbName('delete');
ab.NextFigKey = KbName('tab');
ab.HideFigsKey = KbName('q');
ab.HideImageKey = KbName('w');
ab.GrowFigKey = KbName('a');
ab.ShrinkFigKey = KbName('s');
ab.ResetFigSizeKey = KbName('d');
ab.ScreenshotKey = KbName('''"');
ab.SaveMeshKey = KbName(';:');
ab.ReconstructShapeKey = KbName('return');
ab.ShiftKey = [KbName('leftshift') KbName('rightshift')];
ab.SelectionKey = ab.ShiftKey;
ab.InsertionKey = [KbName('leftalt') KbName('rightalt')];
ab.ShowFPSKey = KbName('/?');
ab.ModifySlantKey = [KbName('leftcontrol') KbName('rightcontrol')];
ab.PauseAnimKey = KbName('space');

nParams = numel(varargin);
if mod(nParams, 2)
  error('Uneven number of parameters provided.  Parameters must be provided as key-value pairs.');
end

fieldNames = fieldnames(ab);
loweredFieldNames = lower(fieldNames);

for i = 1:2:nParams
  key = lower(varargin{i});
  inds = strmatch(key, loweredFieldNames, 'exact');
  
  if isempty(inds)
    error(['Parameter ' varargin{i} ' not recognized.']);
  elseif numel(inds) > 1
    % This shouldn't happen unless two of ab's field names differ only by case.
    error('Someone''s been a bonehead.');
  else
    % Dynamic field names!  Magnificent with sauerkraut, but sadly not so much with validation.
    ab.(fieldNames{inds}) = varargin{i + 1};
  end
end
