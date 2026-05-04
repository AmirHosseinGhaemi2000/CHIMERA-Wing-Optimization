%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Objective Function (with Penalty Term for Lift Constraint)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function f = obj_fun_design(x, Aer_net, x_scale, y_scale, penalty)
% Evaluate aerodynamic performance for design vector x (8 variables)
[L, D] = aer(Aer_net, x, x_scale, y_scale);
% Compute lift constraint violation: target lift is 600*9.81
eq_violation = (600 * 9.81 / L) - 1;
% Combine drag term and weighted penalty for lift constraint violation
f = (D / 100)^2 + penalty * eq_violation.^2;
f = double(f) ;
end