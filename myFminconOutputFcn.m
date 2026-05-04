%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Output Functions for Tracking Design History
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Output function for fmincon (Gradient-Based Method)
function stop = myFminconOutputFcn(x, ~, state)
global x_hist x_hist_all run_idx;
switch state
    case 'init'
        x_hist = [];
    case 'iter'
        x_hist = [x_hist; x];
    case 'done'
        if isempty(x_hist_all)
            x_hist_all = {};
            run_idx = 1;
        else
            run_idx = run_idx + 1;
        end
        x_hist_all{run_idx} = x_hist;  % Store current run's history
end
stop = false;
end