function [Linearity, Planerity, BoundaryPoints, normal_pnts, alfa, alfa1, point_num, B_loc, IndxEdgePoint, mD] = features_For_Classification_new(input_pnts)

number_of_neighbor = 9; 
bp = 1; 
bl = 1; 
n = size(input_pnts, 1);    
k = number_of_neighbor;

neighbor_idx = knnsearch(input_pnts, input_pnts, 'k', number_of_neighbor + 1);  
neighbor_idx = neighbor_idx(:, 2:number_of_neighbor + 1); 
%----------------------------------
neighbor_idx = cat(2, neighbor_idx, zeros(size(neighbor_idx, 1), 30));
planerity_error = zeros(size(neighbor_idx, 1), 1);

for i = 1:size(neighbor_idx, 1)
    [Nx, Ny, Nz, Standard_D, deviations] = fit_3D_line(input_pnts(neighbor_idx(i, 1:number_of_neighbor), :));
    if Standard_D <= 0.5
        s1 = 5;
        while Standard_D <= 0.5
            neighbor_idx_one = knnsearch(input_pnts, input_pnts(i, :), 'k', number_of_neighbor + s1 + 1);
            neighbor_idx_one = neighbor_idx_one(:, 2:number_of_neighbor + s1 + 1); 
            neighbor_idx_one_1 = neighbor_idx_one;
            [Nx, Ny, Nz, Standard_D, deviations] = fit_3D_line(input_pnts(neighbor_idx_one(1, :), :)); 
            u = find(abs(deviations) > 0.3);
            if length(u) > 6 && size(neighbor_idx_one_1, 2) > 50
                v = find(abs(deviations) <= 0.3);
                neighbor_idx_one_1 = neighbor_idx_one;
                neighbor_idx_one_1(1, v') = 0;
                [Nx, Ny, Nz, Standard_D, deviations] = fit_3D_line(input_pnts(neighbor_idx_one_1(1, u), :));
            end
            s1 = s1 + 5;
        end
        neighbor_idx(i, 1:size(neighbor_idx_one, 2)) = neighbor_idx_one_1(1, :);
    end
    Standard_D_list(i, 1) = Standard_D;
end

% Boundary point calculation start
for i = 1:size(neighbor_idx, 1)
    k = nonzeros(neighbor_idx(i, :));
    meanPnt = mean(input_pnts(k, :), 1);
    p1 = input_pnts(i, :);
    d_3D(i) = norm(input_pnts(i, :) - meanPnt);
    d_2D(i) = norm(p1(1:2) - meanPnt(1:2));
    
    %% Alpha shape
    maxD = MaxDistanceCalc(input_pnts(k, :));
    mD(i) = maxD;
end

% % Uncomment to visualize boundary points
% figure; hold on;
% plot3(input_pnts(:, 1), input_pnts(:, 2), input_pnts(:, 3), '.g');
for i = 1:size(d_3D, 2)
    if d_2D(i) >= 0.25
        BoundaryPoints(bp, :) = input_pnts(i, :); 
        B_loc(bl) = i; 
        % plot3(input_pnts(i, 1), input_pnts(i, 2), input_pnts(i, 3), '.r', 'markersize', 10);
        bp = bp + 1; 
        bl = bl + 1; 
    end
end
% hold off;

% % Uncomment to visualize neighbor normal points
% figure;
normal_pnts = zeros(3, n);    
line = zeros(n, 1);

for i = 1:n
    j = find(neighbor_idx(i, :) ~= 0);
    number_of_neighbor = length(j);
    neighbor_num(i) = length(j);
    neighbor_pnts = input_pnts(neighbor_idx(i, j'), :);  
    mean_neighbor = mean(neighbor_pnts, 1);   
    v = repmat(mean_neighbor', 1, number_of_neighbor) - neighbor_pnts';
    C = v * v';       
    [V, D] = eig(C);    
    [s, j] = min(diag(D));
    %-------------------------
    % Normal points calculation
    normal_pnts(:, i) = V(:, j);
    %----------------------------
    ev = eig(C);
    Lembd = sort(ev, 'descend');
    Linearity(i) = (Lembd(1) - Lembd(2)) / Lembd(1);
    Planerity(i) = (Lembd(2) - Lembd(3)) / Lembd(1);
    BreaklinePoint(i) = (Lembd(3) / (Lembd(1) + Lembd(2) + Lembd(3)));   % Nurunnabi method - 2015
end

[alfa1, point_num, point_num_N, IndxEdgePoint] = test_neighbours(normal_pnts, input_pnts);
i = find(Planerity < 0.5);
for i = 1:size(normal_pnts, 2)
    alfa(1, i) = atan2(norm(cross(normal_pnts(:, i), [0, 0, 1])), dot(normal_pnts(:, i), [0, 0, 1]));
end
alfa = alfa * 180 / pi;

end
