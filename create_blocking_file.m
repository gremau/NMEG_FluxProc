function blk_file_name = create_blocking_file( varargin )
% CREATE_BLOCKING_FILE - 
        
    p = inputParser();
    p.addOptional( 'user_message', '', @ischar );
    p.parse( varargin{ : } );
    
    t_string = datestr( now(), 'blocking_yyyymmdd_HHMMSS' );
    
    blk_file_name = sprintf( '%s%s.txt', tempname(), t_string );
    fid = fopen( blk_file_name, 'w' );


    fprintf( fid, 'placeholder file to pause Matlab execution\r\n' );
    fprintf( fid, 'created %s\r\n', datestr( now() ) );
    if not( isempty( p.Results.user_message ) )
        fprintf( fid, '%s\r\n', p.Results.user_message );
    end
    
    fclose( fid );
    
    
    
    