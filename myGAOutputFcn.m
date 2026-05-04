% Output function for Genetic Algorithm (GA)
function [state, options, optchanged] = myGAOutputFcn(options, state, flag)
global x_hist;
switch flag
    case 'init'
        x_hist = [];
    case 'iter'
        % Retrieve the best candidate from the current population
        [~, idx] = min(state.Score);
        best_x = state.Population(idx, :);
        x_hist = [x_hist; best_x];
    case 'done'
        % Finalization (if needed)
end
optchanged = false;
end