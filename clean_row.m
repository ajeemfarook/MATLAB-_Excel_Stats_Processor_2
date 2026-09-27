function row = clean_row(row)
%CLEAN_ROW  Unwrap nested cells in a row of data.
    for j = 1:length(row)
        row{j} = unwrap(row{j});
    end
end