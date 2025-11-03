function [initialBoundaryFigure, enhancedBoundaryFigure] = extractBuildingBoundary(filename)
    %==========================================================================
    % extractBuildingBoundary
    % ------------------------
    % 2D boundary extraction and plotting for LiDAR point data.
    % Straightens edges in the enhanced boundary using RDP simplification.
    %
    % Input:
    %   filename - path to .txt or .dat file containing [X Y Z] points
    %
    % Output:
    %   initialBoundaryFigure  - handle to figure of initial boundary
    %   enhancedBoundaryFigure - handle to figure of enhanced (straighter) boundary
    %==========================================================================

    %-----------------------------
    % Step 1: Load point data
    %-----------------------------
    points = load(filename);
    points = points(:, 1:2);      % Only use X and Y coordinates

    % Remove duplicates if any
    points = unique(points, 'rows', 'stable');

    if size(points, 1) < 3
        error('Not enough points to form a boundary!');
    end

    %-----------------------------
    % Step 2: Plot initial boundary
    %-----------------------------
    initialBoundaryFigure = figure('Name', 'Initial Boundary', 'Visible', 'off');
    hold on;
    plot(points(:,1), points(:,2), 'b-', 'LineWidth', 1.5);               
    scatter(points(:,1), points(:,2), 20, 'r', 'filled');                
    plot([points(end,1), points(1,1)], [points(end,2), points(1,2)], ...
        'b-', 'LineWidth', 1.5);
    title('Initial Boundary (Sequential Connection)');
    xlabel('X'); ylabel('Y');
    axis equal; grid on; box on;
    hold off;

    %-----------------------------
    % Step 3: Enhance the boundary (straighten edges)
    %-----------------------------
    epsilon = 0.5; % Adjust this for straighter or smoother edges
    smoothedPoints = smoothBoundary(points, epsilon); 

    %-----------------------------
    % Step 4: Plot enhanced boundary
    %-----------------------------
    enhancedBoundaryFigure = figure('Name', 'Enhanced Boundary', 'Visible', 'off');
    hold on;
    plot(smoothedPoints(:,1), smoothedPoints(:,2), 'g-', 'LineWidth', 1.5);
    scatter(smoothedPoints(:,1), smoothedPoints(:,2), 15, 'm', 'filled');
    title('Enhanced Boundary (Straighter Edges)');
    xlabel('X'); ylabel('Y');
    axis equal; grid on; box on;
    hold off;

    %-----------------------------
    % Step 5: Compute area (optional)
    %-----------------------------
    boundaryArea = polyarea(smoothedPoints(:,1), smoothedPoints(:,2));
    msgbox(sprintf('Enhanced Boundary Area: %.2f square units', boundaryArea), ...
        'Boundary Area');
end

%% ========================================================================
%  Helper function: smoothBoundary (RDP simplification)
% ========================================================================
function smoothedPts = smoothBoundary(points, epsilon)
    % Simplifies boundary to produce straighter edges
    smoothedPts = rdp(points, epsilon);

    % Close the loop
    if ~isequal(smoothedPts(1,:), smoothedPts(end,:))
        smoothedPts(end+1,:) = smoothedPts(1,:);
    end
end

%% Ramer-Douglas-Peucker implementation
function outPts = rdp(points, epsilon)
    dmax = 0;
    index = 0;
    n = size(points,1);

    % Find point with max distance to line connecting endpoints
    for i = 2:n-1
        d = pointLineDistance(points(i,:), points(1,:), points(end,:));
        if d > dmax
            index = i;
            dmax = d;
        end
    end

    if dmax > epsilon
        recResults1 = rdp(points(1:index,:), epsilon);
        recResults2 = rdp(points(index:end,:), epsilon);
        outPts = [recResults1(1:end-1,:); recResults2];
    else
        outPts = [points(1,:); points(end,:)];
    end
end

%% Helper function: distance from point to line
function d = pointLineDistance(point, lineStart, lineEnd)
    if isequal(lineStart, lineEnd)
        d = norm(point - lineStart);
    else
        t = max(0, min(1, dot(point-lineStart, lineEnd-lineStart)/norm(lineEnd-lineStart)^2));
        projection = lineStart + t*(lineEnd-lineStart);
        d = norm(point - projection);
    end
end
