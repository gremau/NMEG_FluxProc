function main_success = process_card_main( this_site, varargin )
% PROCESS_CARD_MAIN - main function for retrieving flux tower data from a flash
%   card:
%    * Copies the raw data from the card to the appropriate 'Raw data from
%      cards' directory
%    * converts 30-minute data to a TOA5 file
%    * converts 10 hz data to TOB1 files
%    * copies the uncompressed TOB1 files to MyBook USB hard drive
%    * copies uncompressed raw data to Story USB hard drive
%    * compresses the raw data on the internal hard drive
%    * FTPs the compressed raw data to EDAC
%
% USAGE: 
%    process_card_main( this_site )
%    process_card_main( this_site, 'card' )
%    process_card_miain( this_site, 'disk', 'data_location', 'C:\path\to\data' );
%
% INPUTS:
%   this_site: UNM_sites object or integer code; the site being processed
%   data_location: string; Optional keyword argument specifying the location of
%       the raw data to be processed. Legal values are 'card' and 'disk'; the
%       default is 'card'.
%   data_path: string; the path to the directory containing the raw card data
%       on disk.  Must be specified if data_location is 'disk'.  Ignored if
%       data_location is 'card'.
%
% SEE ALSO:
%    process_card_partial: designed to pick up processing part way through the
%    pipeline, requiring some by-hand intervention in the code to setup how far
%    through the pipeline to pickup.  This can be useful if, for example, there
%    is a garbled file on a card so that process_card_main crashes, or if the
%    network connection dies so that FTP transfer does not complete.
%
% Timothy W. Hilton, UNM, Dec 2011

% -----
% define optional inputs, with defaults and typechecking
% -----
args = inputParser;
args.addRequired( 'this_site', @(x) ( isintval( x ) | isa( x, 'UNM_sites' ) ) );
args.addOptional( 'data_location', 'card', @ischar );
args.addParamValue( 'data_path', '', @ischar );

% parse optional inputs
args.parse( this_site, varargin{ : } );

this_site = args.Results.this_site;

%--------------------------------------------------------------------------
site_dir = get_site_directory( this_site );

% copy the data from the card to the computer's hard drive
fprintf(1, '\n----------\n');
fprintf(1, 'COPYING FROM CARD TO LOCAL DISK...\n');
data_location = args.Results.data_location;
if not( strcmp( data_location, 'card' ) )
    data_location = args.Results.data_path;
end
[card_copy_success, raw_data_dir, mod_date] = ...
    retrieve_tower_data_from_card( this_site, data_location );

% convert the thirty-minute data to TOA5 file
fprintf(1, '\n----------\n');
fprintf(1, 'CONVERTING THIRTY-MINUTE DATA TO TOA5 FORMAT...\n');
[fluxdata_convert_success, toa5_fname] = thirty_min_2_TOA5(this_site, ...
                                                  raw_data_dir);
fprintf(1, ' Done\n');

%make diagnostic plots of the raw flux data from the card
fluxraw = toa5_2_dataset(toa5_fname);
% save( 'fluxraw_viewer_restart.mat' );  main_success = 1;
% return
h_viewer = fluxraw_dataset_viewer(fluxraw, this_site, mod_date);
waitfor( h_viewer );
clear('fluxraw');

%convert the time series (10 hz) data to TOB1 files
fprintf(1, '\n----------\n');
fprintf(1, 'CONVERTING TIME SERIES DATA TO TOB1 FILES...');
[tsdata_convert_success, ts_data_fnames] = ...
    tsdata_2_TOB1(this_site, raw_data_dir);
fprintf(1, ' Done\n');

%copy uncompressed TOB1 data to MyBook
fprintf(1, '\n----------\n');
fprintf(1, 'COPYING UNCOMPRESSED TOB1 DATA TO MYBOOK...\n');
copy_uncompressed_TOB_files(this_site, ts_data_fnames);
fprintf(1, 'Done copying uncompressed TOB1 data to mybook\n');

%copy uncompressed raw data to Story
fprintf(1, '\n----------\n');
fprintf(1, 'COPYING UNCOMPRESSED RAW CARD DATA TO STORY...\n');
copy_uncompressed_raw_card_data(this_site, raw_data_dir);
fprintf(1, 'Done copying uncompressed TOB1 data to mybook\n');

%compress the raw data on the local drive
fprintf(1, '\n----------\n');
fprintf(1, 'COMPRESSING RAW DATA ON INTERNAL DRIVE...\n');
compress_raw_data_directory(raw_data_dir);
fprintf(1, 'Done compressing\n');

% transfer the compressed raw data to edac
fprintf(1, '\n----------\n');
fprintf(1, 'transfering compressed raw data to edac...\n');
h = msgbox( 'click to begin FTP transfer', '' );
waitfor( h );
transfer_2_edac(this_site, sprintf('%s.7z', raw_data_dir))
fprintf(1, 'Done transferring.\n');

save( 'card_restart_01.mat' );

% --------------------------------------------------
% the data are now copied from the card and backed up.

% merge the new data into the fluxall file
fprintf(1, '\n----------\n');
fprintf(1, 'merging new data into FLUXALL file...\n');
dates = cellfun( @get_TOA5_TOB1_file_date, ts_data_fnames );
cdp = card_data_processor( UNM_sites( this_site ), ...
                           'date_start', min( dates ), ...
                           'date_end', max( dates ) + 1 );
cdp.update_fluxall();

% run RemoveBadData to create for gapfilling file, qc file.  
fprintf(1, '\n----------\n');
fprintf(1, 'starting UNM_RemoveBadData...\n');
[ year, ~, ~, ~, ~, ~ ] = datevec( min( dates ) );
UNM_RemoveBadData( UNM_sites( this_site ), year, 'draw_plots', false );

% compare sunrise as measured by observed solar radiation to runrise as
% calculated by solar angle
fprintf(1, '\n----------\n');
fprintf(1, 'make sure timestamps rise the sun at the correct time...\n');
UNM_site_plot_fullyear_time_offsets( UNM_sites( this_site ), year );

% fill missing temperature, PAR, relative humidity from nearby sites if
% available.
fprintf(1, '\n----------\n');
fprintf(1, ['attempting to fill missing temperature, PAR, relative humidity ' ...
            'from nearby sites...\n'] );
UNM_fill_met_gaps_from_nearby_site( UNM_sites( this_site ), 2012 );

% run RemoveBadData again to check visually that the filters did OK
fprintf(1, '\n----------\n');
fprintf(1, 'starting UNM_RemoveBadData...\n');
[ year, ~, ~, ~, ~, ~ ] = datevec( min( dates ) );
UNM_RemoveBadData( UNM_sites( this_site ), year, 'draw_plots', true );

