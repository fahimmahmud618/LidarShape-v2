function [alfa1, point_num, point_num_N, IndxEdgePoint] = test_neighbours(normal_vec, pts)

neighbor_idx = knnsearch(pts(:, 1:2), pts(:, 1:2), 'k', 9 + 1);
neighbor_idx = neighbor_idx(:, 2:9 + 1); 

for i = 1:size(neighbor_idx, 1)
    for j = 1:size(neighbor_idx(i, :), 2)
        alfa(i, j) = atan2(norm(cross(normal_vec(:, i), normal_vec(:, neighbor_idx(i, j)))), ...
            dot(normal_vec(:, i), normal_vec(:, neighbor_idx(i, j)))) * 180 / pi;
    end
    alfa1(i, 1) = max(alfa(i, :));
end

i = find(alfa1 > 90);
alfa1(i) = 180 - alfa1(i);
i = find(alfa1 < 2);
point_num(1) = size(i, 1);

% % Uncomment to visualize points with alfa1 < 2
% figure; hold on;
% plot3(pts(i, 1), pts(i, 2), pts(i, 3), '.b');

i = find(alfa1 >= 2 & alfa1 < 10);
point_num(2) = size(i, 1);
% plot3(pts(i, 1), pts(i, 2), pts(i, 3), '.r');

i = find(alfa1 >= 10 & alfa1 < 20);
point_num(3) = size(i, 1);
% plot3(pts(i, 1), pts(i, 2), pts(i, 3), '.g');

i = find(alfa1 >= 20 & alfa1 < 30);
point_num(4) = size(i, 1);
% plot3(pts(i, 1), pts(i, 2), pts(i, 3), '.y');

i = find(alfa1 >= 30);
point_num(5) = size(i, 1);
% plot3(pts(i, 1), pts(i, 2), pts(i, 3), '.c');
% hold off;

% % Uncomment to visualize the points with alfa1 >= 0 & alfa1 < 11
% figure; hold on;
i = find(alfa1 >= 0 & alfa1 < 11);
point_num_N(1) = size(i, 1);
% plot3(pts(i, 1), pts(i, 2), pts(i, 3), '.g');

i = find(alfa1 >= 12);
IndxEdgePoint = i; 
% plot3(pts(i, 1), pts(i, 2), pts(i, 3), '.r');
point_num_N(2) = size(i, 1);
% hold off;

point_num = point_num';
end
