function [Nx, Ny, Nz,Standard_D,deviations]=fit_3D_line(pts_list)

X_ave=mean(pts_list,1);            % mean; line of best fit will pass through this point  
dX=bsxfun(@minus,pts_list,X_ave);  % residuals
N=size(pts_list,1);
C=(dX'*dX)/(N-1);           % variance-covariance matrix of X
[R,D]=svd(C,0);             % singular value decomposition of C; C=R*D*R'
Nx=R(1,1); Ny=R(2,1); Nz=R(3,1);
% NOTES:
% 1) Direction of best fit line corresponds to R(:,1)
% 2) R(:,1) is the direction of maximum variances of dX 
% 3) D(1,1) is the variance of dX after projection on R(:,1)
% 4) Parametric equation of best fit line: L(t)=X_ave+t*R(:,1)', where t is a real number
% 5) Total variance of X = trace(D)
% Coefficient of determineation; R^2 = (explained variance)/(total variance)
D=diag(D);
R2=D(1)/sum(D);
% Visualize X and line of best fit
% -------------------------------------------------------------------------
% End-points of a best-fit line (segment); used for visualization only 
deviations=dX*R(:,1);    % project residuals on R(:,1) 
Standard_D=std(deviations);
end
