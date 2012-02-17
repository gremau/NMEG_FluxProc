% process the 10-hz data to 30-minute averages for the Oct/Nov/Dec 2011 data
% obtained from Skyler on 14 Feb 2012   -TWH

function result = process_missing_script( )

    rotation = 1;
    lag = 0;

    ds = process_TOB1_chunk( 3, datenum( 2011, 11, 2 ), datenum( 2011, 11, 19 ), ...
                             lag, rotation );
    postprocess_and_write_file( ds, 3 );

    ds = process_TOB1_chunk( 6, datenum( 2011, 10, 12 ), datenum( 2011, 11, 17 ), ...
                             lag, rotation );
    postprocess_and_write_file( ds, 6 );

    ds = process_TOB1_chunk( 11, datenum( 2011, 10, 30 ), datenum( 2011, 11, 18 ), ...
                             lag, rotation );
    postprocess_and_write_file( ds, 11 );

    ds = process_TOB1_chunk( 4, datenum( 2011, 11, 1 ), datenum( 2011, 12, 02 ), ...
                             lag, rotation );
    postprocess_and_write_file( ds, 4 );

    ds = process_TOB1_chunk( 10, datenum( 2011, 11, 1 ), datenum( 2011, 12, 02 ), ...
                             lag, rotation );
    postprocess_and_write_file( ds, 10 );

    ds = process_TOB1_chunk( 5, datenum( 2011, 10, 12 ), datenum( 2011, 11, 17 ), ...
                             lag, rotation );
    postprocess_and_write_file( ds, 5 );

    result = 1;


function result = postprocess_and_write_file( ds, sitecode )

    outfile = fullfile( get_out_directory( sitecode ), ...
                        'TOB1_data', ...
                        sprintf( '%s_TOB1_missing.mat', ...
                                 get_site_name( sitecode ) ) );

    save( outfile, 'ds' );

    %fprintf( 1, 'done (%d seconds)\n', int32( ( now() - t0 ) * 86400 ) );

    result = 1;

    fprintf('\tany valid Ustar: %d\n', ...
            any( not( isnan( ds.ustar ) ) ) );
    
    %year = regexp( outfile, '20(09|10|11)', 'match', 'once' );
    %year = str2num( year );
    year = 2011;

    % I got the timestamp off by 30 mins -- shift the data one row against
    % the timestamps
    ds = [ ds( 2:end, 1:6 ), ...
                   ds( 1:end-1, 7:end ) ];

    timestamp = dataset( { datenum( double( ds( :, 1:6 ) ) ), ...
                        'timestamp' } );
    
    ds = [ timestamp, ds ];
    ds = dataset_fill_timestamps( ds, 'timestamp', ...
                                          ( 1 / 48 ), ...
                                          datenum( year, 1, 1, 0, 30, 0 ), ...
                                          datenum( year + 1, 1, 1 ) );

    dn = datenum( ds.timestamp, 'mm/dd/yyyy HH:MM:SS' );
    [ y, mon, d, h, m, s ] = datevec( dn );
    ds.year = y;
    ds.month = mon;
    ds.day = d;
    ds.hour = h;
    ds.min = m;
    ds.second = s;
    ds.date = datestr( dn, 'mmddyy' );
    ds.jday = dn - datenum( year, 1, 1 ) + 1;
    
    % format to match existing FLUX_all_YYYY.xls files
    % for some reason, two time columns
    timestamp2 = ds.timestamp;
    timestamp2 = dataset( timestamp2) ;
    ds = [ timestamp2, ds ];
    % only one iok column
    if size( ds.iok, 2 ) > 1
        ds.iok = ds.iok( :, 2 );
    end
    
    disp( 'exporting dataset' );
    export( ds, ...
            'file', strrep( outfile, '.mat', '_filled.txt' ) );
    disp( 'writing .mat file' );
    save( strrep( outfile, '.mat', '_filled.mat' ), 'ds' );

    return
    %--------------------------------------------------

