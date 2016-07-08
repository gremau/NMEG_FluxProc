function out = parse_jena_output(fname)
% PARSE_JENA_OUTPUT - parses an output file from the Jena online
% gapfilling/partitioning tool.  
%
% The online tool places some leading whitespace on each data line; this parser
% does not require that whitespace to be removed.  Likewise, this parser does
% not require the second header line of the data file to be removed.
%
% Though it was written for parsing output of the Jena gapfilling/partitioning
% tool, it should in theory work for any whitespace-delimited ASCII data file
% where the first row contains the variable names, the second row contains
% units, and rows three to EOF contain data.
%
% The output is a matlab dataset array.  The dataset may be converted to a
% matrix of doubles using double(out).
%
% Missing values (-9999, -999, etc) are kept.  They may be replace with NaNs
% using replace_badvals.
%
% USAGE
%      out = parse_jena_output(fname);
%
% INPUTS
%     fname: string; full path to the data file to be parsed
% OUTPUTS
%     out: matlab dataset array; the data in the file
%
% SEE ALSO
%     dataset, replace_badvals
%
% author: Timothy W. Hilton, UNM

error('This file is deprecated!');

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

%out = dataset({arr, vars{:}});
out = array2table( arr, 'VariableNames', vars );



