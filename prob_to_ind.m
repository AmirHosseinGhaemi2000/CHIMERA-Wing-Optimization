%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Convert Probabilities to Discrete Indices Function
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [J, C_ind] = prob_to_ind(C)
j = 1;
for i = 1:3:33
    c_dummy = C(:, i:i+2);
    [~, I] = max(c_dummy);
    I = I - 1;
    C_ind(:, j) = I;
    j = j + 1;
end

J = 0;
alpha = 0.9;
for i = 3*[1, 2, 5, 9] - 1
    J = J + alpha * (C(:, i) - C(:, i - 1)) + (1 - alpha) * (C(:, i) - C(:, i + 1));
end
end