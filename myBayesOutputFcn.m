% Output function for Bayesian Optimization
function stop = myBayesOutputFcn(results, state)
    global x_hist;
    stop = false;

    switch state
        case 'initial'
            % Reset history
            x_hist = [];

        case 'iteration'
            % Get best-so-far design (not just last evaluated point!)
            bt = results.XAtMinObjective;  % table of variables
            x_current = [bt.root_chord, bt.alpha, bt.sweep, bt.span, ...
                         bt.twist, bt.taper_ratio, bt.dihedral, bt.velocity];

            % Append to history
            x_hist = [x_hist; x_current];

        case 'done'
            % Optional: nothing special needed
    end
end