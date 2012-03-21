% function get_unique_TOB1_var_names = get_unique_TOB1_var_names( )
    
%     infile = fopen( 'scratch.m', 'r' );
%     fnames = textscan( infile, '%s', Inf );
%     keyboard


function var_names = read_TOB1_headers( fname )
% READ_TOB1_FILE - reads data from a campbell scientific table-oriented binary
% file  ( TOB1 ), returns the data in a matlab dataset.
% written by Timothy
% W. Hilton, October 2011, based on existing code modified by Krista
% Anderson-Teixeira in January 2008
    
    fid=fopen( fname,'r','ieee-le' ); % file ID
    if fid == -1
        err = MException( 'UNM_data_processor', ...
                         'cannot open file %s\n', fname );
        throw( err );
    end

    % ----  process TOB1 file header ----
    
    headerlines = cell( 5,1 );
    for i=1:5
        this_line = fgetl( fid );
        headerlines{ i } = strrep( this_line, '"', '' );
    end
    
    % split header lines into tokens delimited by commas
    var_names = regexp( headerlines{ 2 }, ',', 'split' );
    var_units = regexp( headerlines{ 3 }, ',', 'split' );
    var_types = regexp( headerlines{ 5 }, ',', 'split' );

    
