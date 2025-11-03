 X= pts1(:,1);
 Y = pts1(:,2);
 [K, V,a] = My_boundary(X, Y, alphaV);
Bp = pts1(K,:);
figure; hold on;

plot3(pts1(:,1), pts1(:,2), pts1(:,3), '.g');
plot3(Bp(:,1), Bp(:,2), Bp(:,3), '.r', 'markersize', 10);
hold off; 
