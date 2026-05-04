%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Lipschitz Optimization Function with Gradient-Based Local Search
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [best_design, best_val, exitflag, output] = lipschitz_optimization(obj_fun, lb, ub, Aer_net, x_scale, y_scale)
global x_hist;
x_hist = []; % Reset history at the start

% Parameters
max_iter = 500;           % Maximum number of iterations
tol = 1e-3;               % Global termination tolerance on box diameter
tol_local = 6;            % Threshold below which a local search is invoked
r = 1.1;                  % Reliability parameter (global scaling for Lipschitz estimate)

% Initialize storage for evaluated points
eval_points = [];
eval_values = [];

% Define a structure array for boxes
% Each box: lb, ub, center, f_center, diameter, and characteristic (char)
boxList = struct('lb', {}, 'ub', {}, 'center', {}, 'f_center', {}, 'diameter', {}, 'char', {});

% Create the initial box covering the entire design space
center0 = (lb + ub) / 2 + 0.1*(rand(1, length(lb))-0.5).*(ub-lb);
f_center0 = obj_fun(center0);
eval_points = [eval_points; center0];
eval_values = [eval_values; f_center0];
diameter0 = norm(ub - lb, Inf); % Infinity norm as box size
L_est = 1e-32;  % Initial (very small) Lipschitz constant estimate
char0 = f_center0 - L_est * (diameter0 / 2);
boxList(1) = struct('lb', lb, 'ub', ub, 'center', center0, 'f_center', f_center0, 'diameter', diameter0, 'char', char0);

best_val = f_center0;
best_design = center0;
disp(best_design(1))
% Record the initial design
x_hist = [x_hist; best_design];

iter = 1;
disp('>> Starting enhanced Lipschitz optimization iterations...');

while iter <= max_iter
    % Update Lipschitz constant estimate based on all evaluated points (global estimate)
    for i = 1:size(eval_points,1)
        for j = i+1:size(eval_points,1)
            dist = norm(eval_points(i,:) - eval_points(j,:), 2);
            if dist > 0
                L_est = max(L_est, abs(eval_values(i) - eval_values(j)) / dist);
            end
        end
    end
    L_est = r * L_est;  % Apply reliability factor

    % Update the characteristic for each box in the list
    for k = 1:length(boxList)
        boxList(k).char = boxList(k).f_center - L_est * (boxList(k).diameter / 2);
    end

    % Select the box with the smallest characteristic value
    [~, idx] = min([boxList.char]);
    selectedBox = boxList(idx);

    % Global termination: if the selected box is sufficiently small, stop
    if selectedBox.diameter < tol
        disp('>> Global termination: box diameter below tolerance.');
        break;
    end

    disp(['Boxes left:',num2str(numel(boxList))]) ;
    % If the selected box is very small, invoke a local search to refine the solution
    if selectedBox.diameter < tol_local
        disp('Applying gradient-based local search')

        % Define the non-linear equality constraint: target lift must equal 600*9.81
        nonlcon = @(x) deal([], eq_constraint(x, Aer_net, x_scale, y_scale));
        % Configure fmincon options with a history output function
        opts = optimoptions('fmincon', 'Algorithm', 'interior-point', 'Display', 'off', ...
            'ConstraintTolerance', 1e-2, 'StepTolerance', 1e-40, 'MaxIterations', 250, ...
            'EnableFeasibilityMode', true);
        obj_fun_grad = @(x)obj_fun_design_grad(x, Aer_net, x_scale, y_scale) ;
        [local_sol, ~, exitflag] = fmincon(obj_fun_grad, selectedBox.center, [], [], [], [],...
            selectedBox.lb, selectedBox.ub, nonlcon, opts);

        disp(['Exit flag of constrained optim process:',num2str(exitflag)])
        local_val = obj_fun_grad(local_sol) ;
        if local_val <= obj_fun_grad(best_design) && exitflag > 0
            best_val = local_val;
            best_design = local_sol;
            x_hist = [x_hist; best_design];
        end

        % Remove the box from further consideration and continue
        boxList(idx) = [];

        % Check if there are no boxes left; if so, terminate the loop.
        if isempty(boxList)
            disp('>> No more boxes to subdivide. Terminating optimization.');
            break;
        end

        iter = iter + 1;
        continue;
    end

    % Determine the dimensions with the maximum width
    widths = selectedBox.ub - selectedBox.lb;
    max_width = max(widths);
    dims = find(abs(widths - max_width) < 1e-12); % All dimensions with max width

    % Simultaneously subdivide selectedBox along all dimensions in 'dims'
    m = length(dims);
    newBoxes = [];
    % There are 2^m subdivisions; iterate over all binary combinations
    for b = 0:(2^m - 1)
        bits = dec2bin(b, m) - '0';  % Convert to binary vector (0 or 1)
        new_lb = selectedBox.lb;
        new_ub = selectedBox.ub;
        % For each dimension in dims, update bounds based on bit value
        for j = 1:m
            d = dims(j);
            mid = (selectedBox.lb(d) + selectedBox.ub(d)) / 2;
            if bits(j) == 0
                new_ub(d) = mid;
            else
                new_lb(d) = mid;
            end
        end
        new_center = (new_lb + new_ub) / 2;
        new_f_center = obj_fun(new_center);
        eval_points = [eval_points; new_center];
        eval_values = [eval_values; new_f_center];
        new_diameter = norm(new_ub - new_lb, Inf);
        new_char = new_f_center - L_est * (new_diameter / 2);
        new_box = struct('lb', new_lb, 'ub', new_ub, 'center', new_center, ...
            'f_center', new_f_center, 'diameter', new_diameter, 'char', new_char);
        newBoxes = [newBoxes, new_box]; %#ok<AGROW>
        if new_f_center < best_val
            best_val = new_f_center;
            best_design = new_center;
        end
    end

    % Remove the subdivided selected box and add the new boxes
    boxList(idx) = [];
    boxList = [boxList, newBoxes];

    % Update global design history
    x_hist = [x_hist; best_design];

    % Display iteration details
    disp(['Iteration: ', num2str(iter), ' | Best Value: ', num2str(best_val), ...
        ' | Selected Box Diameter: ', num2str(selectedBox.diameter), ...
        ' | Subdivided Dimensions: ', num2str(dims)]);
    iter = iter + 1;
end

exitflag = 1;
output.iterations = iter - 1;
output.evaluations = size(eval_points, 1);

disp('>> Lipschitz optimization completed.');
disp(['>> Total Iterations: ', num2str(iter - 1)]);
disp(['>> Total Function Evaluations: ', num2str(output.evaluations)]);
end