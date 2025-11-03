% Call the edge_plane_detection_new function
[Linearity, Planerity, BoundaryPoints, alfa, uu, pts1, B_loc, IndxEdgePoint, alphaV] = edge_plane_detection_new(3);

% Debug: Check the value of alphaV
disp(['alphaV: ', num2str(alphaV)]);

% Ensure alphaV is within a valid range (0 to 1)
%alphaV = max(0, min(1, alphaV));

% Extract X and Y coordinates from pts1
X = pts1(:, 1);
Y = pts1(:, 2);

% Call My_boundary with X, Y, and validated alphaV
[K, V, a] = My_boundary(X, Y, alphaV);

% Get the boundary points from pts1
Bp = pts1(K, :);

% Plot the results
figure;
hold on;

% Plot all points in green
plot3(pts1(:, 1), pts1(:, 2), pts1(:, 3), '.g');

% Plot boundary points in red
plot3(Bp(:, 1), Bp(:, 2), Bp(:, 3), '.r', 'markersize', 10);

hold off;
