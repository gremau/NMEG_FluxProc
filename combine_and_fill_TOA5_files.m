function ds = combine_and_fill_TOA5_files()

    [filename, pathname, filterindex] = uigetfile( ...
        { 'TOA5*.dat','TOA5 files (TOA5*.dat)' }, ...
        'select files to merge', ...
        fullfile( 'I:', 'Raw uncompressed data folders', 'TX Data', ...
                  'TX2010', 'ConvertedCardData' ), ...
        'MultiSelect', 'on' );
    
    nfiles = length( filename );
    ds_array = cell( nfiles );
    
    for i in 1:nfiles
        fprintf( 1, 'reading %s\n', filename( i ) );
        ds_array{ i } = toa5_to_dataset( fullfile( pathname, filename ) );
    end
    
    ds = ds_array;
    
    
