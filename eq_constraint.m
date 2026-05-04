%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Non-Linear Equality Constraint for Target Lift
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function h_val = eq_constraint(x, Aer_net, x_scale, y_scale)
[L, ~] = aer(Aer_net, x, x_scale, y_scale);
L = double(L);  % Ensure numeric type
h_val = double((600 * 9.81 / L) - 1);
end