%% Plotting Results
clear; close all; clc;

load('../Results/2/results_lipschitz.mat');

% Define common plot style properties
FS = 12;                    % Font size
fontName = 'CMU Serif';     % Font name
lineWidthVal = 1;           % Line width for plots

% Set LaTeX interpreter for all text and axes labels
set(0, 'DefaultTextInterpreter', 'latex');
set(0, 'DefaultAxesTickLabelInterpreter', 'latex');

%% Figure 1: Evolution of Wing Geometry
figure(1);
% Plot initial wing geometry (black dashed line)
x0_design = x_hist(1,:) ;
[maxx1, miny1, maxy1] = plot_wing(x0_design(4), x0_design(1), x0_design(6), x0_design(3), 1, 'k', '--');

% Plot optimized wing geometry (red solid line)
hold on;
[maxx2, miny2, maxy2] = plot_wing(best_design(4), best_design(1), best_design(6), best_design(3), 1, 'r', '-');
legend({'Initial Wing', 'Optimized Wing'}, 'Interpreter', 'latex', ...
    'FontName', fontName, 'FontSize', FS,'Location','northeast');
title('Evolution of Wing Geometry', 'Interpreter', 'latex', ...
    'FontName', fontName, 'FontSize', FS);
grid on;
grid minor;
set(gca, 'FontName', fontName, 'FontSize', FS, 'TickLabelInterpreter', 'latex');
hold off;

% Adjust plot limits for clarity
temp = (max(maxy1, maxy2)*1.2 - min(miny1, miny2)*1.2) * 0.1;
% ylim([min(miny1, miny2)-temp, max(maxy1, maxy2)+temp]);
xlim([0, max(maxx1, maxx2)/2*1.1]);

%% Figure 2: Evolution of Lift and Drag over Iterations
% Compute lift and drag history from design history
for i = 1:size(x_hist, 1)
    [L_hist(i), D_hist(i)] = aer(Aer_net, x_hist(i, :), x_scale, y_scale);  %#ok<SAGROW>
end

figure(2);
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