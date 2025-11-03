function [Linearity, Planerity, BoundaryPoints, alfa, uu, pts1, B_loc, IndxEdgePoint, alphaV] = edge_plane_detection_new(colon_num,filename1, pathname1)

[pts1] = input_handler(3,pathname1,filename1);

%if colon_num == 3
 %  [pts1] = input_handler(3,pathname1,filename1);
%else
 %  [pts1] = ouvrir_rapid(4);
  % pts1 = pts1(:, 1:3);
%end

[Linearity, Planerity, BoundaryPoints, normal_pnts, alfa, alfa1, point_num, B_loc, IndxEdgePoint, mD] = ...
    features_For_Classification_new(pts1);

% Alpha value calculation
alphaV = mean(mD);

% % Uncomment to visualize histogram of alfa
% figure;
% histogram(alfa, 'BinWidth', 3);
[N, edges] = histcounts(alfa, 'BinWidth', 3);

j = find(N >= max(N) * 0.7);

for u = 1:length(j)
    uu = find(alfa >= edges(j(u)) - 3);
end
uu = find(alfa < edges(j(u)) - 3); % For VA -12, for other cases it is -3

% % Uncomment to visualize 3D scatter plot
% figure; hold on;
% plot3(pts1(:, 1), pts1(:, 2), pts1(:, 3), 'y.');
% plot3(pts1(uu, 1), pts1(uu, 2), pts1(uu, 3), '.g', 'markersize', 7);
% plot3(BoundaryPoints(:, 1), BoundaryPoints(:, 2), BoundaryPoints(:, 3), '.r');
% hold off;

% % Uncomment to visualize histogram of alfa1
% figure;
% histogram(alfa1, 'BinWidth', 3);
[N1, edges1] = histcounts(alfa1, 'BinWidth', 3);

jj = find(N1 >= max(N1) * 0.7);
for u = 1:length(jj)
    uu1 = find(alfa1 >= edges1(jj(u)) - 3);
end
uu1 = find(alfa1 < edges1(jj(u)) - 12);

% % Uncomment to visualize 3D scatter plot
% figure; hold on;
% plot3(pts1(:, 1), pts1(:, 2), pts1(:, 3), '.b');
% plot3(pts1(uu1, 1), pts1(uu1, 2), pts1(uu1, 3), '.y', 'markersize', 7);
% plot3(BoundaryPoints(:, 1), BoundaryPoints(:, 2), BoundaryPoints(:, 3), '.r', 'markersize', 11);
% hold off;

end
