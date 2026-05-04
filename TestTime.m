%% Independent Script: Neural Network Timing Test
clear;
close all;
clc;

warning('off', 'all');

%% Reproducibility
rng(1);   % fixed random seed

%% Load Models and Scaling Data
Aer_net  = importKerasNetwork('model.h5');
Cont_net = importKerasNetwork('model_c.h5');

x_scale = load("min_max_vals_x.mat");
x_scale = x_scale.matrix_name;

y_scale = load("min_max_vals_y.mat");
y_scale = y_scale.matrix_name;

%% Bounds
lb = [0.5, -3, 0, 1  , 0, 0.2, -6, 35];
ub = [1.4,  8, 7, 7.5, 5, 0.8,  6, 58];

%% Timing Settings
n_runs = 20;
time_NN = zeros(n_runs,1);

%% Generate Samples Outside Loop
X_samples = lb + rand(n_runs, length(lb)) .* (ub - lb);

%% Warm-up
for k = 1:10
    [~, ~] = aer(Aer_net, X_samples(1,:), x_scale, y_scale);
    [~, ~] = Cont(Cont_net, X_samples(1,:), x_scale, 0);
end

%% Timing Loop
for i = 1:n_runs
    x_sample = X_samples(i,:);

    tic;
    [~, ~] = aer(Aer_net, x_sample, x_scale, y_scale);
    [~, ~] = Cont(Cont_net, x_sample, x_scale, 0);
    time_NN(i) = toc;
end

%% Results
avg_time_NN = mean(time_NN);
std_time_NN = std(time_NN);
median_time_NN = median(time_NN);

fprintf('\n================ TIMING RESULTS ================\n');
fprintf('Number of runs: %d\n', n_runs);
fprintf('Average NN time : %.6f seconds (%.3f ms)\n', avg_time_NN, avg_time_NN*1000);
fprintf('Median NN time  : %.6f seconds (%.3f ms)\n', median_time_NN, median_time_NN*1000);
fprintf('Std deviation   : %.6f seconds (%.3f ms)\n', std_time_NN, std_time_NN*1000);
fprintf('===============================================\n');