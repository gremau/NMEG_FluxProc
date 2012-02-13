function out = parse_jena_output(fname)
% PARSE_JENA_OUTPUT - parses an output file from the Jena online
% gapfilling/partitioning tool.  The online tool places some leading
% whitespace on each data line; this parser does not require that
% whitespace to be removed.  Likewise, this parser does not require the
% second header line of the data file to be removed.
%
% The output is a matlab dataset object.  The dataset may be converted to
% a matrix of doubles using double(out).
%
% INPUTS
% fname: string; full path to the data file to be parsed
% OUTPUTS
% out: matlab dataset; the data in the file

    fid = fopen(fname, 'r');
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


    
