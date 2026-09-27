function extract_controls()
%EXTRACT_CONTROLS  Pull control rows (8-11) from each input file's
%   Statistics sheet. Stack into ONE output workbook.
%   Columns A:AK (37 columns). Preserves data title (header row).

    input_folder  = 'input/';
    output_folder = 'output/';
    output_file   = fullfile(output_folder, 'controls_extracted.xlsx');

    if ~exist(output_folder, 'dir')
        mkdir(output_folder);
    end

    files = dir(fullfile(input_folder, '*.xlsx'));
    files = files(~startsWith({files.name}, '~$'));

    if isempty(files)
        error('No .xlsx files found in %s', input_folder);
    end

    fprintf('Found %d file(s)\n\n', numel(files));

    ctrl_buckets = cell(1, 4);
    for i = 1:4
        ctrl_buckets{i} = {};
    end
    hdr = {};

    ctrl_names = {'045', '058', '081', '130'};

    for k = 1:numel(files)
        src = fullfile(input_folder, files(k).name);
        fprintf('Reading %d/%d: %s\n', k, numel(files), files(k).name);

        data = readcell(src, 'Sheet', 'Statistics');

        % Restrict to first 37 columns (A:AK)
        if size(data, 2) > 37
            data = data(:, 1:37);
        end

        if isempty(hdr)
            raw_hdr = data(1, :);
            for j = 1:length(raw_hdr)
                v = raw_hdr{j};
                % Unwrap nested cells
                while iscell(v) && ~isempty(v)
                    v = v{1};
                end
                % Replace empty / missing / blank / numeric with placeholder
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

        % ----- Control rows 8-11 -----
        for ci = 1:4
            row = ci + 7;  % 8, 9, 10, 11
            if size(data, 1) >= row
                row_cells = clean_row(data(row, :));
                ctrl_buckets{ci}(end+1, :) = [{files(k).name}, row_cells];
            end
        end
    end

    if exist(output_file, 'file')
        delete(output_file);
    end

    for ci = 1:length(ctrl_buckets)
        if isempty(ctrl_buckets{ci}), continue; end
        out = cell2table(ctrl_buckets{ci}, 'VariableNames', hdr);
        writetable(out, output_file, 'Sheet', sprintf('Control_%s', ctrl_names{ci}));
        fprintf('  Control_%s -> %d rows\n', ctrl_names{ci}, height(out));
    end

    fprintf('\nDONE: %s\n', output_file);
end

% Helper functions
function row = clean_row(row)
    for j = 1:length(row)
        row{j} = unwrap(row{j});
    end
end

function v = unwrap(v)
    while iscell(v) && ~isempty(v)
        v = v{1};
    end
    if isstring(v) && isscalar(v)
        v = double(v);
    end
end