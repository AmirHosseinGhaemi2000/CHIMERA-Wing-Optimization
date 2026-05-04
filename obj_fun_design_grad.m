%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Objective Function for Gradient-Based Optimization
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function f = obj_fun_design_grad(x, Aer_net, x_scale, y_scale)
% Evaluate aerodynamic performance for design vector x (8 variables)
[~, D] = aer(Aer_net, x, x_scale, y_scale);
D = double(D);  % Ensure numeric type
% Objective: minimize the squared drag (scaled)
f = (D / 750)^2;
end