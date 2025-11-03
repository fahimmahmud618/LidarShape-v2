function max_D = MaxDistanceCalc(points)
         % Delaunay triangulation performed, all the connections stored in the edge lines of the matrix
% 	triangles = sort(delaunay(points(1, :), points(2, :)), 2);
triangles = sort(delaunay(points(:,1), points(:,2)), 2);
	lines = zeros(size(triangles, 1) * 3, 2);
	for i = 1:size(triangles, 1)
		lines(3 * i - 2,:) = [triangles(i, 1), triangles(i, 2)];
		lines(3 * i - 1,:) = [triangles(i, 1), triangles(i, 3)];
		lines(3 * i,:) = [triangles(i, 2), triangles(i, 3)];
    end
         % The number of lines that appear more than once to remove the edge
	[~, IA] = unique(lines, 'rows');
    
    UL=lines(IA,:);
    for k=1:size(UL,1)
        d(k)=norm(points(UL(k,1)) - points(UL(k,2)));
    end
    
   max_D = max(d); % maximum distance is choosen for alpha value which guarentee the two scanlines
    
   
	
%     lines = setdiff(lines(IA, :), lines(setdiff(1:size(lines, 1), IA), :), 'rows');
%          % Data point tracking lines of the convex polygon vertex numbers are stored in seqs
% 	seqs = zeros(size(lines, 1) + 1,1);
% 	seqs(1:2) = lines(1, :);
% 	lines(1, :) = [];
% 	for i = 3:size(seqs)
% 		pos = find(lines == seqs(i - 1));
% 		row = rem(pos - 1, size(lines, 1)) + 1;
% 		col = ceil(pos / size(lines, 1));
% 		seqs(i) = lines(row, 3 - col);
% 		lines(row, :) = [];
%     end
%         % The% seqs, convex polygon vertex coordinates obtained
% 	polygon = points(:, seqs);
end