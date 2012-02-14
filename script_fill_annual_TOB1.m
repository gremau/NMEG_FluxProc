tob1_dir = fullfile( get_out_directory(), 'TOB1_mat' );
files = list_files( tob1_dir, '.*\.mat');

for i = 1:numel( files )
    
    fprintf( 1, 'loading %s\n', files{ i } );
    
    load( files{ i } );
    
    year = regexp( files{ i }, '20(09|10|11)', 'match', 'once' );
    year = str2num( year );

    timestamp = dataset( { datenum( double( whole_year( :, 1:6 ) ) ), ...
                        'timestamp' } );
    
    whole_year = [ timestamp, whole_year ];
    whole_year = dataset_fill_timestamps( whole_year, 'timestamp', ...
                                          ( 1 / 48 ), ...
                                          datenum( year, 1, 1 ), ...
                                          datenum( year + 1, 1, 1 ) );
    
    disp( 'exporting dataset' );
    export( whole_year, 'file', strrep( files{ i }, '.mat', '_filled.txt' ) );
    disp( 'writing .mat file' );
    save( strrep( files{ i }, '.mat', '_filled.mat' ), 'whole_year' );
end
    
                                         