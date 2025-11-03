function [K, V, a] = My_boundary(varargin)
    
    
    narginchk(1, 4); % Ensure input has between 1 and 4 arguments
    [P, S, a] = sanityCheckInput(varargin{:});
    preMergeSize = size(P, 1);
    [~, I, ~] = unique(P, 'first', 'rows');
    postMergeSize = length(I);
    if (preMergeSize > postMergeSize)
        
        sorted_I = sort(I);
        P = P(sorted_I, :);
    end
    shp = alphaShape(P, Inf);
    if numRegions(shp) == 0
        K = [];
        if nargout >= 2
            V = 0;
        end
        return;
    end
    P = shp.Points;
    if size(P, 2) == 2
        areavol = area(shp);
    else
        areavol = volume(shp);
    end

    if isempty(a)
        % Dynamically calculate the alpha value
        Acritical = criticalAlpha(shp, 'one-region');
        Aspectrum = alphaSpectrum(shp);
        Ahispec = Aspectrum(Aspectrum >= Acritical);

        if (Ahispec(1) - Acritical < 1e-3 * Ahispec(1))
            a = Inf; % Use infinite alpha for degenerate spectrum
        else
            numA = numel(Ahispec);
            a = Ahispec(numA + 1 - max(ceil((1 - S) * numA), 1));
        end
    end

    % Assign the calculated or provided alpha value
    shp.Alpha = a;
    shp.HoleThreshold = areavol;

    % Extract boundary facets
    bf = boundaryFacets(shp);
    if size(P, 2) == 2
        bf = bf';
        bf = bf(:);
        idx = (1:2:numel(bf))';
        bf = bf(idx);
        bf(end + 1) = bf(1);
    end
    K = bf;

    if (preMergeSize > postMergeSize)
        K = sorted_I(K);
    end

    if nargout >= 2
        if size(P, 2) == 2
            V = area(shp);
        else
            V = volume(shp);
        end
    end
end

function [P, S, a] = sanityCheckInput(varargin)
    % Helper function to validate and process input arguments
    S = 0.5; % Default shrink factor
    a = [];  % Default alpha value (dynamically calculated)

    if nargin == 1
        P = varargin{1};
        sanityCheckPoints(P);
    elseif nargin == 2
        [arg1, arg2] = deal(varargin{:});
        if isequal(size(arg1), size(arg2)) && isnumeric(arg1) && isnumeric(arg2)
            P = checkAndConcatVectors(arg1, arg2);
        elseif (~isscalar(arg1) && isscalar(arg2))
            P = arg1;
            sanityCheckPoints(P);
            S = arg2;
        else
            error(message('MATLAB:boundary:InvalidInput'));
        end
    elseif nargin == 3
        [arg1, arg2, arg3] = deal(varargin{:});
        if isequal(size(arg1), size(arg2)) && isequal(size(arg2), size(arg3)) && isnumeric(arg1) && isnumeric(arg2) && isnumeric(arg3)
            P = checkAndConcatVectors(arg1, arg2, arg3);
        elseif isequal(size(arg1), size(arg2)) && isnumeric(arg1) && isnumeric(arg2) && isscalar(arg3)
            P = checkAndConcatVectors(arg1, arg2);
            S = arg3;
        else
            error(message('MATLAB:boundary:InvalidInput'));
        end
    elseif nargin == 4
        S = varargin{end};
        a = varargin{end - 1};
        [arg1, arg2, arg3] = deal(varargin{1:(end - 2)});
        if isequal(size(arg1), size(arg2)) && isequal(size(arg2), size(arg3)) && isnumeric(arg1) && isnumeric(arg2) && isnumeric(arg3)
            P = checkAndConcatVectors(arg1, arg2, arg3);
        else
            error(message('MATLAB:boundary:InvalidInput'));
        end
    end
    sanityCheckShrink(S);
end

function P = checkAndConcatVectors(varargin)
    % Concatenates vectors into a single matrix
    P = [];
    for i = 1:nargin
        a = varargin{i};
        if isempty(a)
            error(message('MATLAB:boundary:EmptyInpPtsErrId'));
        elseif ~iscolumn(a)
            error(message('MATLAB:boundary:NonColVecInpPtsErrId'));
        end
        P = [P a];
    end
end

function sanityCheckPoints(P)
    % Validates the input points
    if isempty(P)
        error(message('MATLAB:boundary:EmptyInpPtsErrId'));
    end
    if ~ismatrix(P)
        error(message('MATLAB:boundary:InvalidPointsMatrix'));
    end
    if size(P, 2) < 2 || size(P, 2) > 3
        error(message('MATLAB:boundary:Non2D3DInputErrId'));
    end
end

function sanityCheckShrink(S)
    if ~isscalar(S) || ~isnumeric(S) || ~isfinite(S) || ~isreal(S) || issparse(S) || S < 0
        error('Shrink factor must be a finite, real, non-sparse, numeric scalar greater than or equal to 0.');
    end
end



