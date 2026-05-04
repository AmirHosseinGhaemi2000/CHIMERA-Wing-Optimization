%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% DIRECT Optimization Function
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [best_design, best_val, exitflag, output] = direct_optimization(obj_fun, lb, ub)
global x_hist;
x_hist = [];  % Reset global design history

max_iter = 500;  % Maximum iterations allowed
tol = 1e-5;       % Tolerance on rectangle half-size (in normalized space)

n = length(lb);  % Number of variables

% Normalize the domain: z in [0,1]^n
% Initial rectangle in normalized space:
z_lb0 = zeros(1, n);
z_ub0 = ones(1, n);
center0 = min(max((z_lb0 + z_ub0) / 2 + 0.1*(rand(1, n)-0.5), 0), 1); % In normalized coordinates
% Map back to original space:
x0 = lb + center0 .* (ub - lb);
f_center0 = obj_fun(x0);
% Define the rectangle size as half the maximum side length in normalized space
d0 = max(z_ub0 - z_lb0) / 2;

% Create initial rectangle structure array
rectList = struct('z_lb', {}, 'z_ub', {}, 'center', {}, 'f_center', {}, 'd', {});
rectList(1) = struct('z_lb', z_lb0, 'z_ub', z_ub0, 'center', center0, 'f_center', f_center0, 'd', d0);

best_val = f_center0;
best_design = x0;
% Store the initial guess in x_hist
x_hist = [x_hist; best_design];

iter = 1;

disp('>> Starting DIRECT optimization iterations...');

while iter <= max_iter
    % Determine potentially optimal rectangles.
    N = length(rectList);
    po_idxs = [];
    for i = 1:N
        isPotential = true;
        for j = 1:N
            if j ~= i
                % If rectangle j has a lower center value and a larger (or equal) half-size,
                % then rectangle i is not potentially optimal.
                if (rectList(j).f_center < rectList(i).f_center) && (rectList(j).d >= rectList(i).d)
                    isPotential = false;
                    break;
                end
            end
        end
        if isPotential
            po_idxs = [po_idxs, i];
        end
    end

    if isempty(po_idxs)
        % Fall back to the rectangle with the smallest f_center if none are identified.
        [~, idx] = min([rectList.f_center]);
        po_idxs = idx;
    end

    % Terminate if the smallest rectangle half-size is below the tolerance.
    d_min = min([rectList.d]);
    if d_min < tol
        disp('>> Termination criterion met (rectangle half-size below tolerance).');
        break;
    end

    newRects = [];
    % Subdivide all potentially optimal rectangles.
    for idx = po_idxs
        R = rectList(idx);
        widths = R.z_ub - R.z_lb;
        max_width = max(widths);
        dims_to_split = find(widths == max_width);

        % For each dimension with maximum width, subdivide.
        for d = dims_to_split
            mid = (R.z_lb(d) + R.z_ub(d)) / 2;
            % Create subrectangle 1: lower portion in dimension d.
            z_lb1 = R.z_lb;
            z_ub1 = R.z_ub;
            z_ub1(d) = mid;
            center1 = (z_lb1 + z_ub1) / 2;
            x1 = lb + center1 .* (ub - lb);
            f_center1 = obj_fun(x1);
            d1 = max(z_ub1 - z_lb1) / 2;
            newRect1 = struct('z_lb', z_lb1, 'z_ub', z_ub1, 'center', center1, 'f_center', f_center1, 'd', d1);

            % Create subrectangle 2: upper portion in dimension d.
            z_lb2 = R.z_lb;
            z_ub2 = R.z_ub;
            z_lb2(d) = mid;
            center2 = (z_lb2 + z_ub2) / 2;
            x2 = lb + center2 .* (ub - lb);
            f_center2 = obj_fun(x2);
            d2 = max(z_ub2 - z_lb2) / 2;
            newRect2 = struct('z_lb', z_lb2, 'z_ub', z_ub2, 'center', center2, 'f_center', f_center2, 'd', d2);

            newRects = [newRects, newRect1, newRect2]; %#ok<AGROW>

            % Update the best solution if improvement is found.
            if f_center1 < best_val
                best_val = f_center1;
                best_design = x1;
            end
            if f_center2 < best_val
                best_val = f_center2;
                best_design = x2;
            end
        end
    end

    % Remove the subdivided rectangles from the list.
    rectList(po_idxs) = [];
    % Add all newly generated rectangles.
    rectList = [rectList, newRects];

    % Update global design history.
    x_hist = [x_hist; best_design];

    % Fancy display of iteration details.
    disp(['[DIRECT] Iteration ', num2str(iter), ...
        ' | Best Value: ', num2str(best_val), ...
        ' | Min Half-Size: ', num2str(d_min)]);

    iter = iter + 1;
end

exitflag = 1;
output.iterations = iter - 1;
output.evaluations = length(x_hist) + 1;  % approximate function evaluation count

disp('>> DIRECT optimization completed.');
disp(['>> Total Iterations: ', num2str(iter - 1)]);
disp(['>> Total Function Evaluations: ', num2str(output.evaluations)]);

% Note: best_design is returned in original space.
end