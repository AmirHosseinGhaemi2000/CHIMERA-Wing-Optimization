function [CL, CD] = aer_clcd(model, swarm_pos, x_scale, y_scale)
n = size(swarm_pos, 1);
for i = 1:n
    x = swarm_pos(i, :);
    % Scale the design vector appropriately for the model input
    x = -2 + 4 * (x - x_scale(1, :)) ./ (x_scale(2, :) - x_scale(1, :));
    out = predict(model, x);
    out = (out + 2) .* (y_scale(2, :) - y_scale(1, :)) / 4 + (y_scale(1, :));

    % Assign coefficients of Lift (CL) and Drag (CD)
    CL = out(7);
    CD = out(8);
end
end