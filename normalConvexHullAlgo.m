function [combinedFigure] = normalConvexHullAlgo(filepath, filename)
    % Full path to the file
    fullFilePath = fullfile(filepath, filename);

    % Load the LiDAR data (x, y, z format)
    data = load(fullFilePath);
    x = data(:, 1);
    y = data(:, 2);
    z = data(:, 3);

    % Optional: Subsample data to decrease performance load
    subsampleFactor = 1; % Default is no subsampling
    x = x(1:subsampleFactor:end);
    y = y(1:subsampleFactor:end);
    z = z(1:subsampleFactor:end);
    points3D = [x, y, z]; % Use full 3D coordinates

    % Step 1: Compute the convex hull for boundary detection
    k = convhull(points3D); % Indices of points forming the convex hull

    % Extract boundary points from the convex hull
    boundaryPoints = points3D(unique(k), :); % Unique points forming the convex hull

    % Safeguard against empty boundary points
    if isempty(boundaryPoints)
        warning('Boundary points are empty. Check the input data.');
        boundaryPoints = [NaN, NaN, NaN]; % Placeholder for invalid data
    end

    % Step 2: Noise removal using statistical outlier detection
    % Parameters for statistical filtering
    kNeighbors = 10; % Number of nearest neighbors to consider
    zThreshold = 2.5; % Z-score threshold for identifying outliers

    % Compute distances to k nearest neighbors
    n = size(boundaryPoints, 1);
    distances = zeros(n, 1);

    for i = 1:n
        diff = boundaryPoints - boundaryPoints(i, :); % Compute pairwise differences
        dists = sqrt(sum(diff.^2, 2)); % Compute Euclidean distances
        sortedDists = sort(dists); % Sort distances
        distances(i) = mean(sortedDists(2:kNeighbors+1)); % Mean of k nearest neighbors (ignore self)
    end

    % Compute mean and standard deviation of distances
    meanDist = mean(distances);
    stdDist = std(distances);

    % Identify inliers using a Z-score threshold
    zScores = (distances - meanDist) / stdDist;
    validPoints = boundaryPoints(abs(zScores) <= zThreshold, :); % Keep points within threshold

    % Check if enough points remain after noise removal
    if size(validPoints, 1) < 3
        error('Not enough valid points to form a boundary after noise removal!');
    end

    % Step 3: Construct the initial boundary using nearest neighbors
    n = size(validPoints, 1);

    % Initialize variables
    used = false(n, 1); % To track used points
    initialBoundary = []; % To store the ordered boundary points

    % Start with the first point
    initialBoundary(1, :) = validPoints(1, :);
    used(1) = true;

    for i = 1:n-1
        lastPoint = initialBoundary(end, :);
        minDist = inf;
        nextIndex = -1;

        for j = 1:n
            if ~used(j)
                dist = norm(lastPoint - validPoints(j, :)); % Euclidean distance
                if dist < minDist
                    minDist = dist;
                    nextIndex = j;
                end
            end
        end

        % Add the next point to the boundary
        if nextIndex == -1, break; end
        initialBoundary(end+1, :) = validPoints(nextIndex, :);
        used(nextIndex) = true;
    end

    % Close the boundary
    initialBoundary(end+1, :) = initialBoundary(1, :);

    % Step 4: Enhanced regularization with corner refinement
    numIterations = 5; % Number of smoothing iterations
    angleThreshold = 135; % Minimum angle (degrees) to preserve corners
    curvatureThreshold = 0.1; % Threshold for creating new corners based on curvature
    regularizedBoundary = initialBoundary;

    for k = 1:numIterations
        regularizedBoundary = smoothAndRefineCorners(regularizedBoundary, angleThreshold, curvatureThreshold);
    end

    % Create the combined figure with three subplots
    combinedFigure = figure('Name', 'LiDARShape :: Convex Hull Algorithm'); % Set figure name

    % Set the figure size
    set(combinedFigure, 'Position', [100, 100, 1400, 500]); % Width of 1400px and height of 500px

    % Plot 1: Point cloud with boundary points in 3D
    subplot(1, 3, 1); % Position in 1st subplot
    scatter3(x, y, z, 'g.'); % Point cloud in 3D
    hold on;
    scatter3(boundaryPoints(:, 1), boundaryPoints(:, 2), boundaryPoints(:, 3), 'r.'); % Boundary points in red
    title('Point Cloud with Boundary Points in 3D');
    xlabel('X');
    ylabel('Y');
    zlabel('Z');
    axis equal;
    grid on;
    view(2);
    hold off;

    % Plot 2: Initial boundary plot
    subplot(1, 3, 2); % Position in 2nd subplot
    plot3(initialBoundary(:, 1), initialBoundary(:, 2), initialBoundary(:, 3), 'b-', 'LineWidth', 1.5);
    title('Initial Boundary');
    xlabel('X'); ylabel('Y'); zlabel('Z');
    axis equal; % Correct the aspect ratio
    grid on;
    view(2); % Set the initial view to X-Y plane

    % Plot 3: Enhanced boundary plot
    subplot(1, 3, 3); % Position in 3rd subplot
    plot3(regularizedBoundary(:, 1), regularizedBoundary(:, 2), regularizedBoundary(:, 3), 'g-', 'LineWidth', 1.5);
    title('Enhanced Regularized Boundary with Corner Refinement');
    xlabel('X'); ylabel('Y'); zlabel('Z');
    axis equal; % Correct the aspect ratio
    grid on;
    view(2); % Set the initial view to X-Y plane

    % Add the heading 'Normal Convex Hull' at the top-left inside the figure
    annotation('textbox', [0.05, 0.95, 0.5, 0.05], 'String', sprintf('Convex Hull Algorithm Result for %s', filename), ...
        'EdgeColor', 'none', 'FontSize', 12, 'FontWeight', 'bold', 'Color', 'k', ...
        'HorizontalAlignment', 'left', 'VerticalAlignment', 'top');
end

function regularizedBoundary = smoothAndRefineCorners(boundary, angleThreshold, curvatureThreshold)
    % Function to regularize the boundary while preserving and creating corners
    
    % Calculate angles between consecutive vectors
    n = size(boundary, 1) - 1; % Number of segments
    refinedBoundary = boundary; % Initialize as original boundary
    isCorner = false(n, 1); % Track corner points

    % Identify corners based on angle
    for i = 2:n-1
        % Vectors for the current segment
        v1 = refinedBoundary(i, :) - refinedBoundary(i-1, :); % Vector to previous point
        v2 = refinedBoundary(i+1, :) - refinedBoundary(i, :); % Vector to next point
        
        % Compute angle between vectors
        cosTheta = dot(v1, v2) / (norm(v1) * norm(v2));
        angle = acosd(cosTheta); % Convert to degrees

        % Mark as corner if angle is greater than threshold
        if angle > angleThreshold
            isCorner(i) = true;
        end
    end

    % Identify new corners based on curvature
    for i = 2:n-1
        if ~isCorner(i)
            % Compute curvature using the distance from the point to the line segment
            p = refinedBoundary(i, :); % Current point
            p1 = refinedBoundary(i-1, :); % Previous point
            p2 = refinedBoundary(i+1, :); % Next point
            curvature = pointToLineDistance(p, p1, p2);

            if curvature > curvatureThreshold
                isCorner(i) = true; % Mark as a corner
            end
        end
    end

    % Smooth points between corners
    for i = 2:n-1
        if ~isCorner(i) % Smooth non-corner points
            refinedBoundary(i, :) = 0.5 * (refinedBoundary(i-1, :) + refinedBoundary(i+1, :)); % Midpoint
        end
    end

    % Return the refined boundary
    regularizedBoundary = refinedBoundary;

    
end

function d = pointToLineDistance(p, p1, p2)
    % Compute the distance of point p to the line segment defined by p1 and p2
    lineVec = p2 - p1;
    pointVec = p - p1;
    t = dot(pointVec, lineVec) / dot(lineVec, lineVec); % Project onto the line

    % Clamp t to [0, 1] to stay on the segment
    t = max(0, min(1, t));

    % Compute the closest point on the line segment
    closestPoint = p1 + t * lineVec;

    % Compute the distance from the point to the line segment
    d = norm(p - closestPoint);
end
