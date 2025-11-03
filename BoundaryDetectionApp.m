classdef BoundaryDetectionApp < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure          matlab.ui.Figure
        SelectFileButton  matlab.ui.control.Button
        ShowBoundaryButton  matlab.ui.control.Button
        DownloadResultButton matlab.ui.control.Button % New button
        EalphaButton  matlab.ui.control.Button
        ConvexHullButton  matlab.ui.control.Button
        DBSCANButton  matlab.ui.control.Button
        UIAxes1           matlab.ui.control.UIAxes
        UIAxes2           matlab.ui.control.UIAxes
        UIAxes3           matlab.ui.control.UIAxes
        LoadingBar        matlab.ui.control.Label
        DescriptionText   matlab.ui.control.Label
        TitleText         matlab.ui.control.Label
        HorizontalLine    matlab.ui.control.UIAxes  % For horizontal line
        HorizontalLine2   matlab.ui.control.UIAxes
        HorizontalLine3   matlab.ui.control.UIAxes
        AlphaValueLabel   matlab.ui.control.Label
    end

    properties (Access = private)
        pathname1 % Path of the selected file
        filename1 % Name of the selected file
        IsProcessing = false; % Flag to prevent multiple triggers
        alphaV = 0; % Variable to store the calculated alphaV
        initialBoundaryFigure % Store initial boundary figure
        enhancedBoundaryFigure % Store enhanced boundary figure
    end

    methods (Access = private)

        % Callback function for the button
        
        function selectFile(app, ~)
    % Check if processing is already ongoing
    if app.IsProcessing
        disp("Callback blocked: already processing.");
        return;
    end

    % Set the processing flag
    app.IsProcessing = true;
    disp("Callback started.");

    % Disable the buttons to prevent multiple triggers
    app.SelectFileButton.Enable = 'off';
    app.EalphaButton.Enable = 'off';
    app.ConvexHullButton.Enable = 'off';
    app.DBSCANButton.Enable = 'off';
    app.ShowBoundaryButton.Enable = 'off';
    app.DownloadResultButton.Enable = 'off';

    % Hide UIAxes2 and UIAxes3 and clear their data
    app.UIAxes2.Visible = 'off';
    app.UIAxes3.Visible = 'off';
    cla(app.UIAxes2);
    cla(app.UIAxes3);

    % Show loading bar
    app.LoadingBar.Visible = 'on';
    app.LoadingBar.Text = 'Loading...';

    try
        % Open file selection dialog
        [filename1, pathname1] = uigetfile({'*.txt','*.txt'; '*.xyz','*.xyz'; '*.asc','*.asc'; '*.*','*.*'}, 'Select a file');
        if isequal(filename1, 0)
            disp('File selection canceled.');
            app.LoadingBar.Visible = 'off';
            app.IsProcessing = false;
            return;
        end

        % Store in app properties
        app.filename1 = filename1;
        app.pathname1 = pathname1;

        % Full path to the selected file
        fullFilePath = fullfile(pathname1, filename1);

        % Call edge_plane_detection_new function (your existing function)
        [Linearity, Planerity, BoundaryPoints, alfa, uu, pts1, B_loc, IndxEdgePoint, alphaV] = edge_plane_detection_new(3, filename1, pathname1);

        % Store the calculated alphaV
        app.alphaV = alphaV;

        % Update the UI to show the calculated alphaV
        app.AlphaValueLabel.Text = ['Calculated Adaptive Alpha Value: ', num2str(alphaV)];
        app.AlphaValueLabel.Visible = 'on';

        % Remove duplicate points
        [pts1Unique, ~, ~] = unique(pts1, 'rows', 'stable');
        numDuplicates = size(pts1,1) - size(pts1Unique,1);
        if numDuplicates > 0
            app.LoadingBar.Text = ['Removed ', num2str(numDuplicates), ' duplicate points.'];
            pause(1); % Briefly show message
        end

        % Extract X, Y, Z coordinates
        X = pts1Unique(:,1);
        Y = pts1Unique(:,2);
        Z = pts1Unique(:,3);

        % Call My_boundary with unique points and alphaV
        [K, V, a] = My_boundary(X, Y, alphaV);

        % Get boundary points
        Bp = pts1Unique(K, :);

        % Save boundary points to a file (bp.txt)
        bpFilePath = fullfile(pwd, 'bp.txt');
        fid = fopen(bpFilePath, 'w');
        fprintf(fid, '%.6f\t%.6f\t%.6f\n', Bp');
        fclose(fid);

        % Show the axes and their grid
        app.UIAxes1.Visible = 'on';
        app.EalphaButton.Visible = 'on';
        app.ConvexHullButton.Visible = 'on';
        app.DBSCANButton.Visible = 'on';
        app.ShowBoundaryButton.Visible = 'on';
        app.DownloadResultButton.Visible = 'on';

        % Plot the first plot (all points and boundary points)
        cla(app.UIAxes1);
        hold(app.UIAxes1, 'on');
        plot3(app.UIAxes1, X, Y, Z, '.g'); % All points in green
        plot3(app.UIAxes1, Bp(:,1), Bp(:,2), Bp(:,3), '.r', 'markersize', 10); % Boundary points in red
        title(app.UIAxes1, 'Point Cloud with Boundary');
        xlabel(app.UIAxes1, 'X'); ylabel(app.UIAxes1, 'Y'); zlabel(app.UIAxes1, 'Z');
        grid(app.UIAxes1, 'on');
        hold(app.UIAxes1, 'off');

        % Call extractBuildingBoundary with bp.txt and get the figures
        [app.initialBoundaryFigure, app.enhancedBoundaryFigure] = extractBuildingBoundary(bpFilePath);

    catch ME
        disp(['Error: ', ME.message]);
        uialert(app.UIFigure, 'An error occurred during processing.', 'Error');
    end

    % Hide loading bar and re-enable buttons
    app.ShowBoundaryButton.Visible  = 'on';
    app.DownloadResultButton.Visible = 'on';
    app.LoadingBar.Visible = 'off';
    app.SelectFileButton.Text = 'Reselect a file';
    app.SelectFileButton.Enable = 'on';
    app.EalphaButton.Enable = 'on';
    app.ConvexHullButton.Enable = 'on';
    app.DBSCANButton.Enable = 'on';
    app.ShowBoundaryButton.Enable = 'on';
    app.DownloadResultButton.Enable = 'on';
    app.IsProcessing = false;
    disp("Callback completed.");
end

        % Callback function for the "Show Boundary" button
function showboundary(app)
    % Make UIAxes2 and UIAxes3 visible
    app.UIAxes2.Visible = 'on';
    app.UIAxes3.Visible = 'on';
    app.ShowBoundaryButton.Enable = 'off';

    % ----------------------------
    % Plot the initial boundary (UIAxes2)
    % ----------------------------
    cla(app.UIAxes2);
    figureData = findobj(app.initialBoundaryFigure, 'Type', 'line');

    if ~isempty(figureData)
        for k = 1:length(figureData)
            h = figureData(k);
            % Check if ZData exists and is not all zeros
            if isprop(h, 'ZData') && ~isempty(h.ZData) && ~all(h.ZData == 0)
                plot3(app.UIAxes2, h.XData, h.YData, h.ZData, 'b-', 'LineWidth', 1.5);
                zlabel(app.UIAxes2, 'Z');
            else
                plot(app.UIAxes2, h.XData, h.YData, 'b-', 'LineWidth', 1.5);
            end
            hold(app.UIAxes2, 'on');
        end
        hold(app.UIAxes2, 'off');
    end

    title(app.UIAxes2, 'Initial Boundary');
    xlabel(app.UIAxes2, 'X');
    ylabel(app.UIAxes2, 'Y');
    grid(app.UIAxes2, 'on');
    axis(app.UIAxes2, 'equal');
    view(app.UIAxes2, [0 90]); % Top-down 2D view

    % ----------------------------
    % Plot the enhanced boundary (UIAxes3)
    % ----------------------------
    cla(app.UIAxes3);
    figureData = findobj(app.enhancedBoundaryFigure, 'Type', 'line');

    if ~isempty(figureData)
        for k = 1:length(figureData)
            h = figureData(k);
            if isprop(h, 'ZData') && ~isempty(h.ZData) && ~all(h.ZData == 0)
                plot3(app.UIAxes3, h.XData, h.YData, h.ZData, 'g-', 'LineWidth', 1.5);
                zlabel(app.UIAxes3, 'Z');
            else
                plot(app.UIAxes3, h.XData, h.YData, 'g-', 'LineWidth', 1.5);
            end
            hold(app.UIAxes3, 'on');
        end
        hold(app.UIAxes3, 'off');
    end

    title(app.UIAxes3, 'Enhanced Boundary');
    xlabel(app.UIAxes3, 'X');
    ylabel(app.UIAxes3, 'Y');
    grid(app.UIAxes3, 'on');
    axis(app.UIAxes3, 'equal');
    view(app.UIAxes3, [0 90]);

    % ----------------------------
    % Close temporary figures safely
    % ----------------------------
    if ~isempty(app.initialBoundaryFigure) && isvalid(app.initialBoundaryFigure)
        close(app.initialBoundaryFigure);
    end

    if ~isempty(app.enhancedBoundaryFigure) && isvalid(app.enhancedBoundaryFigure)
        close(app.enhancedBoundaryFigure);
    end
end

        % Callback function for the "Download Result" button
        function downloadResult(app, ~)
            % Prompt the user to select a file name and location
            [file, path] = uiputfile('*.png', 'Save UI as PNG');
            if isequal(file, 0)
                disp('Save operation canceled.');
                return;
            end

            % Save the entire UI figure as a PNG image
            exportgraphics(app.UIFigure, fullfile(path, file), 'Resolution', 300);
            disp(['UI saved as PNG: ', fullfile(path, file)]);
        end
    end

    % Component initialization
    methods (Access = private)

        % Create components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off', 'Color', [0.9 0.9 0.9]);
            app.UIFigure.Position = [100 100 1000 600];  % Adjusted height for more space
            app.UIFigure.Name = 'LiDARShape';

            % Title
            app.TitleText = uilabel(app.UIFigure);
            app.TitleText.Position = [200 550 600 30];
            app.TitleText.Text = 'LiDARShape: Smart Building Edge Mapping';
            app.TitleText.FontSize = 20;
            app.TitleText.FontWeight = 'bold';
            app.TitleText.HorizontalAlignment = 'center';
            app.TitleText.FontColor = [0 0.5 0]; % Use FontColor property for uilabel

            % Description
            app.DescriptionText = uilabel(app.UIFigure);
            app.DescriptionText.Position = [150 500 700 30];
            app.DescriptionText.Text = 'Select a LiDAR data file to get results for Proposed Neighbourhood-Based Alpha-Shape Algorithm';
            app.DescriptionText.FontSize = 14;
            app.DescriptionText.HorizontalAlignment = 'center';

            % Create a horizontal line (using UIAxes)
            app.HorizontalLine = uiaxes(app.UIFigure);
            app.HorizontalLine.Position = [50 480 900 2];
            set(app.HorizontalLine, 'XTick', [], 'YTick', []);  % Hide axes
            line([0 1], [0 0], 'Color', 'black', 'LineWidth', 2, 'Parent', app.HorizontalLine);

            % Select File Button (positioned below the line)
            app.SelectFileButton = uibutton(app.UIFigure, 'push');
            app.SelectFileButton.Position = [250 440 100 30];
            app.SelectFileButton.Text = 'Select File';
            app.SelectFileButton.ButtonPushedFcn = @(~, ~) selectFile(app);
            app.SelectFileButton.BackgroundColor = [0.2, 0.6, 0.8]; % Example: Light blue
            app.SelectFileButton.FontColor = [1, 1, 1];             % Example: White text

            % Show Boundary Button
            app.ShowBoundaryButton = uibutton(app.UIFigure, 'push');
            app.ShowBoundaryButton.Position = [450 440 100 30];
            app.ShowBoundaryButton.Text = 'See Boundaries';
            app.ShowBoundaryButton.ButtonPushedFcn = @(~, ~) showboundary(app);
            app.ShowBoundaryButton.BackgroundColor = [0.2, 0.6, 0.8]; % Example: Light blue
            app.ShowBoundaryButton.FontColor = [1, 1, 1]; 
            app.ShowBoundaryButton.Visible = 'off';

            % Download Result Button
            app.DownloadResultButton = uibutton(app.UIFigure, 'push');
            app.DownloadResultButton.Position = [650 440 100 30];
            app.DownloadResultButton.Text = 'Download Result';
            app.DownloadResultButton.ButtonPushedFcn = @(~, ~) downloadResult(app);
            app.DownloadResultButton.BackgroundColor = [0.2, 0.6, 0.8]; % Example: Light blue
            app.DownloadResultButton.FontColor = [1, 1, 1]; 
            app.DownloadResultButton.Visible = 'off';

            % Create a second horizontal line
            app.HorizontalLine2 = uiaxes(app.UIFigure);
            app.HorizontalLine2.Position = [50 50 900 2];
            set(app.HorizontalLine2, 'XTick', [], 'YTick', []);  % Hide axes
            line([0 1], [0 0], 'Color', 'black', 'LineWidth', 2, 'Parent', app.HorizontalLine2);

            % Ealpha Button
            app.EalphaButton = uibutton(app.UIFigure, 'push');
            app.EalphaButton.Position = [50 10 200 30];
            app.EalphaButton.Text = 'See Result for Alpha-Shape';
            app.EalphaButton.ButtonPushedFcn = @(~, ~) normalAlphaShapeAlgo(app.pathname1, app.filename1);
            app.EalphaButton.Visible = 'off';

            % Convex Hull Button
            app.ConvexHullButton = uibutton(app.UIFigure, 'push');
            app.ConvexHullButton.Position = [300 10 200 30];
            app.ConvexHullButton.Text = 'See Result for Multidirectional Band';
            app.ConvexHullButton.ButtonPushedFcn = @(~, ~) normalConvexHullAlgo(app.pathname1, app.filename1);
            app.ConvexHullButton.Visible = 'off';

            % DBSCAN Button
            app.DBSCANButton = uibutton(app.UIFigure, 'push');
            app.DBSCANButton.Position = [550 10 200 30];
            app.DBSCANButton.Text = 'See Result for Dey et al. Method';
            app.DBSCANButton.ButtonPushedFcn = @(~, ~) normalDBSCANAlgo(app.pathname1, app.filename1);
            app.DBSCANButton.Visible = 'off';

            % Create Alpha Value label (hidden initially)
            app.AlphaValueLabel = uilabel(app.UIFigure);
            app.AlphaValueLabel.Position = [350 60 300 30];
            app.AlphaValueLabel.Text = 'Calculated Adaptive Alpha Value: N/A';
            app.AlphaValueLabel.FontSize = 14;
            app.AlphaValueLabel.HorizontalAlignment = 'center';
            app.AlphaValueLabel.Visible = 'off';  % Hide initially

            % Create UIAxes1, UIAxes2, and UIAxes3 (visible but with no labels)
            app.UIAxes1 = uiaxes(app.UIFigure);
            app.UIAxes1.Position = [20 90 300 300];
            app.UIAxes1.Visible = 'off';  % Initially off
            set(app.UIAxes1, 'Color', 'w');  % Set background to white

            app.UIAxes2 = uiaxes(app.UIFigure);
            app.UIAxes2.Position = [340 90 300 300];
            app.UIAxes2.Visible = 'off';  % Initially off
            set(app.UIAxes2, 'XTick', [], 'YTick', [], 'ZTick', []);  % Hide ticks
            set(app.UIAxes2, 'Color', 'w');  % Set background to white

            app.UIAxes3 = uiaxes(app.UIFigure);
            app.UIAxes3.Position = [660 90 300 300];
            app.UIAxes3.Visible = 'off';  % Initially off
            set(app.UIAxes3, 'XTick', [], 'YTick', [], 'ZTick', []);  % Hide ticks
            set(app.UIAxes3, 'Color', 'w');  % Set background to white

            % Create Loading Bar (hidden initially)
            app.LoadingBar = uilabel(app.UIFigure);
            app.LoadingBar.Position = [450 50 100 30];
            app.LoadingBar.Text = 'Loading...';
            app.LoadingBar.Visible = 'off';

            % Show UIFigure
            app.UIFigure.Visible = 'on';
        end
    end

    % App initialization and construction
    methods (Access = public)

        % Construct app
        function app = BoundaryDetectionApp
            createComponents(app);
        end
    end
end