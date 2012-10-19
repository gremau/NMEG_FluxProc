function ds = combine_and_fill_TOA5_files( varargin )
% combine_and_fill_TOA5_files() --
% prompts user to select a group of TOA5 files, combines them into one matlab
% dataset and fills in any missing 30-minute time stamps.  Returns the filled
% TOA5 data as a matlab datset.
%
% Timothy W. Hilton, UNM, Dec 2011

if nargin == 0
    % no files specified; prompt user to select files
    
    [filename, pathname, filterindex] = uigetfile( ...
        { 'TOA5*.dat','TOA5 files (TOA5*.dat)' }, ...
        'select files to merge', ...
        fullfile( 'C:', 'Research_Flux_Towers', ...
                  'Flux_Tower_Data_by_Site' ), ...
        'MultiSelect', 'on' );
else
    % the arguments are file names (with full paths)
    args = [ varargin{ : } ];
    [ pathname, filename, ext ] = cellfun( @fileparts, ...
                                           args, ...
                                           'UniformOutput', false );
    filename = strcat( filename, ext );
end
    
nfiles = length( filename );
ds_array = cell( nfiles, 1 );

for i = 1:nfiles
    fprintf( 1, 'reading %s\n', filename{ i } );
    
    if numel( pathname ) == 1 
        this_path = pathname;
    else
        this_path = pathname{ i };
    end
    
    ds_array{ i } = toa5_2_dataset( fullfile( this_path, filename{ i } ) );
end

% combine ds_array to single dataset
ds = vertcat( ds_array{ : } );

fprintf( 1, 'filling missing timestamps\n' );
thirty_mins = 1 / 48;  %thirty minutes expressed in units of days
ds = dataset_fill_timestamps( ds, ...
                              'timestamp', ... 
                              't_min', min( ds.timestamp ), ...
                              't_max', max( ds.timestamp ) );%datenum( 2012, 6, 1 ) );

% remove duplicated timestamps (e.g., in TX 2010)
fprintf( 1, 'removing duplicate timestamps\n' );
ts = datenum( ds.timestamp( : ) );
one_minute = 1 / ( 60 * 24 ); %one minute expressed in units of days
non_dup_idx = find( diff( ts ) > one_minute );
ds = ds( non_dup_idx, : );


% to save to file, use e.g.:
fprintf( 1, 'saving csv file\n' );
idx = min( find( datenum(ds.timestamp(:))>= datenum( 2012, 1, 1)));
ds.timestamp = datestr( ds.timestamp, 'mm/dd/yyyy HH:MM:SS' );
export(ds( idx:end, : ), 'FILE', ...
       fullfile( get_out_directory(), 'combined_TOA5.csv' ), ...
       'Delimiter', ',');