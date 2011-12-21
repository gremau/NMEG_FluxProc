function ds = concat_toa_files(site, write_combined)
% CONCAT_TOA_FILES - concat_toa_files(site, write_combined)
%   
% site: string, the site to process (used in output file name)
% write_combined: boolean; if true, writes combined data to disk as ASCII
%                 file
%
% Timothy W. Hilton, UNM, Nov 2011

    [fnames, dirpath] = uigetfile( fullfile( 'C:', ...
                                            'Research - Flux Towers', ...
                                            'Flux Tower Data by Site', ...
                                            '*.dat' ), ...
                                   'MultiSelect', 'On' );
    
    fnames = cellfun( @fullfile, ...
                      cellstr( repmat( dirpath, length( fnames ), 1 ) ), ...
                      fnames(:), ...
                      'UniformOutput', false );
    
    ds_array = cell( length( fnames ), 1 );
    cmd = 'bigds = vertcat( ';
    for i = 1:length(fnames)
        ds_array{i} = toa5_2_dataset( fnames{ i } );
        cmd = [ cmd, sprintf( ' ds_array{ %d }', i ) ];
        if i < length( fnames )
            cmd = [ cmd, ',' ];
        end
    end
    cmd = [cmd, ' );'];

    eval(cmd);
    clear('ds_array');

    ds = dataset_fill_timestamps(bigds, 'TIMESTAMP', ( 1 / 48 ) );

    if write_combined
        outfname =  fullfile( tempdir(), ...
                              sprintf( '%s_filled_ds.dat', site ) );
        fprintf( 'writing filled dataset\n' );
        export(ds, 'File', outfname ); 
        fprintf( 'wrote %s\n', outfname );   
    end
    
    
