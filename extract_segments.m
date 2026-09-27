function extract_segments()
%EXTRACT_SEGMENTS  Pull segment rows (2-5) from each input file's
%   Statistics sheet. Stack into ONE output workbook.
%   Columns A:P (16 columns). Preserves data title (header row).

    input_folder  = 'input/';
    output_folder = 'output/';
    output_file   = fullfile(output_folder, 'segments_extracted.xlsx');

    if ~exist(output_folder, 'dir')
        mkdir(output_folder);
    end

    files = dir(fullfile(input_folder, '*.xlsx'));
    files = files(~startsWith({files.name}, '~$'));

    if isempty(files)
        error('No .xlsx files found in %s', input_folder);
    end

    fprintf('Found %d file(s)\n\n', numel(files));

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

    for s = 1:4
        if isempty(seg_buckets{s}), continue; end
        out = cell2table(seg_buckets{s}, 'VariableNames', hdr);
        writetable(out, output_file, 'Sheet', sprintf('Segment_%d', s));
        fprintf('  Segment_%d -> %d rows\n', s, height(out));
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