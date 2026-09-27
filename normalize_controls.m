function normalize_controls()
%NORMALIZE_CONTROLS  Normalize control data based on column titles.
%   Reads from controls_extracted.xlsx and applies normalization formulas.
%
%   Normalization formulas:
%   - Mean_L, Med_L, Q1_L, Q3_L: (value - far_L) / slope
%   - Mean_R, Med_R, Q1_R, Q3_R: (value - far_R) / slope
%   - IQR_L, IQR_R: value / slope

    input_file    = 'output/controls_extracted.xlsx';
    output_file   = 'output/controls_normalized.xlsx';
    
    % Normalization parameters
    slope      = 0.980155632;
    intercept  = -0.099816481;
    far_L      = 0.00521;
    far_R      = 0.1206;

    % Column title mappings (source title -> output title)
    column_mappings = {
        'Mean_L',          'Mean_L',           'Mean Left';
        'SD_L',            'SD_L',             'Standard Deviation Left';
        'x',               'x',                'Separator';
        'Mean_R',          'Mean_R',           'Mean Right';
        'SD_R',            'SD_R',             'Standard Deviation Right';
        'x_1',             'x_1',              'Separator';
        'Med_L',           'Med_L',            'Median Left';
        'Q1_L',            'Q1_L',             'Q1 Left';
        'Q3_L',            'Q3_L',             'Q3 Left';
        'IQR_L',           'IQR_L',            'IQR Left';
        'x_2',             'x_2',              'Separator';
        'Med_R',           'Med_R',            'Median Right';
        'Q1_R',            'Q1_R',             'Q1 Right';
        'Q3_R',            'Q3_R',             'Q3 Right';
        'IQR_R',           'IQR_R',            'IQR Right';
        'x_3',             'x_3',              'Separator';
        'Mean_Pupil_L',    'Mean_Pupil_L',     'Mean Pupil Left';
        'SD_Pupil_L',      'SD_Pupil_L',       'Standard Deviation Pupil Left';
        'x_4',             'x_4',              'Separator';
        'Mean_Pupil_R',    'Mean_Pupil_R',     'Mean Pupil Right';
        'SD_Pupil_R',      'SD_Pupil_R',       'Standard Deviation Pupil Right';
        'x_5',             'x_5',              'Separator';
        'Mean_InterPupilDist', 'Mean_InterPupilDist', 'Mean InterPupil Distance';
        'SD_InterPupilDist',   'SD_InterPupilDist',   'Standard Deviation InterPupil Distance';
        'x_6',             'x_6',              'Separator';
        'Mean_X_L',        'Mean_X_L',         'Mean X Left';
        'SD_X_L',          'SD_X_L',           'Standard Deviation X Left';
        'x_7',             'x_7',              'Separator';
        'Mean_Y_L',        'Mean_Y_L',         'Mean Y Left';
        'SD_Y_L',          'SD_Y_L',           'Standard Deviation Y Left';
        'x_8',             'x_8',              'Separator';
        'Mean_X_R',        'Mean_X_R',         'Mean X Right';
        'SD_X_R',          'SD_X_R',           'Standard Deviation X Right';
        'x_9',             'x_9',              'Separator';
        'Mean_Y_R',        'Mean_Y_R',         'Mean Y Right';
        'SD_Y_R',          'SD_Y_R',           'Standard Deviation Y Right'
    };

    ctrl_names = {'045', '058', '081', '130'};

    if exist(output_file, 'file')
        delete(output_file);
    end

    fprintf('Normalizing control data...\n');
    fprintf('  Slope:     %.9f\n', slope);
    fprintf('  Intercept: %.9f\n', intercept);
    fprintf('  Far L:     %.5f\n', far_L);
    fprintf('  Far R:     %.5f\n\n', far_R);

    for ci = 1:length(ctrl_names)
        sheet_name = sprintf('Control_%s', ctrl_names{ci});
        
        fprintf('Processing %s...\n', sheet_name);
        
        % Read data from extracted file with preserved variable names
        try
            data = readtable(input_file, 'Sheet', sheet_name, ...
                              'VariableNamingRule', 'preserve');
        catch ME
            warning('Could not read sheet %s: %s', sheet_name, ME.message);
            continue;
        end
        
        % Apply column mappings
        data = apply_column_mappings(data, column_mappings);
        
        % Add normalization parameter columns
        n = height(data);
        data = addvars(data, ...
                       repmat(slope,      n, 1), ...
                       repmat(intercept,  n, 1), ...
                       repmat(far_L,      n, 1), ...
                       repmat(far_R,      n, 1), ...
                       'NewVariableNames', {'Slope', 'Intercept', ...
                                            'Far_Before_Median_L', ...
                                            'Far_Before_Median_R'});
        
        % Apply normalization
        normalized = compute_normalization(data, slope, intercept, far_L, far_R);
        
        % Write to output file
        writetable(data,      output_file, 'Sheet', sheet_name);
        writetable(normalized, output_file, 'Sheet', [sheet_name, '_Normalized']);
        
        fprintf('  %s -> %d rows normalized\n\n', sheet_name, height(normalized));
    end

    fprintf('DONE: %s\n', output_file);
end

function data = apply_column_mappings(data, column_mappings)
%APPLY_COLUMN_MAPPINGS  Rename columns based on mapping table.

    current_cols = data.Properties.VariableNames;
    
    for i = 1:size(column_mappings, 1)
        source_title = column_mappings{i, 1};
        target_title = column_mappings{i, 2};
        description  = column_mappings{i, 3};
        
        % Find matching column
        col_idx = find_column_by_title(current_cols, source_title);
        
        if col_idx > 0
            old_name = current_cols{col_idx};
            new_name = target_title;
            data.Properties.VariableNames{col_idx} = new_name;
            fprintf('  Mapped: %s -> %s (%s)\n', old_name, new_name, description);
        else
            fprintf('  Warning: Column "%s" not found\n', source_title);
        end
    end
end

function col_idx = find_column_by_title(current_cols, title)
%FIND_COLUMN_BY_TITLE  Find column index by title (case-insensitive).

    col_idx = 0;
    title_lower = lower(strtrim(title));
    
    for i = 1:length(current_cols)
        if strcmp(lower(current_cols{i}), title_lower)
            col_idx = i;
            return;
        end
    end
end

function normalized = compute_normalization(data, slope, intercept, far_L, far_R)
%COMPUTE_NORMALIZATION  Normalize position and spread columns.

    % Define column name patterns for normalization
    pos_L_pattern  = {'Mean_L', 'Med_L', 'Q1_L', 'Q3_L'};
    pos_R_pattern  = {'Mean_R', 'Med_R', 'Q1_R', 'Q3_R'};
    spread_pattern = {'IQR_L', 'IQR_R'};

    normalized = data;
    all_cols = data.Properties.VariableNames;

    for c = 1:length(all_cols)
        col = all_cols{c};

        % Check if column matches Left position pattern
        if any(strcmp(col, pos_L_pattern))
            normalized.(col) = (data.(col) - far_L) / slope;
            fprintf('    Normalized (Left): %s\n', col);

        % Check if column matches Right position pattern
        elseif any(strcmp(col, pos_R_pattern))
            normalized.(col) = (data.(col) - far_R) / slope;
            fprintf('    Normalized (Right): %s\n', col);

        % Check if column matches spread pattern
        elseif any(strcmp(col, spread_pattern))
            normalized.(col) = data.(col) / slope;
            fprintf('    Normalized (Spread): %s\n', col);
        end
    end
end