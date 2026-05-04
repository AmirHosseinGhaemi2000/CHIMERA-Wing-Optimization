%% Batch summarize results from ../Results/1 and ../Results/2
clear; clc;

% === Config: where to look ===
baseDir   = '../Results';
subDirs   = {'1','2'};                 % folders to scan
pattern   = 'results_*.mat';           % file pattern

% === Load models and scaling (needed to compute L,D,CL,CD) ===
warning('off','all');
Aer_net = importKerasNetwork('model.h5');
x_scale = load("min_max_vals_x.mat"); x_scale = x_scale.matrix_name;
y_scale = load("min_max_vals_y.mat"); y_scale = y_scale.matrix_name;

% === DOF names for stability variables ===
DOF_names = {'S_F_X_U','S_M_U','S_F_Y_V','S_F_Z_W', ...
             'S_M_Alpha','S_L_Beta','S_N_Beta', ...
             'S_L_P','S_M_Q','S_N_R'};

% === Collect results ===
rows = [];
rowIdx = 0;

for s = 1:numel(subDirs)
    thisDir = fullfile(baseDir, subDirs{s});
    if ~isfolder(thisDir)
        warning('Directory not found: %s', thisDir);
        continue;
    end

    files = dir(fullfile(thisDir, pattern));
    if isempty(files)
        warning('No files matching %s in %s', pattern, thisDir);
        continue;
    end

    for k = 1:numel(files)
        filePath = fullfile(files(k).folder, files(k).name);
        try
            data = load(filePath);

            % --- Extract final/best design (8 variables) ---
            x_final = [];
            if isfield(data, 'best_design') && ~isempty(data.best_design)
                x_final = data.best_design(:).';              % row vector 1x8
            elseif isfield(data, 'x_hist') && ~isempty(data.x_hist)
                x_final = data.x_hist(end, 1:8);              % last best-so-far
            end

            if isempty(x_final) || numel(x_final) < 8
                warning('Skipping (no final design found): %s', filePath);
                continue;
            end

            % --- Compute performance: L, D, CL, CD ---
            [L, D]   = aer(Aer_net, x_final, x_scale, y_scale);
            [CL, CD] = aer_clcd(Aer_net, x_final, x_scale, y_scale);

            % --- Stability variables (S vector) ---
            Svec = nan(1, numel(DOF_names));
            if isfield(data, 'S') && numel(data.S) == numel(DOF_names)
                Svec = data.S(:).';  % row vector 1x10
            end

            % --- Derive a method name from filename if possible ---
            method = '';
            tok = regexp(files(k).name, '^results_([^.]+)\.mat$', 'tokens', 'once');
            if ~isempty(tok), method = tok{1}; end

            % --- Accumulate row ---
            rowIdx = rowIdx + 1;
            rows(rowIdx).folder    = subDirs{s};          %#ok<SAGROW>
            rows(rowIdx).file      = files(k).name;       %#ok<SAGROW>
            rows(rowIdx).method    = method;              %#ok<SAGROW>
            rows(rowIdx).root_chord= x_final(1);          %#ok<SAGROW>
            rows(rowIdx).alpha     = x_final(2);          %#ok<SAGROW>
            rows(rowIdx).sweep     = x_final(3);          %#ok<SAGROW>
            rows(rowIdx).span      = x_final(4);          %#ok<SAGROW>
            rows(rowIdx).twist     = x_final(5);          %#ok<SAGROW>
            rows(rowIdx).taper     = x_final(6);          %#ok<SAGROW>
            rows(rowIdx).dihedral  = x_final(7);          %#ok<SAGROW>
            rows(rowIdx).velocity  = x_final(8);          %#ok<SAGROW>
            rows(rowIdx).L         = L;                   %#ok<SAGROW>
            rows(rowIdx).D         = D;                   %#ok<SAGROW>
            rows(rowIdx).CL        = CL;                  %#ok<SAGROW>
            rows(rowIdx).CD        = CD;                  %#ok<SAGROW>

            % Attach stability values with proper names
            for j = 1:numel(DOF_names)
                fname = DOF_names{j};
                rows(rowIdx).(fname) = Svec(j);           %#ok<SAGROW>
            end

        catch ME
            warning('Failed on %s: %s', filePath, ME.message);
            continue;
        end
    end
end

if ~isempty(rows)
    % === Convert to table ===
    T = struct2table(rows);

    % Reorder columns: metadata → design vars → performance → stability
    T = movevars(T, {'folder','file','method'}, 'Before', 1);
    T = movevars(T, {'root_chord','alpha','sweep','span','twist','taper','dihedral','velocity'}, 'After', 'method');
    T = movevars(T, {'L','D','CL','CD'}, 'After', 'velocity');

    % === Save outputs ===
    outMat = fullfile(baseDir, 'summary_results.mat');
    outCsv = fullfile(baseDir, 'summary_results.csv');
    save(outMat, 'T');
    writetable(T, outCsv);

    % === Quick preview ===
    disp('--- Summary of final designs, performance, and stability ---');
    disp(T(1:min(10,height(T)), :)); % preview first 10 rows

else
    warning('No valid results found to summarize.');
end