function SAM_Interactive_GUI()

% Initialize main variables
data = struct();
data.image = [];
data.sam = [];
data.embeddings = [];
data.allMasks = [];
data.allPoints = [];
data.objectCount = 0;
data.imageSize = [];
data.colors = {'red', 'green', 'blue', 'magenta', 'cyan', 'yellow', 'black', 'white'};
data.isProcessing = false;

% Selection method settings
data.selectionMethod = 1; % 1=Click-based, 2=Distance-based, 3=Largest only
data.minAreaThreshold = 50; % Minimum area for valid masks
data.cleanComponents = true; % Whether to clean connected components

% Create main figure with modern styling
data.mainFig = figure('Name', 'SAM Interactive Segmentation Tool', ...
    'Position', [50, 50, 1500, 900], ...
    'MenuBar', 'none', ...
    'ToolBar', 'none', ...
    'Resize', 'on', ...
    'CloseRequestFcn', @closeApp, ...
    'Color', [0.94 0.94 0.94], ...
    'WindowStyle', 'normal');

% Add resize callback for scalability
set(data.mainFig, 'SizeChangedFcn', @onWindowResize);
setupGUI();

    function setupGUI()
        % Create menu bar with enhanced styling
        data.fileMenu = uimenu(data.mainFig, 'Label', 'File');
        uimenu(data.fileMenu, 'Label', 'Load Image', 'Callback', @loadImage, 'Accelerator', 'O');
        uimenu(data.fileMenu, 'Label', 'Save Results', 'Callback', @saveResults, 'Enable', 'off', 'Accelerator', 'S');
        uimenu(data.fileMenu, 'Label', 'Export Masks', 'Callback', @exportMasks, 'Enable', 'off', 'Accelerator', 'E');
        uimenu(data.fileMenu, 'Label', 'Clear All', 'Callback', @clearAll, 'Accelerator', 'R');
        uimenu(data.fileMenu, 'Label', 'Exit', 'Separator', 'on', 'Callback', @closeApp, 'Accelerator', 'Q');
        % Settings menu
        data.settingsMenu = uimenu(data.mainFig, 'Label', 'Settings');
        uimenu(data.settingsMenu, 'Label', 'Reset to Defaults', 'Callback', @resetSettings);
        % Help menu
        data.helpMenu = uimenu(data.mainFig, 'Label', 'Help');
        uimenu(data.helpMenu, 'Label', 'Selection Methods Info', 'Callback', @showHelp, 'Accelerator', 'H');
        uimenu(data.helpMenu, 'Label', 'About', 'Callback', @showAbout);
        % Create main layout with better proportions
        data.mainPanel = uipanel(data.mainFig, 'Position', [0 0 1 1], 'BorderType', 'none', ...
            'BackgroundColor', [0.94 0.94 0.94]);
        setupPanels();
        updateLayout();
        updateStatus('Ready. Load an image to begin segmentation.');
    end
    function setupPanels()
        % Control panel (left side) with modern styling
        data.controlPanel = uipanel(data.mainPanel, 'Title', 'Controls & Settings', ...
            'TitlePosition', 'centertop', ...
            'FontSize', 12, 'FontWeight', 'bold', ...
            'BackgroundColor', [0.97 0.97 0.97], ...
            'BorderType', 'line', 'HighlightColor', [0.3 0.3 0.3], ...
            'ShadowColor', [0.7 0.7 0.7]);

        % Image display panel (right side) with modern styling
        data.imagePanel = uipanel(data.mainPanel, 'Title', 'Image Display', ...
            'TitlePosition', 'centertop', ...
            'FontSize', 12, 'FontWeight', 'bold', ...
            'BackgroundColor', [0.98 0.98 0.98], ...
            'BorderType', 'line', 'HighlightColor', [0.3 0.3 0.3], ...
            'ShadowColor', [0.7 0.7 0.7]);

        setupControlPanel();
        setupImagePanel();
    end
    function setupControlPanel()
        % Store UI elements for dynamic positioning
        data.controlElements = struct();
        % Load Image button with modern styling
        data.controlElements.loadBtn = uicontrol(data.controlPanel, 'Style', 'pushbutton', ...
            'String', 'Load Image', ...
            'FontSize', 11, 'FontWeight', 'bold', ...
            'BackgroundColor', [0.2 0.6 1.0], ...
            'ForegroundColor', 'white', ...
            'Units', 'pixels', ...
            'Callback', @loadImage);
        % Model status section
        data.controlElements.modelLabel = uicontrol(data.controlPanel, 'Style', 'text', ...
            'String', 'SAM Model Status:', ...
            'FontSize', 10, 'FontWeight', 'bold', ...
            'BackgroundColor', [0.97 0.97 0.97], ...
            'Units', 'pixels', ...
            'HorizontalAlignment', 'left');

        data.modelStatus = uicontrol(data.controlPanel, 'Style', 'text', ...
            'String', 'Not Loaded', ...
            'FontSize', 9, ...
            'ForegroundColor', [0.8 0 0], ...
            'BackgroundColor', [0.97 0.97 0.97], ...
            'Units', 'pixels', ...
            'HorizontalAlignment', 'left');

        % Selection Method Panel with enhanced styling
        data.methodPanel = uipanel(data.controlPanel, 'Title', 'Selection Method', ...
            'FontSize', 10, 'FontWeight', 'bold', ...
            'BackgroundColor', [0.95 0.95 0.95], ...
            'Units', 'pixels', ...
            'BorderType', 'line');

        setupMethodPanel();

        % Enhanced Smoothing Controls Panel
        data.smoothingPanel = uipanel(data.controlPanel, 'Title', 'Shape Processing', ...
            'FontSize', 10, 'FontWeight', 'bold', ...
            'BackgroundColor', [0.95 0.95 0.95], ...
            'Units', 'pixels', ...
            'BorderType', 'line');

        setupSmoothingPanel();

        % Information panels with modern styling
        setupInfoPanels();

        % Control buttons with enhanced styling
        setupControlButtons();

        % Status bar with modern styling
        data.statusText = uicontrol(data.controlPanel, 'Style', 'text', ...
            'String', 'Ready', ...
            'FontSize', 9, ...
            'ForegroundColor', [0 0.6 0], ...
            'BackgroundColor', [0.9 0.9 0.9], ...
            'Units', 'pixels', ...
            'HorizontalAlignment', 'left');
    end
    function setupMethodPanel()
        % Selection method radio buttons with better styling
        data.methodGroup = uibuttongroup(data.methodPanel, ...
            'BorderType', 'none', ...
            'BackgroundColor', [0.95 0.95 0.95], ...
            'SelectionChangeFcn', @methodChanged);

        data.method1Radio = uicontrol(data.methodGroup, 'Style', 'radiobutton', ...
            'String', 'Click-Point Based (Recommended)', ...
            'FontSize', 9, ...
            'BackgroundColor', [0.95 0.95 0.95], ...
            'Value', 1, 'Tag', 'method1');

        data.method2Radio = uicontrol(data.methodGroup, 'Style', 'radiobutton', ...
            'String', 'Distance-Based Selection', ...
            'FontSize', 9, ...
            'BackgroundColor', [0.95 0.95 0.95], ...
            'Tag', 'method2');

        data.method3Radio = uicontrol(data.methodGroup, 'Style', 'radiobutton', ...
            'String', 'Largest Component Only', ...
            'FontSize', 9, ...
            'BackgroundColor', [0.95 0.95 0.95], ...
            'Tag', 'method3');
    end
    function setupSmoothingPanel()
        % Smoothing controls with enhanced styling
        data.controlElements.smoothLabel = uicontrol(data.smoothingPanel, 'Style', 'text', ...
            'String', 'Smoothing Level:', ...
            'FontSize', 9, 'FontWeight', 'bold', ...
            'BackgroundColor', [0.95 0.95 0.95], ...
            'Units', 'pixels', ...
            'HorizontalAlignment', 'left');
        data.smoothingSlider = uicontrol(data.smoothingPanel, 'Style', 'slider', ...
            'Min', 0, 'Max', 20, 'Value', 2, ...  % Increased from Max 10 to Max 20
            'SliderStep', [0.05 0.1], ...  % Finer control steps
            'BackgroundColor', [0.9 0.9 0.9], ...
            'Units', 'pixels', ...
            'Callback', @smoothingChanged);
        data.smoothingValue = uicontrol(data.smoothingPanel, 'Style', 'text', ...
            'String', '2.0', ...
            'FontSize', 9, 'FontWeight', 'bold', ...
            'BackgroundColor', [0.95 0.95 0.95], ...
            'Units', 'pixels', ...
            'HorizontalAlignment', 'center');
        % Shape control slider with enhanced styling
        data.controlElements.concaveLabel = uicontrol(data.smoothingPanel, 'Style', 'text', ...
            'String', 'Shape Control:', ...
            'FontSize', 9, 'FontWeight', 'bold', ...
            'BackgroundColor', [0.95 0.95 0.95], ...
            'Units', 'pixels', ...
            'HorizontalAlignment', 'left');
        data.concavenessSlider = uicontrol(data.smoothingPanel, 'Style', 'slider', ...
            'Min', -1, 'Max', 10, 'Value', 5, ...
            'SliderStep', [0.05 0.1], ...
            'BackgroundColor', [0.9 0.9 0.9], ...
            'Units', 'pixels', ...
            'Callback', @concavenessChanged);
        data.concavenessValue = uicontrol(data.smoothingPanel, 'Style', 'text', ...
            'String', '5.0', ...
            'FontSize', 9, 'FontWeight', 'bold', ...
            'BackgroundColor', [0.95 0.95 0.95], ...
            'Units', 'pixels', ...
            'HorizontalAlignment', 'center');
        data.concavenessDesc = uicontrol(data.smoothingPanel, 'Style', 'text', ...
            'String', 'Balanced', ...
            'FontSize', 8, ...
            'BackgroundColor', [0.95 0.95 0.95], ...
            'Units', 'pixels', ...
            'HorizontalAlignment', 'left', ...
            'ForegroundColor', [0.2 0.6 0.2]);
        % Checkboxes with enhanced styling
        data.simplifyBoundary = uicontrol(data.smoothingPanel, 'Style', 'checkbox', ...
            'String', 'Simplify Boundaries', ...
            'FontSize', 9, 'Value', 1, ...
            'BackgroundColor', [0.95 0.95 0.95], ...
            'Units', 'pixels', ...
            'Callback', @simplifyChanged);
        data.advancedSmoothing = uicontrol(data.smoothingPanel, 'Style', 'checkbox', ...
            'String', 'Advanced Smoothing', ...
            'FontSize', 9, 'Value', 0, ...
            'BackgroundColor', [0.95 0.95 0.95], ...
            'Units', 'pixels', ...
            'Callback', @advancedSmoothingChanged);
        % Initialize settings
        data.selectionMethod = 1;
        data.smoothingLevel = 2;
        data.concavenessLevel = 5;
        data.simplifyBoundaryFlag = true;
        data.advancedSmoothingFlag = false;
    end
    function setupInfoPanels()
        % Segmentation results panel
        data.segmentInfoPanel = uipanel(data.controlPanel, 'Title', 'Segmentation Results', ...
            'FontSize', 10, 'FontWeight', 'bold', ...
            'BackgroundColor', [0.95 0.95 0.95], ...
            'Units', 'pixels', ...
            'BorderType', 'line');

        data.segmentInfo = uicontrol(data.segmentInfoPanel, 'Style', 'text', ...
            'String', 'Objects segmented: 0', ...
            'FontSize', 9, ...
            'BackgroundColor', [0.95 0.95 0.95], ...
            'Units', 'pixels', ...
            'HorizontalAlignment', 'left');

        % Object list panel
        data.objectListPanel = uipanel(data.controlPanel, 'Title', 'Segmented Objects', ...
            'FontSize', 10, 'FontWeight', 'bold', ...
            'BackgroundColor', [0.95 0.95 0.95], ...
            'Units', 'pixels', ...
            'BorderType', 'line');

        data.objectList = uicontrol(data.objectListPanel, 'Style', 'listbox', ...
            'FontSize', 9, ...
            'Units', 'pixels', ...
            'BackgroundColor', 'white');
    end
    function setupControlButtons()
        % Control buttons with modern styling
        data.clearLastBtn = uicontrol(data.controlPanel, 'Style', 'pushbutton', ...
            'String', 'Clear Last', ...
            'Callback', @clearLastObject, ...
            'FontSize', 9, ...
            'BackgroundColor', [1.0 0.6 0.2], ...
            'ForegroundColor', 'white', ...
            'Units', 'pixels', ...
            'Enable', 'off');

        data.clearAllBtn = uicontrol(data.controlPanel, 'Style', 'pushbutton', ...
            'String', 'Clear All', ...
            'Callback', @clearAll, ...
            'FontSize', 9, ...
            'BackgroundColor', [0.8 0.3 0.3], ...
            'ForegroundColor', 'white', ...
            'Units', 'pixels', ...
            'Enable', 'off');

        data.saveBtn = uicontrol(data.controlPanel, 'Style', 'pushbutton', ...
            'String', 'Save Results', ...
            'Callback', @saveResults, ...
            'FontSize', 9, ...
            'BackgroundColor', [0.2 0.7 0.2], ...
            'ForegroundColor', 'white', ...
            'Units', 'pixels', ...
            'Enable', 'off');

        data.exportBtn = uicontrol(data.controlPanel, 'Style', 'pushbutton', ...
            'String', 'Export Masks', ...
            'Callback', @exportMasks, ...
            'FontSize', 9, ...
            'BackgroundColor', [0.4 0.2 0.8], ...
            'ForegroundColor', 'white', ...
            'Units', 'pixels', ...
            'Enable', 'off');
    end
    function setupImagePanel()
        % Create axes for image display with modern styling
        data.imageAxes = axes('Parent', data.imagePanel, ...
            'Box', 'on', ...
            'XTick', [], 'YTick', [], ...
            'HitTest', 'on', ...
            'PickableParts', 'all', ...
            'Color', [0.98 0.98 0.98]);

        % Set up initial click callback
        set(data.imageAxes, 'ButtonDownFcn', @imageClick);

        % Display placeholder with better styling
        data.placeholderText = text(0.5, 0.5, 'Load an image to begin segmentation', ...
            'Parent', data.imageAxes, ...
            'HorizontalAlignment', 'center', ...
            'VerticalAlignment', 'middle', ...
            'FontSize', 16, 'Color', [0.4 0.4 0.4], ...
            'FontWeight', 'bold', ...
            'HitTest', 'off');

        set(data.imageAxes, 'XLim', [0 1], 'YLim', [0 1]);
    end
    function onWindowResize(~, ~)
        % Handle window resize to maintain scalable layout
        updateLayout();
    end
    function updateLayout()
        % Get current figure size in pixels
        figPos = get(data.mainFig, 'Position');
        figWidth = figPos(3);
        figHeight = figPos(4);

        % Define margins and proportions with minimum constraints
        margin = 10;
        minControlPanelWidth = 280; % Minimum width for readability
        maxControlPanelWidth = 380; % Maximum width to preserve space for image

        % Calculate adaptive control panel width
        controlPanelWidth = min(maxControlPanelWidth, max(minControlPanelWidth, figWidth * 0.25));
        imagePanelWidth = figWidth - controlPanelWidth - 3 * margin;

        % Ensure minimum image panel width
        if imagePanelWidth < 400 && figWidth > 700
            controlPanelWidth = figWidth - 400 - 3 * margin;
            imagePanelWidth = 400;
        end

        % Update main panel positions (normalized units)
        set(data.controlPanel, 'Position', ...
            [margin/figWidth, margin/figHeight, ...
            controlPanelWidth/figWidth, (figHeight-2*margin)/figHeight]);

        set(data.imagePanel, 'Position', ...
            [(controlPanelWidth + 2*margin)/figWidth, margin/figHeight, ...
            imagePanelWidth/figWidth, (figHeight-2*margin)/figHeight]);

        % Update control panel layout
        updateControlPanelLayout();

        % Update image panel layout
        updateImagePanelLayout();
    end
    function updateControlPanelLayout()
        % Get control panel dimensions in pixels
        controlPos = get(data.controlPanel, 'Position');
        figPos = get(data.mainFig, 'Position');
        panelWidth = controlPos(3) * figPos(3) - 20; % Account for panel margins
        panelHeight = controlPos(4) * figPos(4) - 20;

        margin = 10;
        buttonHeight = 32;
        panelSpacing = 8; % Reduced spacing for small screens
        textSpacing = 4;  % Reduced spacing

        % Calculate available space and adapt layout
        minRequiredHeight = calculateMinimumHeight();
        isCompactMode = panelHeight < minRequiredHeight + 100; % 100px buffer

        % Adjust spacing and heights for compact mode
        if isCompactMode
            buttonHeight = 28;
            panelSpacing = 6;
            textSpacing = 3;
            infoPanelHeight = 50;
            listPanelHeight = 80;
            methodPanelHeight = 85;
            smoothingPanelHeight = 160;
        else
            infoPanelHeight = 60;
            listPanelHeight = 120; % Increased since we removed one panel
            methodPanelHeight = 95;
            smoothingPanelHeight = 200;
        end

        currentY = panelHeight - margin - buttonHeight;

        % Load button
        set(data.controlElements.loadBtn, 'Units', 'pixels');
        set(data.controlElements.loadBtn, 'Position', ...
            [margin, currentY, panelWidth-2*margin, buttonHeight]);
        currentY = currentY - buttonHeight - panelSpacing;

        % Model status with adaptive spacing
        if isCompactMode
            statusHeight = 18;
        else
            statusHeight = 20;
        end
        set(data.controlElements.modelLabel, 'Units', 'pixels');
        set(data.controlElements.modelLabel, 'Position', ...
            [margin, currentY, panelWidth-2*margin, statusHeight]);
        currentY = currentY - statusHeight - 2;

        set(data.modelStatus, 'Units', 'pixels');
        set(data.modelStatus, 'Position', ...
            [margin, currentY, panelWidth-2*margin, statusHeight-2]);
        currentY = currentY - (statusHeight-2) - panelSpacing;

        % Selection method panel with adaptive height
        set(data.methodPanel, 'Units', 'pixels');
        set(data.methodPanel, 'Position', ...
            [margin, currentY-methodPanelHeight, panelWidth-2*margin, methodPanelHeight]);
        updateMethodPanelLayout(methodPanelHeight, panelWidth-2*margin);
        currentY = currentY - methodPanelHeight - panelSpacing;

        % Smoothing panel with adaptive height
        set(data.smoothingPanel, 'Units', 'pixels');
        set(data.smoothingPanel, 'Position', ...
            [margin, currentY-smoothingPanelHeight, panelWidth-2*margin, smoothingPanelHeight]);
        updateSmoothingPanelLayout(smoothingPanelHeight, panelWidth-2*margin, isCompactMode);
        currentY = currentY - smoothingPanelHeight - panelSpacing;

        % Only Segmentation results panel now (Image Information panel removed)
        set(data.segmentInfoPanel, 'Units', 'pixels');
        set(data.segmentInfoPanel, 'Position', ...
            [margin, currentY-infoPanelHeight, panelWidth-2*margin, infoPanelHeight]);
        set(data.segmentInfo, 'Units', 'pixels');
        set(data.segmentInfo, 'Position', [8, 8, panelWidth-4*margin, infoPanelHeight-30]);
        currentY = currentY - infoPanelHeight - textSpacing;

        % Object list panel with adaptive height - now has more space available
        availableSpace = currentY - (2*buttonHeight + 3*textSpacing + 40); % Space for buttons and status
        if availableSpace < listPanelHeight
            listPanelHeight = max(80, availableSpace); % Increased minimum to 80px
        end

        set(data.objectListPanel, 'Units', 'pixels');
        set(data.objectListPanel, 'Position', ...
            [margin, currentY-listPanelHeight, panelWidth-2*margin, listPanelHeight]);
        set(data.objectList, 'Units', 'pixels');
        set(data.objectList, 'Position', [8, 8, panelWidth-4*margin, listPanelHeight-30]);
        currentY = currentY - listPanelHeight - panelSpacing;

        % Control buttons with better spacing
        buttonWidth = (panelWidth - 3*margin) / 2;
        set(data.clearLastBtn, 'Units', 'pixels');
        set(data.clearLastBtn, 'Position', [margin, currentY-buttonHeight, buttonWidth, buttonHeight]);
        set(data.clearAllBtn, 'Units', 'pixels');
        set(data.clearAllBtn, 'Position', [margin*2+buttonWidth, currentY-buttonHeight, buttonWidth, buttonHeight]);
        currentY = currentY - buttonHeight - textSpacing;

        set(data.saveBtn, 'Units', 'pixels');
        set(data.saveBtn, 'Position', [margin, currentY-buttonHeight, buttonWidth, buttonHeight]);
        set(data.exportBtn, 'Units', 'pixels');
        set(data.exportBtn, 'Position', [margin*2+buttonWidth, currentY-buttonHeight, buttonWidth, buttonHeight]);
        currentY = currentY - buttonHeight - panelSpacing;

        % Status bar - ensure it's always visible
        if isCompactMode
            statusBarHeight = 20;
        else
            statusBarHeight = 24;
        end
        set(data.statusText, 'Units', 'pixels');
        set(data.statusText, 'Position', [margin, 8, panelWidth-2*margin, statusBarHeight]);
    end
    function minHeight = calculateMinimumHeight()
        % Calculate the minimum height needed for all essential elements
        minHeight = 32 + ... % Load button
            40 + ... % Model status
            85 + ... % Method panel (minimum)
            160 + ... % Smoothing panel (minimum)
            50 + ... % Segmentation results panel only (removed Image Info panel)
            80 + ... % Object list (minimum)
            64 + ... % Control buttons (2 rows)
            30 + ... % Status bar
            70;      % Margins and spacing (reduced)
    end
    function updateMethodPanelLayout(panelHeight, panelWidth)
        % Set button group position with proper width and spacing
        set(data.methodGroup, 'Units', 'pixels');
        set(data.methodGroup, 'Position', [4, 4, panelWidth-8, panelHeight-24]);

        radioHeight = 16; % Slightly reduced for better fit
        radioSpacing = 3; % Reduced spacing
        radioY = panelHeight - 42;

        set(data.method1Radio, 'Units', 'pixels');
        set(data.method1Radio, 'Position', [8, radioY, panelWidth-20, radioHeight]);
        set(data.method2Radio, 'Units', 'pixels');
        set(data.method2Radio, 'Position', [8, radioY-radioHeight-radioSpacing, panelWidth-20, radioHeight]);
        set(data.method3Radio, 'Units', 'pixels');
        set(data.method3Radio, 'Position', [8, radioY-2*(radioHeight+radioSpacing), panelWidth-20, radioHeight]);
    end
    function updateSmoothingPanelLayout(panelHeight, panelWidth, isCompactMode)
        if nargin < 3
            isCompactMode = false;
        end
        margin = 8;
        if isCompactMode
            elementSpacing = 6;
        else
            elementSpacing = 8;
        end
        if isCompactMode
            currentY = panelHeight - 35;
        else
            currentY = panelHeight - 40;
        end
        % Smoothing level label and controls
        if isCompactMode
            labelHeight = 14;
        else
            labelHeight = 16;
        end
        set(data.controlElements.smoothLabel, 'Units', 'pixels');
        set(data.controlElements.smoothLabel, 'Position', ...
            [margin, currentY, panelWidth-2*margin, labelHeight]);
        currentY = currentY - (labelHeight + 4);

        if isCompactMode
            sliderHeight = 18;
        else
            sliderHeight = 20;
        end
        sliderWidth = panelWidth - 70;
        set(data.smoothingSlider, 'Units', 'pixels');
        set(data.smoothingSlider, 'Position', ...
            [margin, currentY, sliderWidth, sliderHeight]);
        set(data.smoothingValue, 'Units', 'pixels');
        set(data.smoothingValue, 'Position', ...
            [sliderWidth+margin+8, currentY, 30, sliderHeight]);
        currentY = currentY - (sliderHeight + elementSpacing + 4);
        % Shape control label and controls
        set(data.controlElements.concaveLabel, 'Units', 'pixels');
        set(data.controlElements.concaveLabel, 'Position', ...
            [margin, currentY, panelWidth-2*margin, labelHeight]);
        currentY = currentY - (labelHeight + 4);
        set(data.concavenessSlider, 'Units', 'pixels');
        set(data.concavenessSlider, 'Position', ...
            [margin, currentY, sliderWidth-40, sliderHeight]);
        set(data.concavenessValue, 'Units', 'pixels');
        set(data.concavenessValue, 'Position', ...
            [sliderWidth-35, currentY, 32, sliderHeight]);
        set(data.concavenessDesc, 'Units', 'pixels');
        set(data.concavenessDesc, 'Position', ...
            [sliderWidth+8, currentY-2, 60, sliderHeight+4]);
        currentY = currentY - (sliderHeight + elementSpacing + 4);
        % Checkboxes with adaptive spacing
        if isCompactMode
            checkboxHeight = 18;
            checkboxSpacing = 20;
        else
            checkboxHeight = 20;
            checkboxSpacing = 24;
        end
        set(data.simplifyBoundary, 'Units', 'pixels');
        set(data.simplifyBoundary, 'Position', ...
            [margin, currentY, panelWidth-2*margin, checkboxHeight]);
        currentY = currentY - checkboxSpacing;
        set(data.advancedSmoothing, 'Units', 'pixels');
        set(data.advancedSmoothing, 'Position', ...
            [margin, currentY, panelWidth-2*margin, checkboxHeight]);
    end
    function updateImagePanelLayout()
        % Update image axes to fill panel with margin
        set(data.imageAxes, 'Position', [0.03 0.03 0.94 0.92]);
    end
    function showAbout(~, ~)
        % Create about dialog with software information
        aboutFig = figure('Name', 'About SAM Interactive GUI', ...
            'Position', [300, 200, 600, 500], ...
            'MenuBar', 'none', ...
            'ToolBar', 'none', ...
            'Resize', 'off', ...
            'Color', [0.94 0.94 0.94], ...
            'WindowStyle', 'modal');
        % Create main panel
        mainPanel = uipanel(aboutFig, 'Position', [0 0 1 1], ...
            'BorderType', 'none', 'BackgroundColor', [0.94 0.94 0.94]);
        % Title
        titleText = uicontrol(mainPanel, 'Style', 'text', ...
            'String', 'SAM Interactive Segmentation Tool', ...
            'Units', 'normalized', ...
            'Position', [0.1 0.85 0.8 0.1], ...
            'FontSize', 16, 'FontWeight', 'bold', ...
            'BackgroundColor', [0.94 0.94 0.94], ...
            'ForegroundColor', [0.2 0.2 0.8]);
        % Version and build info
        versionText = uicontrol(mainPanel, 'Style', 'text', ...
            'String', 'Version 1.0', ...
            'Units', 'normalized', ...
            'Position', [0.1 0.78 0.8 0.05], ...
            'FontSize', 12, 'FontWeight', 'bold', ...
            'BackgroundColor', [0.94 0.94 0.94], ...
            'ForegroundColor', [0.4 0.4 0.4]);
        % Main description - using listbox for scrollability
        descText = uicontrol(mainPanel, 'Style', 'listbox', ...
            'String', getAboutText(), ...
            'Units', 'normalized', ...
            'Position', [0.1 0.25 0.8 0.5], ...
            'FontSize', 10, ...
            'BackgroundColor', 'white', ...
            'Max', 2, ...  % Allow scrolling
            'Enable', 'on');
        % System info
        sysInfo = getSystemInfo();
        sysText = uicontrol(mainPanel, 'Style', 'text', ...
            'String', sysInfo, ...
            'Units', 'normalized', ...
            'Position', [0.1 0.15 0.8 0.08], ...
            'FontSize', 9, ...
            'BackgroundColor', [0.95 0.95 0.95], ...
            'HorizontalAlignment', 'left', ...
            'ForegroundColor', [0.3 0.3 0.3]);
        % Close button
        closeBtn = uicontrol(mainPanel, 'Style', 'pushbutton', ...
            'String', 'Close', ...
            'Units', 'normalized', ...
            'Position', [0.45 0.02 0.1 0.08], ...
            'FontSize', 11, ...
            'BackgroundColor', [0.2 0.6 1.0], ...
            'ForegroundColor', 'white', ...
            'Callback', @(~,~) close(aboutFig));
    end
    function resetSettings(~, ~)
        % Reset all data values
        data.selectionMethod = 1;
        data.minAreaThreshold = 50;
        data.cleanComponents = true;
        data.smoothingLevel = 2;
        data.concavenessLevel = 5;
        data.simplifyBoundaryFlag = true;
        data.advancedSmoothingFlag = false;
        % Reset radio button
        set(data.method1Radio, 'Value', 1);
        % Method 1: Reset smoothing slider with forced visual update
        oldSmoothPos = get(data.smoothingSlider, 'Position');
        oldSmoothParent = get(data.smoothingSlider, 'Parent');
        delete(data.smoothingSlider);
        data.smoothingSlider = uicontrol(oldSmoothParent, 'Style', 'slider', ...
            'Min', 0, 'Max', 20, 'Value', 2, ...
            'SliderStep', [0.05 0.1], ...
            'BackgroundColor', [0.9 0.9 0.9], ...
            'Units', 'pixels', ...
            'Position', oldSmoothPos, ...
            'Callback', @smoothingChanged);
        % Method 1: Reset concaveness slider with forced visual update
        oldConcavePos = get(data.concavenessSlider, 'Position');
        oldConcaveParent = get(data.concavenessSlider, 'Parent');
        delete(data.concavenessSlider);
        data.concavenessSlider = uicontrol(oldConcaveParent, 'Style', 'slider', ...
            'Min', -1, 'Max', 10, 'Value', 5, ...
            'SliderStep', [0.05 0.1], ...
            'BackgroundColor', [0.9 0.9 0.9], ...
            'Units', 'pixels', ...
            'Position', oldConcavePos, ...
            'Callback', @concavenessChanged);
        % Update display values
        smoothingChanged([], []); % Update display text
        concavenessChanged([], []); % Update display text
        % Reset checkboxes
        set(data.simplifyBoundary, 'Value', 1);
        set(data.advancedSmoothing, 'Value', 0);
        % Final refresh
        drawnow;
        updateStatus('Settings reset to defaults.');
    end
    function showHelp(~, ~)
        % Create help dialog with comprehensive information about selection methods
        helpFig = figure('Name', 'SAM Interactive GUI - Help', ...
            'Position', [200, 100, 800, 600], ...
            'MenuBar', 'none', ...
            'ToolBar', 'none', ...
            'Resize', 'on', ...
            'Color', [0.94 0.94 0.94], ...
            'WindowStyle', 'normal');
        % Create main panel with scrollable content
        mainPanel = uipanel(helpFig, 'Position', [0 0 1 1], ...
            'BorderType', 'none', 'BackgroundColor', [0.94 0.94 0.94]);
        % Create scrollable listbox for help text (this provides scrolling)
        helpText = uicontrol(mainPanel, 'Style', 'listbox', ...
            'Units', 'normalized', ...
            'Position', [0.02 0.15 0.96 0.83], ...
            'BackgroundColor', 'white', ...
            'FontSize', 10, ...
            'FontName', 'Courier New', ...  % Monospace font for better formatting
            'String', getHelpText(), ...
            'Max', 2, ...  % Allow multiple selection (for copy functionality)
            'Enable', 'on');
        % Create close button
        closeBtn = uicontrol(mainPanel, 'Style', 'pushbutton', ...
            'String', 'Close', ...
            'Units', 'normalized', ...
            'Position', [0.45 0.02 0.1 0.08], ...
            'FontSize', 11, ...
            'BackgroundColor', [0.2 0.6 1.0], ...
            'ForegroundColor', 'white', ...
            'Callback', @(~,~) close(helpFig));
        % Make figure modal
        set(helpFig, 'WindowStyle', 'modal');
    end
    function name = getMethodName(method)
        switch method
            case 1
                name = 'Click-Point Based';
            case 2
                name = 'Distance-Based';
            case 3
                name = 'Largest Only';
            otherwise
                name = 'Unknown';
        end
    end
    function loadImage(~, ~)
        updateStatus('Loading image...');
        [filename, pathname] = uigetfile({'*.jpg;*.jpeg;*.png;*.bmp;*.tiff;*.gif', ...
            'Image Files (*.jpg, *.jpeg, *.png, *.bmp, *.tiff, *.gif)'}, ...
            'Select an image');
        if isequal(filename, 0)
            updateStatus('Image loading cancelled.');
            return;
        end
        % Load and process image
        fullpath = fullfile(pathname, filename);
        updateStatus('Reading image file...');
        data.image = imread(fullpath);
        % Convert to RGB if needed
        if size(data.image, 3) == 1
            data.image = repmat(data.image, [1, 1, 3]);
        end
        data.imageSize = size(data.image);
        % Clear previous results
        clearAllObjects();
        % Load SAM model if not already loaded
        if isempty(data.sam)
            updateStatus('Loading SAM model...');
            if ~exist('segmentAnythingModel', 'file')
                updateStatus('ERROR: segmentAnythingModel not found. Please ensure Computer Vision Toolbox is installed.');
                return;
            end
            data.sam = segmentAnythingModel();
            set(data.modelStatus, 'String', 'Loaded', 'ForegroundColor', [0 0.6 0]);
            updateStatus('SAM model loaded successfully.');
        end
        % Extract embeddings
        updateStatus('Extracting embeddings...');
        data.embeddings = extractEmbeddings(data.sam, data.image);
        % Display image
        displayImage();
        updateStatus(sprintf('Image loaded. Method: %s. Click on objects to segment.', getMethodName(data.selectionMethod)));
    end
    function displayImage()
        if isempty(data.image)
            return;
        end

        % Clear axes first
        cla(data.imageAxes);

        % Display image and get handle
        data.imageHandle = imshow(data.image, 'Parent', data.imageAxes);
        hold(data.imageAxes, 'on');

        % Set up click callbacks on both axes and image
        set(data.imageAxes, 'ButtonDownFcn', @imageClick);
        set(data.imageHandle, 'ButtonDownFcn', @imageClick);
        set(data.imageAxes, 'HitTest', 'on');
        set(data.imageHandle, 'HitTest', 'on');

        % Check if we have both masks and points, and they match in size
        numMasks = size(data.allMasks, 3);
        numPoints = size(data.allPoints, 1);

        % Only display overlays if we have valid data
        if numMasks > 0 && numPoints > 0 && numMasks == numPoints
            % Display all masks and points
            for i = 1:numMasks
                mask = data.allMasks(:, :, i);
                colorIdx = mod(i-1, length(data.colors)) + 1;

                % Draw boundary
                visboundaries(data.imageAxes, mask, 'Color', data.colors{colorIdx}, 'LineWidth', 2);

                % Draw point
                pointHandle = plot(data.imageAxes, data.allPoints(i,1), data.allPoints(i,2), 'o', ...
                    'Color', data.colors{colorIdx}, 'MarkerSize', 8, 'LineWidth', 2, ...
                    'MarkerFaceColor', data.colors{colorIdx});
                set(pointHandle, 'HitTest', 'off'); % Allow clicks to pass through

                % Add label
                textHandle = text(data.allPoints(i,1)+5, data.allPoints(i,2)-5, sprintf('%d', i), ...
                    'Parent', data.imageAxes, 'Color', 'white', 'FontSize', 12, ...
                    'FontWeight', 'bold', 'BackgroundColor', 'black');
                set(textHandle, 'HitTest', 'off'); % Allow clicks to pass through
            end
        elseif numMasks ~= numPoints && (numMasks > 0 || numPoints > 0)
            % Data inconsistency detected - clear both to prevent further issues
            data.allMasks = [];
            data.allPoints = [];
            data.objectCount = 0;
        end

        hold(data.imageAxes, 'off');

        % Update title with method info
        methodName = getMethodName(data.selectionMethod);
        title(data.imageAxes, sprintf('Method: %s | Objects: %d | Click to segment', ...
            methodName, data.objectCount));

        % Force axes to be clickable
        set(data.imageAxes, 'PickableParts', 'all');
        if isfield(data, 'imageHandle') && isvalid(data.imageHandle)
            set(data.imageHandle, 'PickableParts', 'visible');
        end
    end
    function concavenessChanged(~, ~)
        data.concavenessLevel = get(data.concavenessSlider, 'Value');
        set(data.concavenessValue, 'String', sprintf('%.1f', data.concavenessLevel));

        % Update descriptive text based on concaveness level
        if data.concavenessLevel < 0
            desc = 'Force Convex';
            color = [0.8 0.2 0.2];  % Red
        elseif data.concavenessLevel < 2
            desc = 'Very Convex';
            color = [0.8 0.4 0.2];  % Orange
        elseif data.concavenessLevel < 4
            desc = 'Mostly Convex';
            color = [0.6 0.6 0.2];  % Yellow-green
        elseif data.concavenessLevel < 6
            desc = 'Balanced';
            color = [0.2 0.6 0.2];  % Green
        elseif data.concavenessLevel < 8
            desc = 'Allow Concave';
            color = [0.2 0.4 0.6];  % Blue
        else
            desc = 'Very Concave';
            color = [0.4 0.2 0.8];  % Purple
        end

        set(data.concavenessDesc, 'String', desc, 'ForegroundColor', color);

        updateStatus(sprintf('Shape control: %.1f (%s)', data.concavenessLevel, desc));
    end
    function smoothingChanged(~, ~)
        data.smoothingLevel = get(data.smoothingSlider, 'Value');
        set(data.smoothingValue, 'String', sprintf('%.1f', data.smoothingLevel));
        % Enhanced descriptive feedback for extended range
        if data.smoothingLevel < 0.5
            desc = 'Original (Pixel Perfect)';
        elseif data.smoothingLevel < 2
            desc = 'Minimal Smoothing';
        elseif data.smoothingLevel < 5
            desc = 'Light Smoothing';
        elseif data.smoothingLevel < 8
            desc = 'Moderate Smoothing';
        elseif data.smoothingLevel < 12
            desc = 'Heavy Smoothing';
        elseif data.smoothingLevel < 16
            desc = 'Very Heavy Smoothing';
        else
            desc = 'Maximum (Rough Polygon)';
        end
        updateStatus(sprintf('Smoothing level: %.1f (%s)', data.smoothingLevel, desc));
    end
    function simplifyChanged(~, ~)
        data.simplifyBoundaryFlag = get(data.simplifyBoundary, 'Value');
        status = 'disabled';
        if data.simplifyBoundaryFlag
            status = 'enabled';
        end
        updateStatus(sprintf('Boundary simplification %s', status));
    end
    function advancedSmoothingChanged(~, ~)
        data.advancedSmoothingFlag = get(data.advancedSmoothing, 'Value');
        status = 'disabled';
        if data.advancedSmoothingFlag
            status = 'enabled';
        end
        updateStatus(sprintf('Advanced smoothing %s', status));
    end
    function methodChanged(~, eventdata)
        % Callback for selection method change
        switch eventdata.NewValue.Tag
            case 'method1'
                data.selectionMethod = 1;
                updateStatus('Selection method: Click-Point Based');
            case 'method2'
                data.selectionMethod = 2;
                updateStatus('Selection method: Distance-Based');
            case 'method3'
                data.selectionMethod = 3;
                updateStatus('Selection method: Largest Component');
        end
    end
    function imageClick(~, ~)
        if isempty(data.image)
            updateStatus('Please load an image first.');
            return;
        end

        if isempty(data.embeddings)
            updateStatus('Embeddings not ready. Please reload the image.');
            return;
        end

        if data.isProcessing
            return;
        end

        % Get click coordinates
        point = get(data.imageAxes, 'CurrentPoint');
        x = point(1,1);
        y = point(1,2);

        % Validate click is within image bounds
        if x < 0.5 || x > data.imageSize(2) + 0.5 || y < 0.5 || y > data.imageSize(1) + 0.5
            updateStatus('Click is outside image boundaries.');
            return;
        end

        % Round coordinates to pixel centers
        x = round(x);
        y = round(y);

        % Check if click is on already segmented area
        if data.objectCount > 0
            exclusionMask = createExclusionMask(data);
            if exclusionMask(y, x)
                updateStatus('Cannot segment: Click is on already segmented area. Try clicking elsewhere.');
                return;
            end
        end

        data.isProcessing = true;
        updateStatus(sprintf('Processing click at [%d, %d] with method %d...', x, y, data.selectionMethod));

        % Segment the clicked object
        clickPoint = [x, y];
        masks = segmentObjectsFromEmbeddings(data.sam, data.embeddings, data.imageSize, ...
            'ForegroundPoints', clickPoint);

        if ~isempty(masks) && any(masks(:))
            % Create exclusion mask before processing
            exclusionMask = createExclusionMask(data);

            % Select main object based on chosen method
            finalMask = selectMainObjectByMethodNoOverlap(masks, x, y, data.selectionMethod, exclusionMask);

            if ~isempty(finalMask) && any(finalMask(:))
                data.objectCount = data.objectCount + 1;

                % Store the point and mask
                data.allPoints = [data.allPoints; x, y];
                data.allMasks = cat(3, data.allMasks, finalMask);

                % Calculate mask area
                maskArea = sum(finalMask(:));

                % Update object list
                updateObjectList();

                % Update display
                displayImage();

                % Enable buttons
                set(data.clearLastBtn, 'Enable', 'on');
                set(data.clearAllBtn, 'Enable', 'on');
                set(data.saveBtn, 'Enable', 'on');
                set(data.exportBtn, 'Enable', 'on');
                set(findobj(data.fileMenu, 'Label', 'Save Results'), 'Enable', 'on');
                set(findobj(data.fileMenu, 'Label', 'Export Masks'), 'Enable', 'on');

                methodNames = {'Click-Point Based', 'Distance-Based', 'Largest Component'};
                updateStatus(sprintf('Object %d segmented using %s! Area: %d pixels (non-overlapping)', ...
                    data.objectCount, methodNames{data.selectionMethod}, maskArea));
            else
                updateStatus('No valid non-overlapping object found at clicked location. Try another spot.');
            end
        else
            updateStatus('No object found at clicked location. Try another spot.');
        end

        data.isProcessing = false;
    end
    function updateObjectList()
        objectStrings = cell(data.objectCount, 1);
        for i = 1:data.objectCount
            mask = data.allMasks(:, :, i);
            area = sum(mask(:));
            objectStrings{i} = sprintf('Object %d: [%.0f,%.0f] Area:%d', ...
                i, data.allPoints(i,1), data.allPoints(i,2), area);
        end
        set(data.objectList, 'String', objectStrings);
        set(data.segmentInfo, 'String', sprintf('Objects segmented: %d', data.objectCount));
    end
    function clearLastObject(~, ~)
        if data.objectCount > 0
            data.objectCount = data.objectCount - 1;
            data.allPoints(end, :) = [];
            data.allMasks(:, :, end) = [];

            updateObjectList();
            displayImage();

            if data.objectCount == 0
                set(data.clearLastBtn, 'Enable', 'off');
                set(data.clearAllBtn, 'Enable', 'off');
                set(data.saveBtn, 'Enable', 'off');
                set(data.exportBtn, 'Enable', 'off');
                set(findobj(data.fileMenu, 'Label', 'Save Results'), 'Enable', 'off');
                set(findobj(data.fileMenu, 'Label', 'Export Masks'), 'Enable', 'off');
            end

            updateStatus('Last object cleared.');
        end
    end
    function clearAll(~, ~)
        clearAllObjects();
        if ~isempty(data.image)
            displayImage();
        end
        updateStatus('All objects cleared.');
    end
    function clearAllObjects()
        data.allMasks = [];
        data.allPoints = [];
        data.objectCount = 0;

        set(data.objectList, 'String', {});
        set(data.segmentInfo, 'String', 'Objects segmented: 0');

        set(data.clearLastBtn, 'Enable', 'off');
        set(data.clearAllBtn, 'Enable', 'off');
        set(data.saveBtn, 'Enable', 'off');
        set(data.exportBtn, 'Enable', 'off');
        set(findobj(data.fileMenu, 'Label', 'Save Results'), 'Enable', 'off');
        set(findobj(data.fileMenu, 'Label', 'Export Masks'), 'Enable', 'off');
    end
    function saveResults(~, ~)
        if data.objectCount == 0
            updateStatus('No objects to save.');
            return;
        end

        [filename, pathname] = uiputfile('*.mat', 'Save segmentation results');
        if isequal(filename, 0)
            return;
        end

        % Prepare data to save
        results = struct();
        results.image = data.image;
        results.masks = data.allMasks;
        results.points = data.allPoints;
        results.objectCount = data.objectCount;
        results.imageSize = data.imageSize;
        results.selectionMethod = data.selectionMethod;

        % Save to MAT file
        fullpath = fullfile(pathname, filename);
        save(fullpath, 'results');

        % Also save visualization
        [~, name, ~] = fileparts(filename);
        imgPath = fullfile(pathname, [name '_visualization.png']);

        % Create figure for saving
        tempFig = figure('Visible', 'off');
        imshow(data.image);
        hold on;

        for i = 1:size(data.allMasks, 3)
            mask = data.allMasks(:, :, i);
            colorIdx = mod(i-1, length(data.colors)) + 1;
            visboundaries(mask, 'Color', data.colors{colorIdx}, 'LineWidth', 2);
        end
        hold off;

        saveas(tempFig, imgPath);
        close(tempFig);

        updateStatus(['Results saved to ' filename ' and visualization saved.']);
    end
    function exportMasks(~, ~)
        if data.objectCount == 0
            updateStatus('No masks to export.');
            return;
        end

        pathname = uigetdir(pwd, 'Select folder to export masks');
        if isequal(pathname, 0)
            return;
        end

        % Export individual masks
        for i = 1:size(data.allMasks, 3)
            mask = data.allMasks(:, :, i);
            maskFilename = fullfile(pathname, sprintf('mask_%02d.png', i));
            imwrite(uint8(mask * 255), maskFilename);
        end

        % Export combined mask - FIXED VERSION
        combinedMask = zeros(data.imageSize(1), data.imageSize(2), 'uint8');
        for i = 1:size(data.allMasks, 3)
            % Convert logical mask to linear indices and assign object ID
            maskIndices = find(data.allMasks(:, :, i));
            combinedMask(maskIndices) = i;
        end
        imwrite(combinedMask, fullfile(pathname, 'combined_masks.png'));

        % Export points and info
        writematrix(data.allPoints, fullfile(pathname, 'points.csv'));
        methodNames = {'Click-Point Based', 'Distance-Based', 'Largest Component'};
        fid = fopen(fullfile(pathname, 'segmentation_info.txt'), 'w');
        fprintf(fid, 'SAM Interactive Segmentation Results\n====================================\n');
        fprintf(fid, 'Selection Method: %s\nNumber of Objects: %d\nImage Size: %dx%dx%d\n\nObject Details:\n', ...
            methodNames{data.selectionMethod}, data.objectCount, data.imageSize(1), data.imageSize(2), data.imageSize(3));

        for i = 1:data.objectCount
            area = sum(data.allMasks(:, :, i), 'all');
            fprintf(fid, 'Object %d: Point [%d,%d], Area: %d pixels\n', ...
                i, data.allPoints(i,1), data.allPoints(i,2), area);
        end
        fclose(fid);

        updateStatus(sprintf('Exported %d individual masks, combined mask, points and info to %s', ...
            data.objectCount, pathname));
    end
    function updateStatus(message)
        set(data.statusText, 'String', message);
        drawnow;
    end
    function closeApp(~, ~)
        delete(data.mainFig);
    end
    function smartMask = createSmartMask(mask, forceConvex)
        if nargin < 2
            forceConvex = false;
        end
        if ~any(mask(:))
            smartMask = mask;
            return;
        end
        % Check if we should force convex based on concaveness level
        if isfield(data, 'concavenessLevel') && data.concavenessLevel < 0
            forceConvex = true;
        end
        if forceConvex
            % Force convex hull if explicitly requested
            smartMask = createConvexMask(mask);
            return;
        end
        % Apply smoothing based on user settings with enhanced parameters
        if isfield(data, 'smoothingLevel') && isfield(data, 'concavenessLevel') && ...
                isfield(data, 'simplifyBoundaryFlag') && isfield(data, 'advancedSmoothingFlag')
            smartMask = createEnhancedSmoothPolygon(mask, data.smoothingLevel, ...
                data.concavenessLevel, data.simplifyBoundaryFlag, data.advancedSmoothingFlag);
        else
            % Fallback to default smoothing
            smartMask = createEnhancedSmoothPolygon(mask, 2, 5, true, false);
        end
        % Quality check - ensure we don't lose too much area
        originalArea = sum(mask(:));
        smoothArea = sum(smartMask(:));
        if smoothArea < 0.3 * originalArea
            % If we lost too much area, use lighter processing
            smoothMask = createEnhancedSmoothPolygon(mask, max(1, data.smoothingLevel-2), ...
                max(3, data.concavenessLevel-2), false, false);
        end
        % Final fallback
        if ~any(smartMask(:))
            smartMask = keepLargestComponent(mask);
        end
    end
    function smoothMask = createEnhancedSmoothPolygon(mask, smoothingLevel, concavenessLevel, simplifyBoundary, advancedSmoothing)
        if ~any(mask(:))
            smoothMask = mask;
            return;
        end
        cleanMask = keepLargestComponent(mask);
        if ~any(cleanMask(:))
            smoothMask = mask;
            return;
        end
        % Force convex hull if concaveness level is negative
        if concavenessLevel < 0
            smoothMask = createConvexMask(cleanMask);
            return;
        end
        if advancedSmoothing
            smoothMask = createAdvancedGaussianSmoothedMask(cleanMask, smoothingLevel, concavenessLevel);
        else
            smoothMask = createEnhancedMorphologicalSmoothedMask(cleanMask, smoothingLevel, concavenessLevel, simplifyBoundary);
        end
        % Ensure we have a valid result
        if ~any(smoothMask(:))
            smoothMask = cleanMask;
        end
    end
    function smoothMask = createEnhancedMorphologicalSmoothedMask(mask, smoothingLevel, concavenessLevel, simplifyBoundary)
        smoothMask = mask;
        if smoothingLevel < 0.5
            smoothMask = imfill(smoothMask, 'holes');
            return;
        end
        % Force convex hull immediately if concaveness level is negative
        if concavenessLevel < 0
            smoothMask = createConvexMask(smoothMask);
            return;
        end
        % Calculate radii based on smoothing level
        baseRadius = max(1, round(smoothingLevel * 2));
        smallRadius = max(1, round(smoothingLevel * 1.2));
        largeRadius = max(2, round(smoothingLevel * 2.5));
        % Step 1: Initial closing and hole filling
        if smoothingLevel >= 1
            se = strel('disk', smallRadius);
            smoothMask = imclose(smoothMask, se);
            smoothMask = imfill(smoothMask, 'holes');
        end
        % Step 2: Enhanced concaveness-based processing
        if concavenessLevel <= 1  % Very convex (aggressive convexing)
            % Very aggressive closing to eliminate most concavities
            se1 = strel('disk', largeRadius * 2);  % Extra large radius
            se2 = strel('disk', baseRadius);
            smoothMask = imclose(smoothMask, se1);
            smoothMask = imopen(smoothMask, se2);
            smoothMask = imclose(smoothMask, se1);
            % Additional convexing step
            smoothMask = applyPartialConvexHull(smoothMask, 0.8);  % 80% towards convex
        elseif concavenessLevel <= 3  % Mostly convex
            % Aggressive closing to eliminate concavities
            se1 = strel('disk', largeRadius);
            se2 = strel('disk', baseRadius);
            smoothMask = imclose(smoothMask, se1);
            smoothMask = imopen(smoothMask, se2);
            smoothMask = imclose(smoothMask, se1);
            % Mild convexing
            smoothMask = applyPartialConvexHull(smoothMask, 0.3);  % 30% towards convex
        elseif concavenessLevel <= 6  % Balanced processing
            se1 = strel('disk', baseRadius);
            se2 = strel('disk', smallRadius);
            smoothMask = imclose(smoothMask, se1);
            smoothMask = imopen(smoothMask, se2);
            smoothMask = imclose(smoothMask, se1);
        elseif concavenessLevel <= 8  % Allow concave (preserve details)
            % Light processing to preserve concavities
            se = strel('disk', smallRadius);
            smoothMask = imopen(smoothMask, se);
            smoothMask = imclose(smoothMask, se);
        else  % Very concave (minimal processing)
            % Very minimal processing - only remove small noise
            se = strel('disk', 1);
            smoothMask = imopen(smoothMask, se);
            smoothMask = imclose(smoothMask, se);
        end
        % Step 3: Additional smoothing for high levels (but respect concaveness)
        if smoothingLevel >= 4 && concavenessLevel >= 0
            extraRadius = max(1, round(smoothingLevel * 0.8));
            se = strel('disk', extraRadius);

            if concavenessLevel <= 4
                smoothMask = imclose(smoothMask, se);
            else
                smoothMask = imopen(smoothMask, se);
                smoothMask = imclose(smoothMask, se);
            end
        end
        % Step 4: Boundary simplification (adjusted for concaveness)
        if simplifyBoundary && smoothingLevel >= 1.5
            tolerance = smoothingLevel * 2;
            % Reduce tolerance for high concaveness to preserve details
            if concavenessLevel > 7
                tolerance = tolerance * 0.5;
            end
            smoothMask = simplifyEnhancedPolygonBoundary(smoothMask, tolerance, concavenessLevel);
        end
        % Final cleanup
        smoothMask = keepLargestComponent(smoothMask);
        smoothMask = imfill(smoothMask, 'holes');
    end
    function mainMask = selectMainObjectByMethodNoOverlap(masks, clickX, clickY, method, exclusionMask)
        if isempty(masks) || ~any(masks(:))
            mainMask = [];
            return;
        end
        cleanedMasks = preprocessMasksSmartNoOverlap(masks, exclusionMask);
        if isempty(cleanedMasks)
            mainMask = [];
            return;
        end
        if size(cleanedMasks, 3) == 1
            mainMask = removeOverlapRegions(cleanedMasks(:, :, 1), exclusionMask);
            return;
        end
        switch method
            case 1
                mainMask = selectMainObjectClickPointSmartNoOverlap(cleanedMasks, clickX, clickY, exclusionMask);
            case 2
                mainMask = selectMainObjectDistanceSmartNoOverlap(cleanedMasks, clickX, clickY, exclusionMask);
            case 3
                mainMask = selectMainObjectLargestSmartNoOverlap(cleanedMasks, exclusionMask);
            otherwise
                mainMask = selectMainObjectClickPointSmartNoOverlap(cleanedMasks, clickX, clickY, exclusionMask);
        end

        if ~isempty(mainMask) && any(mainMask(:))
            mainMask = removeOverlapRegions(mainMask, exclusionMask);
        end
    end
    function cleanedMasks = preprocessMasksSmartNoOverlap(masks, exclusionMask)
        minAreaThreshold = 200;
        cleanedMasks = [];
        for i = 1:size(masks, 3)
            currentMask = removeOverlapRegions(masks(:, :, i), exclusionMask);
            if ~any(currentMask(:))
                continue;
            end
            currentMask = keepLargestComponent(currentMask);

            if sum(currentMask(:)) < minAreaThreshold
                continue;
            end
            smartMask = createSmartMask(currentMask, false);
            smartMask = removeOverlapRegions(smartMask, exclusionMask);

            if sum(smartMask(:)) >= minAreaThreshold
                if isempty(cleanedMasks)
                    cleanedMasks = smartMask;
                else
                    cleanedMasks = cat(3, cleanedMasks, smartMask);
                end
            end
        end
    end
    function mainMask = selectMainObjectClickPointSmartNoOverlap(masks, clickX, clickY, exclusionMask)
        validMasks = [];
        validAreas = [];
        validDistances = [];
        for i = 1:size(masks, 3)
            currentMask = removeOverlapRegions(masks(:, :, i), exclusionMask);
            if ~any(currentMask(:))
                continue;
            end
            if currentMask(clickY, clickX)
                validMasks = [validMasks, i];
                validAreas = [validAreas, sum(currentMask(:))];

                [rows, cols] = find(currentMask);
                if ~isempty(rows)
                    centroidY = mean(rows);
                    centroidX = mean(cols);
                    distance = sqrt((centroidX - clickX)^2 + (centroidY - clickY)^2);
                    validDistances = [validDistances, distance];
                else
                    validDistances = [validDistances, inf];
                end
            end
        end
        if ~isempty(validMasks)
            areaScores = validAreas / max(validAreas);
            distanceScores = 1 ./ (1 + validDistances);
            combinedScores = 0.8 * areaScores + 0.2 * distanceScores;
            [~, maxIdx] = max(combinedScores);
            selectedMaskIdx = validMasks(maxIdx);
            mainMask = removeOverlapRegions(masks(:, :, selectedMaskIdx), exclusionMask);
        else
            areas = zeros(size(masks, 3), 1);
            for i = 1:size(masks, 3)
                tempMask = removeOverlapRegions(masks(:, :, i), exclusionMask);
                areas(i) = sum(tempMask(:));
            end
            [maxArea, maxIdx] = max(areas);
            if maxArea > 0
                mainMask = removeOverlapRegions(masks(:, :, maxIdx), exclusionMask);
            else
                mainMask = false(size(masks, 1), size(masks, 2));
            end
        end
    end
    function mainMask = selectMainObjectDistanceSmartNoOverlap(masks, clickX, clickY, exclusionMask)
        distances = zeros(size(masks, 3), 1);
        areas = zeros(size(masks, 3), 1);
        for i = 1:size(masks, 3)
            processedMask = removeOverlapRegions(masks(:, :, i), exclusionMask);
            areas(i) = sum(processedMask(:));
            if areas(i) > 0
                [rows, cols] = find(processedMask);
                centroidY = mean(rows);
                centroidX = mean(cols);
                distances(i) = sqrt((centroidX - clickX)^2 + (centroidY - clickY)^2);
            else
                distances(i) = inf;
            end
        end
        minAreaThreshold = 100;
        validMasks = areas > minAreaThreshold;
        if any(validMasks)
            normalizedAreas = areas / max(areas);
            normalizedDistances = 1 ./ (1 + distances);
            combinedScores = 0.6 * normalizedDistances + 0.4 * normalizedAreas;
            combinedScores(~validMasks) = 0;
            [~, maxIdx] = max(combinedScores);
            mainMask = removeOverlapRegions(masks(:, :, maxIdx), exclusionMask);
        else
            [maxArea, maxIdx] = max(areas);
            if maxArea > 0
                mainMask = removeOverlapRegions(masks(:, :, maxIdx), exclusionMask);
            else
                mainMask = false(size(masks, 1), size(masks, 2));
            end
        end
    end
    function mainMask = selectMainObjectLargestSmartNoOverlap(masks, exclusionMask)
        areas = zeros(size(masks, 3), 1);
        compactness = zeros(size(masks, 3), 1);
        for i = 1:size(masks, 3)
            processedMask = removeOverlapRegions(masks(:, :, i), exclusionMask);
            areas(i) = sum(processedMask(:));
            if areas(i) > 0
                stats = regionprops(processedMask, 'Area', 'Perimeter');
                if ~isempty(stats) && stats.Perimeter > 0
                    compactness(i) = 4 * pi * stats.Area / (stats.Perimeter^2);
                else
                    compactness(i) = 0;
                end
            end
        end
        if max(areas) > 0
            normalizedAreas = areas / max(areas);
            normalizedCompactness = compactness / max(max(compactness), 1);
            combinedScores = 0.8 * normalizedAreas + 0.2 * normalizedCompactness;
            [~, maxIdx] = max(combinedScores);
            mainMask = removeOverlapRegions(masks(:, :, maxIdx), exclusionMask);
        else
            mainMask = false(size(masks, 1), size(masks, 2));
        end
    end
    function partialConvexMask = applyPartialConvexHull(mask, convexRatio)
        % Apply partial convex hull transformation
        % convexRatio: 0 = original mask, 1 = full convex hull
        if ~any(mask(:)) || convexRatio <= 0
            partialConvexMask = mask;
            return;
        end
        if convexRatio >= 1
            partialConvexMask = createConvexMask(mask);
            return;
        end
        % Get convex hull
        convexMask = createConvexMask(mask);
        % Blend between original and convex hull
        % Use distance transform for smooth blending
        originalDist = bwdist(~mask);
        convexDist = bwdist(~convexMask);
        % Create blended distance field
        blendedDist = (1 - convexRatio) * originalDist + convexRatio * convexDist;
        % Create mask from blended distance
        partialConvexMask = blendedDist > 0;
        % Ensure we don't lose the original shape completely
        partialConvexMask = partialConvexMask | mask;
    end
end
%% Helper Functinos
function convexMask = createConvexMask(mask)
% Create a proper convex hull mask
if ~any(mask(:))
    convexMask = mask;
    return;
end

% Clean the mask first
cleanMask = keepLargestComponent(mask);

% Get boundary points
[rows, cols] = find(cleanMask);

if isempty(rows)
    convexMask = mask;
    return;
end

% Find convex hull
try
    points = [cols, rows]; % Note: convhull expects [x, y] format
    k = convhull(points);
    convexPoints = points(k, :);

    % Create mask from convex hull
    convexMask = poly2mask(convexPoints(:, 1), convexPoints(:, 2), ...
        size(mask, 1), size(mask, 2));
catch
    % Fallback if convhull fails
    convexMask = cleanMask;
end
end
function cleanMask = keepLargestComponent(mask)
if ~any(mask(:))
    cleanMask = mask;
    return;
end
% Use 8-connectivity for better component detection
CC = bwconncomp(mask, 8);

if CC.NumObjects == 0
    cleanMask = false(size(mask));
    return;
end
if CC.NumObjects == 1
    cleanMask = mask;
    return;
end
% Find largest component by area
numPixels = cellfun(@numel, CC.PixelIdxList);
[~, maxIdx] = max(numPixels);
% Create mask with only largest component
cleanMask = false(size(mask));
cleanMask(CC.PixelIdxList{maxIdx}) = true;
% Apply light morphological smoothing
se = strel('disk', 1);
cleanMask = imclose(cleanMask, se); % Connect nearby regions
cleanMask = imfill(cleanMask, 'holes'); % Fill holes
end
function cleanMask = morphologicalCleanup(mask, intensity)
if ~any(mask(:))
    cleanMask = mask;
    return;
end
switch intensity
    case 'minimal'
        se = strel('disk', 1);
        cleanMask = imclose(mask, se);
        cleanMask = imfill(cleanMask, 'holes');

    case 'light'
        se1 = strel('disk', 1);
        cleanMask = imclose(mask, se1);
        cleanMask = imfill(cleanMask, 'holes');
        cleanMask = imopen(cleanMask, se1);
        if sum(mask(:)) > 1000
            se2 = strel('disk', 2);
            cleanMask = imclose(cleanMask, se2);
        end

    case 'moderate'
        se1 = strel('disk', 2);
        se2 = strel('disk', 3);
        cleanMask = imclose(mask, se1);
        cleanMask = imfill(cleanMask, 'holes');
        cleanMask = imopen(cleanMask, se1);
        cleanMask = imclose(cleanMask, se2);

    case 'aggressive'
        se1 = strel('disk', 3);
        se2 = strel('disk', 4);
        cleanMask = imclose(mask, se1);
        cleanMask = imfill(cleanMask, 'holes');
        cleanMask = imopen(cleanMask, se2);
        cleanMask = imclose(cleanMask, se2);

    otherwise
        cleanMask = morphologicalCleanup(mask, 'light');
end
end
function cleanMask = removeOverlapRegions(newMask, exclusionMask)
if isempty(newMask) || ~any(newMask(:))
    cleanMask = newMask;
    return;
end
% Remove overlapping areas
cleanMask = newMask & ~exclusionMask;
% If the mask becomes too fragmented or small, reject it
minValidArea = 100; % Minimum area to consider valid
if sum(cleanMask(:)) < minValidArea
    cleanMask = false(size(newMask));
    return;
end
% Keep only the largest connected component after overlap removal
cleanMask = keepLargestComponent(cleanMask);
% Final area check after component cleaning
if sum(cleanMask(:)) < minValidArea
    cleanMask = false(size(newMask));
end
end
function exclusionMask = createExclusionMask(data)
if data.objectCount == 0 || isempty(data.allMasks)
    exclusionMask = false(data.imageSize(1), data.imageSize(2));
    return;
end
% Combine all existing masks
exclusionMask = false(data.imageSize(1), data.imageSize(2));
for i = 1:size(data.allMasks, 3)
    exclusionMask = exclusionMask | data.allMasks(:, :, i);
end
% Optional: Add a small buffer around existing segments to prevent touching
bufferSize = 2; % pixels
if bufferSize > 0
    se = strel('disk', bufferSize);
    exclusionMask = imdilate(exclusionMask, se);
end
end
function smoothMask = createAdvancedGaussianSmoothedMask(mask, smoothingLevel, concavenessLevel)
if smoothingLevel < 0.5
    smoothMask = imfill(mask, 'holes');
    return;
end
% Create distance transform
distTransform = bwdist(~mask) - bwdist(mask);
% Enhanced sigma calculation based on smoothing level
sigma = smoothingLevel * 1.5; % More aggressive smoothing
% Apply Gaussian filtering
smoothedDist = imgaussfilt(distTransform, sigma);
% Concaveness control through threshold adjustment
concavenessFactor = (concavenessLevel - 5) / 10; % Range: -0.5 to 0.5
threshold = -smoothingLevel * 0.3 * concavenessFactor;
smoothMask = smoothedDist > threshold;
% Post-processing based on concaveness level
if concavenessLevel < 3 % More convex
    % Apply morphological closing to fill concavities
    se = strel('disk', max(2, round(smoothingLevel)));
    smoothMask = imclose(smoothMask, se);
elseif concavenessLevel > 7 % More concave
    % Apply morphological opening to preserve concavities
    se = strel('disk', max(1, round(smoothingLevel * 0.5)));
    smoothMask = imopen(smoothMask, se);
end
% Clean up the result
smoothMask = keepLargestComponent(smoothMask);
smoothMask = imfill(smoothMask, 'holes');
% Additional smoothing if level is high
if smoothingLevel > 5
    se = strel('disk', 1);
    smoothMask = imopen(smoothMask, se);
    smoothMask = imclose(smoothMask, se);
end
end
function simplifiedMask = simplifyEnhancedPolygonBoundary(mask, tolerance, ~)
if ~any(mask(:))
    simplifiedMask = mask;
    return;
end

% Get boundary
boundaries = bwboundaries(mask, 'noholes');
if isempty(boundaries)
    simplifiedMask = mask;
    return;
end

boundary = boundaries{1};

% Enhanced Douglas-Peucker simplification with extended tolerance range
if tolerance > 20
    % For very high tolerance (rough polygon mode), use aggressive decimation
    decimationFactor = max(3, round(tolerance / 8));
    if size(boundary, 1) > decimationFactor
        simplifiedBoundary = boundary(1:decimationFactor:end, :);
        % Ensure closed polygon
        if ~isequal(simplifiedBoundary(1, :), simplifiedBoundary(end, :))
            simplifiedBoundary = [simplifiedBoundary; simplifiedBoundary(1, :)];
        end
    else
        simplifiedBoundary = boundary;
    end
else
    % Use Douglas-Peucker algorithm for moderate simplification
    simplifiedBoundary = douglasPeucker(boundary, tolerance);
end

% Create simplified mask
if size(simplifiedBoundary, 1) >= 3
    simplifiedMask = poly2mask(simplifiedBoundary(:, 2), simplifiedBoundary(:, 1), ...
        size(mask, 1), size(mask, 2));

    % Fill holes and clean up
    simplifiedMask = imfill(simplifiedMask, 'holes');
else
    simplifiedMask = mask; % Fallback if simplification failed
end

% Quality check - if we lost too much area at extreme levels, it is acceptable
originalArea = sum(mask(:));
simplifiedArea = sum(simplifiedMask(:));

% Only fallback if we lost everything or almost everything
if simplifiedArea < 0.1 * originalArea
    simplifiedMask = mask;
end
end
function simplified = douglasPeuckerSimplify(points, epsilon)
if size(points, 1) <= 2
    simplified = points;
    return;
end
% Find the point with maximum distance from line segment
maxDist = 0;
maxIndex = 0;
for i = 2:(size(points, 1) - 1)
    dist = pointToLineDistance(points(i,:), points(1,:), points(end,:));
    if dist > maxDist
        maxDist = dist;
        maxIndex = i;
    end
end
% If max distance is greater than epsilon, recursively simplify
if maxDist > epsilon
    % Recursive call
    rec1 = douglasPeuckerSimplify(points(1:maxIndex, :), epsilon);
    rec2 = douglasPeuckerSimplify(points(maxIndex:end, :), epsilon);

    % Combine results (remove duplicate middle point)
    simplified = [rec1(1:end-1, :); rec2];
else
    simplified = [points(1,:); points(end,:)];
end
end
function dist = pointToLineDistance(point, lineStart, lineEnd)
% Calculate perpendicular distance from point to line segment
A = point(1) - lineStart(1);
B = point(2) - lineStart(2);
C = lineEnd(1) - lineStart(1);
D = lineEnd(2) - lineStart(2);

dot = A * C + B * D;
lenSq = C * C + D * D;

if lenSq == 0
    % Line segment is actually a point
    dist = sqrt(A * A + B * B);
    return;
end

param = dot / lenSq;

if param < 0
    xx = lineStart(1);
    yy = lineStart(2);
elseif param > 1
    xx = lineEnd(1);
    yy = lineEnd(2);
else
    xx = lineStart(1) + param * C;
    yy = lineStart(2) + param * D;
end

dx = point(1) - xx;
dy = point(2) - yy;
dist = sqrt(dx * dx + dy * dy);
end
function simplified = douglasPeucker(points, tolerance)
if size(points, 1) <= 2
    simplified = points;
    return;
end

% Find the point with maximum distance from line segment
firstPoint = points(1, :);
lastPoint = points(end, :);

maxDist = 0;
maxIndex = 0;

for i = 2:size(points, 1)-1
    dist = pointToLineDistance(points(i, :), firstPoint, lastPoint);
    if dist > maxDist
        maxDist = dist;
        maxIndex = i;
    end
end

% If max distance is greater than tolerance, recursively simplify
if maxDist > tolerance
    % Recursive call
    left = douglasPeucker(points(1:maxIndex, :), tolerance);
    right = douglasPeucker(points(maxIndex:end, :), tolerance);

    % Combine results (remove duplicate middle point)
    simplified = [left(1:end-1, :); right];
else
    % All points between first and last are within tolerance
    simplified = [firstPoint; lastPoint];
end
end
function helpText = getHelpText()
% Comprehensive help text covering all aspects of the GUI
helpText = {
    '                                    SAM INTERACTIVE SEGMENTATION TOOL - USER GUIDE'
    ''
    '═══════════════════════════════════════════════════════════════════════════════════════════'
    '1. GETTING STARTED'
    '═══════════════════════════════════════════════════════════════════════════════════════════'
    ''
    '• Load Image: Click "Load Image" or use File → Load Image (Ctrl+O)'
    '• The SAM model will automatically initialize when you load your first image'
    '• Click anywhere on the image to segment objects at that location'
    '• Each click creates a new segmented object with a unique color and number'
    ''
    '═══════════════════════════════════════════════════════════════════════════════════════════'
    '2. SELECTION METHODS - Choose Your Segmentation Strategy'
    '═══════════════════════════════════════════════════════════════════════════════════════════'
    ''
    '🔵 CLICK-POINT BASED (Recommended)'
    '   • Best for: General purpose segmentation, interactive use'
    '   • How it works: Prioritizes masks that contain your click point'
    '   • Scoring: Combines area size (80%) + distance to click (20%)'
    '   • Use when: You want to segment exactly what you clicked on'
    ''
    '🟡 DISTANCE-BASED SELECTION'
    '   • Best for: Segmenting objects near your click, even if click misses'
    '   • How it works: Finds objects closest to your click point'
    '   • Scoring: Combines distance to click (60%) + area size (40%)'
    '   • Use when: Clicking on small or thin objects that are hard to hit precisely'
    ''
    '🟢 LARGEST COMPONENT ONLY'
    '   • Best for: Segmenting the dominant object in the area'
    '   • How it works: Always selects the largest available object'
    '   • Scoring: Combines area size (80%) + shape compactness (20%)'
    '   • Use when: You want the biggest object regardless of click precision'
    ''
    '═══════════════════════════════════════════════════════════════════════════════════════════'
    '3. SHAPE PROCESSING CONTROLS - Fine-tune Your Results'
    '═══════════════════════════════════════════════════════════════════════════════════════════'
    ''
    '📏 SMOOTHING LEVEL (0.0 - 20.0)'
    '   • 0.0 - 0.5: Original (Pixel Perfect) - No smoothing, preserves all detail'
    '   • 0.5 - 2.0: Minimal Smoothing - Light cleanup of jagged edges'
    '   • 2.0 - 5.0: Light Smoothing - Removes minor irregularities'
    '   • 5.0 - 8.0: Moderate Smoothing - Balances detail and smoothness'
    '   • 8.0 - 12.0: Heavy Smoothing - Creates smoother, more regular shapes'
    '   • 12.0 - 16.0: Very Heavy Smoothing - Highly simplified shapes'
    '   • 16.0 - 20.0: Maximum - Converts to rough polygon approximation'
    ''
    '🔄 SHAPE CONTROL (-1.0 - 10.0)'
    '   • -1.0: Force Convex - Creates convex hull (no concave parts)'
    '   • 0.0 - 2.0: Very Convex - Eliminates most concavities'
    '   • 2.0 - 4.0: Mostly Convex - Reduces concave features'
    '   • 4.0 - 6.0: Balanced - Natural balance of convex/concave'
    '   • 6.0 - 8.0: Allow Concave - Preserves concave details'
    '   • 8.0 - 10.0: Very Concave - Minimal processing, keeps all details'
    ''
    '☑️ PROCESSING OPTIONS'
    '   • Simplify Boundaries: Reduces boundary complexity for smoother edges'
    '   • Advanced Smoothing: Uses Gaussian-based smoothing (more natural curves)'
    ''
    '═══════════════════════════════════════════════════════════════════════════════════════════'
    '4. WORKFLOW TIPS & BEST PRACTICES'
    '═══════════════════════════════════════════════════════════════════════════════════════════'
    ''
    '🎯 FOR PRECISE SEGMENTATION:'
    '   • Use Click-Point Based method'
    '   • Set smoothing level 2.0 - 5.0'
    '   • Keep shape control around 5.0 (balanced)'
    '   • Enable boundary simplification'
    ''
    '🎨 FOR ARTISTIC/SMOOTH RESULTS:'
    '   • Use any selection method'
    '   • Increase smoothing level (8.0+)'
    '   • Adjust shape control for desired concaveness'
    '   • Enable advanced smoothing'
    ''
    '⚡ FOR QUICK ROUGH SEGMENTATION:'
    '   • Use Largest Component method'
    '   • Higher smoothing levels (10.0+)'
    '   • Lower shape control (more convex)'
    ''
    '🔍 FOR DETAILED/COMPLEX OBJECTS:'
    '   • Use Click-Point Based method'
    '   • Lower smoothing (0.5 - 3.0)'
    '   • Higher shape control (7.0+, more concave)'
    '   • Disable simplify boundaries'
    ''
    '═══════════════════════════════════════════════════════════════════════════════════════════'
    '5. KEYBOARD SHORTCUTS'
    '═══════════════════════════════════════════════════════════════════════════════════════════'
    ''
    '• Ctrl+O: Load Image           • Ctrl+S: Save Results'
    '• Ctrl+E: Export Masks         • Ctrl+R: Clear All'
    '• Ctrl+H: Show Help            • Ctrl+Q: Exit Application'
    ''
    '═══════════════════════════════════════════════════════════════════════════════════════════'
    '6. TROUBLESHOOTING'
    '═══════════════════════════════════════════════════════════════════════════════════════════'
    ''
    '❌ "Click is on already segmented area"'
    '   → Click on a different, non-highlighted area'
    '   → Use Clear Last or Clear All to remove previous segments'
    ''
    '❌ "No object found at clicked location"'
    '   → Try clicking on a different area with more contrast'
    '   → Switch to Distance-Based method for more flexibility'
    ''
    '❌ "Embeddings not ready"'
    '   → Reload the image (the SAM model needs to reinitialize)'
    ''
    '❌ Results are too jaggy/rough'
    '   → Increase smoothing level'
    '   → Enable boundary simplification'
    '   → Try advanced smoothing option'
    ''
    '❌ Missing important object details'
    '   → Decrease smoothing level'
    '   → Increase shape control (allow more concave)'
    '   → Disable boundary simplification'
    ''
    '═══════════════════════════════════════════════════════════════════════════════════════════'
    '7. OUTPUT & EXPORT OPTIONS'
    '═══════════════════════════════════════════════════════════════════════════════════════════'
    ''
    '💾 Save Results: Saves the image with overlaid segmentation boundaries'
    '📤 Export Masks: Exports individual binary masks for each segmented object'
    '🗃️ Object List: Shows all segmented objects with coordinates and area information'
    ''
    'Each segmented object is automatically assigned:'
    '• Unique color for visual distinction'
    '• Sequential number for identification'
    '• Area calculation in pixels'
    '• Original click coordinates'
    ''
    '═══════════════════════════════════════════════════════════════════════════════════════════'
    };
end
function aboutText = getAboutText()
% Comprehensive about information
aboutText = {
    'A tool for interactive image segmentation using the'
    'Segment Anything Model (SAM). This software provides multiple'
    'segmentation strategies and advanced shape processing capabilities.'
    ''
    '🔧 KEY FEATURES:'
    ''
    '• Three intelligent selection methods for different use cases'
    '• Advanced shape processing with 20-level smoothing control'
    '• Flexible concaveness control (-1 to +10 range)'
    '• Real-time visual feedback with color-coded objects'
    '• Boundary processing and simplification'
    '• Export capabilities for masks and annotated images'
    '• Scalable, responsive user interface'
    '• Overlap prevention and area validation'
    ''
    '🎯 DESIGNED FOR:'
    ''
    '• Computer vision researchers and practitioners'
    '• Image annotation and dataset preparation'
    '• Geological/Medical image analysis and segmentation'
    '• Quality control and inspection applications'
    '• Educational purposes and demonstrations'
    ''
    '⚙️ TECHNICAL SPECIFICATIONS:'
    ''
    '• Built with MATLAB''s App Designer framework'
    '• Integrates with SAM (Segment Anything Model)'
    '• Advanced morphological and Gaussian processing'
    '• Memory-efficient mask storage and processing'
    '• Robust error handling and user feedback'
    ''
'📝 DEVELOPMENT NOTES:'
''
'• Enhanced GUI with modern styling and responsive design'
'• Good help system and user guidance'
'• Optimized for both precision and ease of use'
'• Extensive testing across various image types and sizes'
''
'📢 This project is open-source — feel free to modify and adapt the code to suit your needs!'
'💬 For questions, suggestions, or collaboration, reach out anytime:'
'   • Email: ahmad.mehri@yahoo.com'
'   • LinkedIn: https://www.linkedin.com/in/seyedahmad-mehrishal/'
'   • YouTube: https://www.youtube.com/@rockbench'
    };
end
function sysInfo = getSystemInfo()
% Get system and MATLAB version information
try
    matlabVer = version;
    computerType = computer;
    javaVer = version('-java');

    sysInfo = sprintf(['MATLAB: %s | Platform: %s | Java: %s | ' ...
        'Built: %s'], ...
        matlabVer, computerType, javaVer, datestr(now, 'yyyy-mm-dd'));
catch
    sysInfo = sprintf('System Information: MATLAB %s | Built: %s', ...
        version, datestr(now, 'yyyy-mm-dd'));
end
end