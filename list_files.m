function list = list_files( path, pat )
% LIST_FILES - list files in a directory, with regular expression filtering
% list = list_files( path, pat )
% INPUTS
%    path: full path of the directory to be listed
%    pat: regular expression to match files against; only matching files are
%         returned
% OUTPUTS
%    list: cell array of matching files
    

    if exist( path ) ~= 7
        error('list_files:dir_not_found',...
              'the requested directory does not exist');
    else
        fnames = dir( path );
    end
    
    fnames = { fnames.name };
    list = regexp( fnames, pat, 'match', 'once' );
    idx = cellfun( @isempty, list );
    list( idx ) = [];
    
    % append full path to beginning of file names
    list = cellfun( @(x) fullfile( path, x ), list, ...
                    'UniformOutput', false )
        
        
    
    