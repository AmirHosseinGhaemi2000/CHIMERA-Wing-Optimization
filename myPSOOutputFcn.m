% Output function for Particle Swarm Optimization (PSO)
function stop = myPSOOutputFcn(optimValues, state)
global x_hist;
switch state
    case 'init'
        x_hist = [];
    case 'iter'
        % Record the best particle's position in the swarm
        x_hist = [x_hist; optimValues.bestx];
    case 'done'
        % Finalization (if needed)
end
stop = false;
end
