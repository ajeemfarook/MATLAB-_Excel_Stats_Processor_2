function v = unwrap(v)
%UNWRAP  Unwrap nested cell arrays and convert string to double.
    while iscell(v) && ~isempty(v)
        v = v{1};
    end
    if isstring(v) && isscalar(v)
        v = double(v);
    end
end
