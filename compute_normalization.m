function normalized = compute_normalization(stats, slope, intercept, far_L, far_R)
%COMPUTE_NORMALIZATION  Normalize position and spread columns based on
%   their header names.
%
%   Normalization formulas:
%   - Mean_L, Median_L, Q1_L, Q3_L: (value - far_L) / slope
%   - Mean_R, Median_R, Q1_R, Q3_R: (value - far_R) / slope
%   - IQR_L, IQR_R: value / slope
%
%   Inputs:
%       stats     - Input table
%       slope     - Slope value (default: 0.980155632)
%       intercept - Intercept value (default: -0.099816481)
%       far_L     - Far Before Median L (default: 0.00521)
%       far_R     - Far Before Median R (default: 0.1206)

    % Default values
    if nargin < 2 || isempty(slope),      slope = 0.980155632;   end
    if nargin < 3 || isempty(intercept),  intercept = -0.099816481; end
    if nargin < 4 || isempty(far_L),      far_L = 0.00521;        end
    if nargin < 5 || isempty(far_R),      far_R = 0.1206;         end

    fprintf('  Normalization Parameters:\n');
    fprintf('    Slope:     %.9f\n', slope);
    fprintf('    Intercept: %.9f\n', intercept);
    fprintf('    Far L:     %.5f\n', far_L);
    fprintf('    Far R:     %.5f\n', far_R);

    % Define column name patterns for normalization
    pos_L_pattern  = {'Mean_L', 'Median_L', 'Q1_L', 'Q3_L'};
    pos_R_pattern  = {'Mean_R', 'Median_R', 'Q1_R', 'Q3_R'};
    spread_pattern = {'IQR_L', 'IQR_R'};

    normalized = stats;

    % Get actual column names from the table
    all_cols = stats.Properties.VariableNames;

    for c = 1:length(all_cols)
        col = all_cols{c};

        % Check if column matches Left position pattern
        if any(strcmp(col, pos_L_pattern))
            % Formula: (value - far_L) / slope
            normalized.(col) = (stats.(col) - far_L) / slope;
            fprintf('    Normalized (Left): %s = (value - %.5f) / %.9f\n', col, far_L, slope);

        % Check if column matches Right position pattern
        elseif any(strcmp(col, pos_R_pattern))
            % Formula: (value - far_R) / slope
            normalized.(col) = (stats.(col) - far_R) / slope;
            fprintf('    Normalized (Right): %s = (value - %.5f) / %.9f\n', col, far_R, slope);

        % Check if column matches spread pattern
        elseif any(strcmp(col, spread_pattern))
            % Formula: value / slope
            normalized.(col) = stats.(col) / slope;
            fprintf('    Normalized (Spread): %s = value / %.9f\n', col, slope);
        end
    end
end