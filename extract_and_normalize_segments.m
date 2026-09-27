function extract_and_normalize_segments()
%EXTRACT_AND_NORMALIZE_SEGMENTS  Pull segment rows (2-5) from each input
%   file's Statistics sheet, then immediately normalize based on column
%   headers. Columns A:P (16 columns).

    input_folder  = 'input/';
    output_folder = 'output/';
    output_file   = fullfile(output_folder, 'segments_normalized.xlsx');

    if ~exist(output_folder, 'dir')
        mkdir(output_folder);
    end

    files = dir(fullfile(input_folder, '*.xlsx'));
    files = files(~startsWith({files.name}, '~$'));

    if isempty(files)
        error('No .xlsx files found in %s', input_folder);
    end

    fprintf('Found %d file(s)\n\n', numel(files));

    % Normalization parameters
    slope      = 0.980155632;
    intercept  = -0.099816481;
    far_L      = 0.00521;
    far_R      = 0.1206;

    seg_buckets = cell(1, 4);
    for i = 1:4
        seg_buckets{i} = {};
    end
    hdr = {};

    for k = 1:numel(files)
        src = fullfile(input_folder, files(k).name);
        fprintf('Reading %d/%d: %s\n', k, numel(files), files(k).name);

        data = readcell(src, 'Sheet', 'Statistics');

        % Restrict to first 16 columns (A:P)
        if size(data, 2) > 16
            data = data(:, 1:16);
        end

        if isempty(hdr)
            raw_hdr = data(1, :);
            for j = 1:length(raw_hdr)
                v = raw_hdr{j};
                while iscell(v) && ~isempty(v)
                    v = v{1};
                end
                if isempty(v) ...
                        || (ischar(v) && isempty(strtrim(v))) ...
                        || (isa(v, 'missing')) ...
                        || (isstring(v) && (isscalar(v) == 0 || isempty(char(v)))) ...
                        || (isnumeric(v) && isscalar(v) && isnan(v)) ...
                        || (islogical(v) && isscalar(v) == 0)
                    raw_hdr{j} = sprintf('Col_%d', j);
                end
            end
            hdr = ['Source_File'; raw_hdr(:)];
        end

        % ----- Segment rows 2-5 -----
        for s = 1:4
            row = s + 1;  % 2, 3, 4, 5
            if size(data, 1) >= row
                row_cells = clean_row(data(row, :));
                seg_buckets{s}(end+1, :) = [{files(k).name}, row_cells];
            end
        end
    end

    if exist(output_file, 'file')
        delete(output_file);
    end

    % Process and normalize each segment bucket
    for s = 1:4
        if isempty(seg_buckets{s}), continue; end
        
        fprintf('\n--- Processing Segment_%d ---\n', s);
        
        % Create table from extracted data
        stats = cell2table(seg_buckets{s}, 'VariableNames', hdr);
        n = height(stats);
        fprintf('  Extracted %d rows\n', n);

        % Add normalization parameter columns
        stats = addvars(stats, ...
                        repmat(slope,      n, 1), ...
                        repmat(intercept,  n, 1), ...
                        repmat(far_L,      n, 1), ...
                        repmat(far_R,      n, 1), ...
                        'NewVariableNames', {'Slope', 'Intercept', ...
                                             'Far_Before_Median_L', ...
                                             'Far_Before_Median_R'});

        % Apply normalization based on column headers
        normalized = compute_normalization(stats, slope, intercept, far_L, far_R);

        % Write to output file
        writetable(stats,      output_file, 'Sheet', sprintf('Segment_%d', s));
        writetable(normalized, output_file, 'Sheet', sprintf('Segment_%d_Normalized', s));
        
        fprintf('  Segment_%d -> %d rows normalized\n', s, height(normalized));
    end

    fprintf('\nDONE: %s\n', output_file);
end

% Helper functions
function row = clean_row(row)
%CLEAN_ROW  Unwrap nested cells in a row of data.
    for j = 1:length(row)
        row{j} = unwrap(row{j});
    end
end

function v = unwrap(v)
%UNWRAP  Unwrap nested cell arrays and convert string to double.
    while iscell(v) && ~isempty(v)
        v = v{1};
    end
    if isstring(v) && isscalar(v)
        v = double(v);
    end
end
