%% Main Script: Wing Design Optimization with Multi-Method Approaches
clear;
close all;
clc;

% (Optional) Delete any previous history file and initialize the global design history variable
% delete('hist.mat');
global x_hist x_hist_all run_idx; %#ok<*GVMIS,*NUSED>
x_hist = []; % Reset history at the start
x_hist_all = []; % Reset history at the start
run_idx= []; % Reset history at the start

%% Load Pre-trained Models and Scaling Data
warning('off', 'all');

disp('>> Loading pre-trained TensorFlow models for Aerodynamics and Stability...');
Aer_net = importKerasNetwork('model.h5');
Cont_net = importKerasNetwork('model_c.h5');
disp('>> TensorFlow models loaded successfully!');
disp('============================================================');

% Load scaling factors for design variables (x) and performance outputs (y)
x_scale = load("min_max_vals_x.mat");
x_scale = x_scale.matrix_name;
y_scale = load("min_max_vals_y.mat");
y_scale = y_scale.matrix_name;

%% Initialize Design Variables and Bounds
% Design variable order:
% [root chord, angle of attack, sweep, span, twist, taper ratio, dihedral, velocity]
% lb = [0.35, -3, 0, 4 , 0, 0.1, 0, 35];   % Lower bounds
% ub = [1.3 ,  8, 7, 11, 5, 0.5, 6, 58];   % Upper bounds

lb = [0.5, -3, 0, 1  , 0, 0.2, -6, 35];    % Lower bounds
ub = [1.4,  8, 7, 7.5, 5, 0.8,  6, 58];    % Upper bounds

% Define penalty parameter (used for Derivative free algorithms)
penalty = 100;

%% Select Optimization Algorithm: 'pso', 'ga', 'grad', 'bayes', 'lipschitz' or 'direct'
opt_mode = 'grad';  % Change this value to select the desired optimization method

%% Run the Selected Optimization Routine
switch opt_mode
    case 'pso'
        disp('>> Starting Particle Swarm Optimization with Penalty Constraints...');
        nvars = 8;
        % Configure PSO options (swarm size, max iterations, etc.)
        psoOptions = optimoptions('particleswarm', 'Display', 'iter', ...
            'SwarmSize', 200, 'MaxIterations', 1000, 'MaxStallIterations', 20, 'OutputFcn', @myPSOOutputFcn);
        [best_design, fval, exitflag, output] = particleswarm(...
            @(x)obj_fun_design(x, Aer_net, x_scale, y_scale, penalty), nvars, lb, ub, psoOptions);
        disp('>> Particle Swarm Optimization completed successfully.');

    case 'ga'
        disp('>> Starting Genetic Algorithm with Penalty Constraints...');
        nvars = 8;
        gaOptions = optimoptions('ga', 'Display', 'iter', 'PopulationSize', 200, ...
            'MaxGenerations', 1000, 'MaxStallGenerations', 20, 'OutputFcn', @myGAOutputFcn);
        [best_design, fval, exitflag, output] = ga(...
            @(x)obj_fun_design(x, Aer_net, x_scale, y_scale, penalty), nvars, [], [], [], [], lb, ub, [], gaOptions);
        disp('>> Genetic Algorithm optimization completed successfully.');

    case 'grad'
        disp('>> Starting Gradient-Based Optimization using MultiStart + fmincon...');
        nvars = 8;

        % Generate a random initial design within bounds
        x0_design = lb + rand(size(lb)) .* (ub - lb);

        % Show initial aerodynamic performance
        disp('>> Evaluating initial aerodynamic performance...');
        [L0, D0] = aer(Aer_net, x0_design, x_scale, y_scale);
        disp(['   Initial Lift value: ', num2str(L0)]);
        disp(['   Initial Drag value: ', num2str(D0)]);

        % Define non-linear equality constraint
        nonlcon = @(x) deal([], eq_constraint(x, Aer_net, x_scale, y_scale));

        % Set fmincon options
        options = optimoptions('fmincon', ...
            'Algorithm', 'interior-point', ...
            'Display', 'iter-detailed', ...
            'MaxIterations', 5000, ...
            'MaxFunctionEvaluations', 1e6, ...
            'StepTolerance', 1e-12, ...
            'OptimalityTolerance', 1e-6, ...
            'ConstraintTolerance', 1e-3, ...
            'EnableFeasibilityMode', true, ...
            'ScaleProblem', true, ...
            'OutputFcn', @myFminconOutputFcn);

        % Wrap problem for MultiStart
        problem = createOptimProblem('fmincon', ...
            'objective', @(x)obj_fun_design_grad(x, Aer_net, x_scale, y_scale), ...
            'x0', x0_design, ...
            'lb', lb, ...
            'ub', ub, ...
            'nonlcon', nonlcon, ...
            'options', options);

        % Set up and run MultiStart
        ms = MultiStart('Display', 'iter', 'UseParallel', false);  % Change to true if using parallel toolbox
        n_starts = 20;  % Number of starting points
        [best_design, fval, exitflag, output, solutions] = run(ms, problem, n_starts);

        match_found = false;
        for j = 1:length(x_hist_all)
            final_design = x_hist_all{j}(end, :);
            if norm(final_design - best_design) < 1e-8
                x_hist = x_hist_all{j};  % Correct trajectory for best design
                disp(['>> Matched best MultiStart run history: x_hist_all{', num2str(j), '}']);
                match_found = true;
                break;
            end
        end

        if ~match_found
            warning('Best design not found in x_hist_all. Using most recent history.');
        end


        disp('>> Gradient-based MultiStart optimization completed successfully.');

    case 'bayes'
        disp('>> Starting Bayesian Optimization with Penalty Constraints...');
        % Define optimizable variables for each design parameter
        vars = [optimizableVariable('root_chord', [lb(1), ub(1)]), ...
            optimizableVariable('alpha', [lb(2), ub(2)]), ...
            optimizableVariable('sweep', [lb(3), ub(3)]), ...
            optimizableVariable('span', [lb(4), ub(4)]), ...
            optimizableVariable('twist', [lb(5), ub(5)]), ...
            optimizableVariable('taper_ratio', [lb(6), ub(6)]), ...
            optimizableVariable('dihedral', [lb(7), ub(7)]), ...
            optimizableVariable('velocity', [lb(8), ub(8)])];

        % Objective function that accepts a table input
        fun = @(x)obj_fun_design([x.root_chord, x.alpha, x.sweep, x.span, x.twist, x.taper_ratio, x.dihedral, x.velocity], Aer_net, x_scale, y_scale, penalty);

        % Run Bayesian optimization with history tracking
        bayesResults = bayesopt(fun, vars, ...
            'ExplorationRatio', 0.8, ...
            'MaxObjectiveEvaluations', 150, ...
            'IsObjectiveDeterministic', true, ...
            'Verbose', 2, ...
            'AcquisitionFunctionName', 'expected-improvement', ...
            'GPActiveSetSize', 200, ...
            'UseParallel', false, ...
            'NumSeedPoints', 100, ...
            'OutputFcn', @myBayesOutputFcn);

        best_table = bayesResults.XAtMinObjective;
        best_design = [best_table.root_chord, best_table.alpha, best_table.sweep, best_table.span, ...
            best_table.twist, best_table.taper_ratio, best_table.dihedral, best_table.velocity];
        fval = bayesResults.MinObjective;
        exitflag = [];
        output = bayesResults;
        disp('>> Bayesian Optimization completed successfully.');

    case 'lipschitz'
        disp('>> Starting Lipschitz Optimization with Adaptive L Refinement...');
        nvars = 8;
        obj_fun = @(x)obj_fun_design(x, Aer_net, x_scale, y_scale, penalty);
        [best_design, fval, exitflag, output] = lipschitz_optimization(obj_fun, lb, ub, Aer_net, x_scale, y_scale);
        disp('>> Lipschitz Optimization completed successfully.');

    case 'direct'
        disp('>> Starting DIRECT Optimization...');
        nvars = 8;
        obj_fun = @(x)obj_fun_design(x, Aer_net, x_scale, y_scale, penalty);
        [best_design, fval, exitflag, output] = direct_optimization(obj_fun, lb, ub);
        disp('>> DIRECT Optimization completed successfully.');

    otherwise
        error('Unknown optimization mode. Please choose "pso", "ga", "grad", "bayes", "lipschitz", or "direct".');
end

%% Display Final Optimization Results
disp('============================================================');
disp('>> Optimized Design Variables:');
disp(best_design);
[L_final, D_final] = aer(Aer_net, best_design, x_scale, y_scale);
fprintf('>> Final Drag Performance: %.4f\n', D_final);
fprintf('>> Final Lift Performance: %.4f\n', L_final);
disp('============================================================');

%% Stability Verification
[~, S] = Cont(Cont_net, x_hist(end, 1:8), x_scale, 0);

DOF_names = {'S_F_X_U', 'S_M_U', 'S_F_Y-V', 'S_F_Z_W', ...
    'S_M_Alpha', 'S_L_Beta', 'S_N_Beta', ...
    'S_L_P', 'S_M_Q', 'S_N_R'};

n = 0;
for i = 1:length(S)
    if S(i) == 0
        disp(['!! Instability Detected in DOF index ', num2str(i), ...
            ' → ', DOF_names{i}]);
        n = n + 1;
    end
end

if n == 0
    disp('>> All degrees of freedom are stable or semi-stable.');
end

%% Plotting Results

% Define common plot style properties
FS = 12;                    % Font size
fontName = 'CMU Serif';     % Font name
lineWidthVal = 1;           % Line width for plots

% Set LaTeX interpreter for all text and axes labels
set(0, 'DefaultTextInterpreter', 'latex');
set(0, 'DefaultAxesTickLabelInterpreter', 'latex');

%% Figure 1: Evolution of Wing Geometry
figure(1);
set(gcf, 'WindowState', 'maximized');

% Plot initial wing geometry (black dashed line)
x0_design = x_hist(1,:) ;
[maxx1, miny1, maxy1] = plot_wing(x0_design(4), x0_design(1), x0_design(6), x0_design(3), 1, 'k', '--');

% Plot optimized wing geometry (red solid line)
hold on;
[maxx2, miny2, maxy2] = plot_wing(best_design(4), best_design(1), best_design(6), best_design(3), 1, 'r', '-');
legend({'Initial Wing', 'Optimized Wing'}, 'Interpreter', 'latex', ...
    'FontName', fontName, 'FontSize', FS);
title('Evolution of Wing Geometry', 'Interpreter', 'latex', ...
    'FontName', fontName, 'FontSize', FS);
grid on;
grid minor;
set(gca, 'FontName', fontName, 'FontSize', FS, 'TickLabelInterpreter', 'latex');
hold off;

% Adjust plot limits for clarity
temp = (max(maxy1, maxy2)*1.2 - min(miny1, miny2)*1.2) * 0.1;
ylim([min(miny1, miny2)-temp, max(maxy1, maxy2)+temp]);
xlim([0, max(maxx1, maxx2)/2*1.1]);

%% Figure 2: Evolution of Lift and Drag over Iterations
% Compute lift and drag history from design history
for i = 1:size(x_hist, 1)
    [L_hist(i), D_hist(i)] = aer(Aer_net, x_hist(i, :), x_scale, y_scale);  %#ok<SAGROW>
end

figure(2);
set(gcf, 'WindowState', 'maximized');
colororder({'k', 'r'});  % Ensure left/right curves use black/red

% Plot Lift (left y-axis)
yyaxis left;
plot(L_hist, 'LineWidth', lineWidthVal, 'Color', 'k');
yline(600*9.81, 'k--', 'Target Lift', 'LabelHorizontalAlignment', 'left', ...
    'LineWidth', lineWidthVal, 'Interpreter', 'latex');
ylabel('Lift (N)', 'Interpreter', 'latex', 'FontName', fontName, 'FontSize', FS);
xlim([1, length(L_hist)]);
tempplot = (max(L_hist) - min(L_hist)) * 0.05;
ylim([min(L_hist)-tempplot, max(L_hist)+tempplot]);

% Plot Drag (right y-axis)
yyaxis right;
plot(D_hist, 'LineWidth', lineWidthVal, 'Color', 'r');
ylabel('Drag (N)', 'Interpreter', 'latex', 'FontName', fontName, 'FontSize', FS);
grid on;
grid minor;
title('Evolution of Lift and Drag over Iterations', 'Interpreter', 'latex', ...
    'FontName', fontName, 'FontSize', FS);
xlabel('Iteration', 'Interpreter', 'latex', 'FontName', fontName, 'FontSize', FS);
set(gca, 'FontName', fontName, 'FontSize', FS, 'TickLabelInterpreter', 'latex');
xlim([1, length(L_hist)]);
tempplot = (max(D_hist)-min(D_hist)) * 0.05;
ylim([min(D_hist)-tempplot, max(D_hist)+tempplot]);

%% Figure 3: Evolution of Individual Design Variables
figure(3);
set(gcf, 'WindowState', 'maximized');
for i = 1:8
    subplot(2, 4, i);
    % Use black for odd-indexed variables, red for even-indexed
    if mod(i, 2) == 1
        plot(x_hist(:, i), 'LineWidth', lineWidthVal, 'Color', 'k');
    else
        plot(x_hist(:, i), 'LineWidth', lineWidthVal, 'Color', 'r');
    end

    % Set descriptive axis labels for each design variable
    switch i
        case 1, varName = 'Root Chord (m)';
        case 2, varName = 'Angle of Attack (deg)';
        case 3, varName = 'Sweep Angle (deg)';
        case 4, varName = 'Span (m)';
        case 5, varName = 'Twist Angle (deg)';
        case 6, varName = 'Taper Ratio';
        case 7, varName = 'Dihedral Angle (deg)';
        case 8, varName = 'Velocity (m/s)';
    end
    ylabel(varName, 'Interpreter', 'latex', 'FontName', fontName, 'FontSize', FS);
    xlabel('Iteration', 'Interpreter', 'latex', 'FontName', fontName, 'FontSize', FS);
    grid on;
    grid minor;
    set(gca, 'FontName', fontName, 'FontSize', FS, 'TickLabelInterpreter', 'latex');
    tempplot = (max(x_hist(:, i))-min(x_hist(:, i))) * 0.05;
    ylim([min(x_hist(:, i))-tempplot, max(x_hist(:, i))+tempplot]);
    xlim([1, length(x_hist(:, i))]);
end
sgtitle('Evolution of Individual Design Variables over Iterations', 'Interpreter', 'latex', ...
    'FontName', fontName, 'FontSize', FS+2);

%% Figure 4: Evolution of $C_L$ and $C_D$ over Iterations
% Compute history for coefficients of lift (CL) and drag (CD)
for i = 1:size(x_hist, 1)
    [CL(i), CD(i)] = aer_clcd(Aer_net, x_hist(i, 1:8), x_scale, y_scale);  %#ok<SAGROW>
end

figure(4);
set(gcf, 'WindowState', 'maximized');
colororder({'k', 'r'});
yyaxis left;
plot(CL, 'LineWidth', lineWidthVal, 'Color', 'k');
ylabel('$C_L$', 'Interpreter', 'latex', 'FontName', fontName, 'FontSize', FS);
xlim([1, length(CL)]);
tempplot = (max(CL)-min(CL)) * 0.05;
ylim([min(CL)-tempplot, max(CL)+tempplot]);

yyaxis right;
plot(CD, 'LineWidth', lineWidthVal, 'Color', 'r');
ylabel('$C_D$', 'Interpreter', 'latex', 'FontName', fontName, 'FontSize', FS);
grid on;
grid minor;
title('Evolution of Coefficients of Lift ($C_L$) and Drag ($C_D$) over Iterations', 'Interpreter', 'latex', ...
    'FontName', fontName, 'FontSize', FS);
xlabel('Iteration', 'Interpreter', 'latex', 'FontName', fontName, 'FontSize', FS);
set(gca, 'FontName', fontName, 'FontSize', FS, 'TickLabelInterpreter', 'latex');
xlim([1, length(CD)]);
tempplot = (max(CD)-min(CD)) * 0.05;
ylim([min(CD)-tempplot, max(CD)+tempplot]);

%% Save Workspace with Method Name
save_filename = ['results_', opt_mode, '.mat'];
save(save_filename);
disp(['>> Workspace saved as "', save_filename, '".']);