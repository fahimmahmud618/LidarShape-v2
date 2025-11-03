function [initialBoundaryFigure, enhancedBoundaryFigure] = drawBuildingRoof(filename)
    % Step 1: Read the points from the file
    points = load(filename); % Assumes points are in 'bp.txt' with x, y, z columns

    % Step 2: Noise removal using statistical outlier detection
    % Parameters for statistical filtering
    k = 10; % Number of nearest neighbors to consider
    zThreshold = 2.5; % Z-score threshold for identifying outliers

    % Compute distances to k nearest neighbors
    n = size(points, 1);
    distances = zeros(n, 1);

    for i = 1:n
        diff = points - points(i, :); % Compute pairwise differences
        dists = sqrt(sum(diff.^2, 2)); % Compute Euclidean distances
        sortedDists = sort(dists); % Sort distances
        distances(i) = mean(sortedDists(2:k+1)); % Mean of k nearest neighbors (ignore self)
    end

    % Compute mean and standard deviation of distances
    meanDist = mean(distances);
    stdDist = std(distances);

    % Identify inliers using a Z-score threshold
    zScores = (distances - meanDist) / stdDist;
    validPoints = points(abs(zScores) <= zThreshold, :); % Keep points within threshold

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

    % Step 5: Create figures to return

    % Create the initial boundary plot
    initialBoundaryFigure = figure('Visible', 'off'); % Create figure but don't display
    plot3(initialBoundary(:, 1), initialBoundary(:, 2), initialBoundary(:, 3), 'b-', 'LineWidth', 1.5);
    title('Initial Boundary');
    xlabel('X'); ylabel('Y'); zlabel('Z');
    grid on;
    view(2); % Set the initial view to X-Y plane

    % Create the enhanced boundary plot
    enhancedBoundaryFigure = figure('Visible', 'off'); % Create figure but don't display
    plot3(regularizedBoundary(:, 1), regularizedBoundary(:, 2), regularizedBoundary(:, 3), 'g-', 'LineWidth', 1.5);
    title('Enhanced Regularized Boundary with Corner Refinement');
    xlabel('X'); ylabel('Y'); zlabel('Z');
    grid on;
    view(2); % Set the initial view to X-Y plane
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
