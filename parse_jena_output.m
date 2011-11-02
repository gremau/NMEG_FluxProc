function out = parse_jena_output(fname)
% PARSE_JENA_OUTPUT - 
%   

    fid = fopen(fname, 'r+');
    line1 = fgetl(fid);

    % split line1 by consecutive whitespace
    vars = regexp(line1, '\s*', 'split');
    vars = vars(not(cellfun(@isempty, vars)));
    vars = genvarname(vars);  %make sure vars are valid matlab names
    nvars = numel(vars);

    % throw out the second header line (units)
    line2 = fgetl(fid);
    units = regexp(line2, '\s*', 'split');

    fmt = repmat('%f', 1, nvars);
    arr = cell2mat(textscan(fid, fmt, 'CollectOutput', true));

    out = dataset({arr, vars{:}});


    
