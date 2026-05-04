%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Stability Evaluation Function
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [cost, S] = Cont(model_c, swarm_pos, x_scale, ~)
n = size(swarm_pos, 1);

for i = 1:n
    x = swarm_pos(i, :);
    % Scale the design vector to the model's input range
    x = -2 + 4 * (x - x_scale(1, :)) ./ (x_scale(2, :) - x_scale(1, :));
    out = predict(model_c, x);
    [J, out] = prob_to_ind(out);
end

S = out(1:10);
cost = J;
end