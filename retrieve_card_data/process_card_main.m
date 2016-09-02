function main_success = process_card_main( this_site, logger_name, varargin )
% PROCESS_CARD_MAIN - main function for retrieving flux tower data from a
% datalogger flash card.
%
% Tasks performed:
%    * Copies the raw data from the card to the appropriate 'raw_card_data'
%      directory
%    * converts 30-minute data to a TOA5 file
%    * converts 10 hz data to TOB1 files
%    * compresses the raw card data on the internal hard drive
%    * ???copies the uncompressed TOB1 files to MyBook USB hard drive
%    * copies compressed raw card data to Story USB hard drive
%    * FTPs the compressed raw data to EDAC
%    * calculates 30-minute averages of 10-hz eddy covariance data
%    * inserts the data into the appropriate annual FLUXALL file.
%
% DATALOGGER FILE REQUIREMENTS: 
% process_card_main expects to find exactly one thirty-min data file and
% one or more 10-hz data files in the specified card data directory.
% The thirty-minute data file must be named *.flux.dat and the 10 hz data
% files must be named *.ts_data*.dat.  If these requirements are not met
% preocess_card_main will not be able to find the datalogger data.  If a
% LoggerNet "repair" operation is needed the unrepaired datalogger files
% should be moved to a different directory (may be a subdirectory within
% the data directory), and repaired file names must satisfy the above
% format requirements.
%
% USAGE: 
%    process_card_main( this_site )
%    process_card_main( this_site, 'card' )
%    process_card_main( this_site, ..., 'interactive', is_interactive )
%    process_card_main( this_site, 'disk', 'data_path', 'C:\path\to\data' );
%
% INPUTS:
%   this_site: UNM_sites object or integer code; the site being processed
%   logger_name: The name of the datalogger card data is being processed
%       for. 
%
% PARAMETER-VALUE PAIRS
%   data_location: string; Optional keyword argument specifying the location of
%       the raw data to be processed. Legal values are 'card' and 'disk'; the
%       default is 'card'.
%   data_path: string; the path to the directory containing the raw card data
%       on disk.  Must be specified if data_location is 'disk'.  Ignored if
%       data_location is 'card'.
%   interactive: optional parameter, logical value.  If true, thirty-minute
%       data is presented for visual inspection and the processor waits for the
%       user to close the window before proceeding.  If false, this step is
%       skipped (useful for non-interactive processing).  Default is true.
%
% SEE ALSO:
%    process_card_partial: designed to pick up processing partway through the
%    pipeline, requiring some by-hand intervention in the code to setup how far
%    through the pipeline to pickup.  This can be useful if, for example, there
%    is a garbled file on a card so that process_card_main crashes, or if the
%    network connection dies so that FTP transfer does not complete.
%
% Timothy W. Hilton, UNM, 2011-2013
% Rewritten by Gregory E. Maurer, UNM, March 2016

% -----
% define optional inputs, with defaults and typechecking
% -----
args = inputParser;
args.addRequired( 'this_site', @(x) ( isintval( x ) | isa( x, 'UNM_sites' ) ) );
args.addRequired( 'logger_name', @ischar );
args.addParameter( 'data_location', 'card', @ischar );
args.addParameter( 'data_path', '', @ischar );
args.addParameter( 'interactive', true, @islogical );

% parse optional inputs
args.parse( this_site, logger_name, varargin{ : } );
this_site = args.Results.this_site;
logger_name = args.Results.logger_name;

% get data location
switch args.Results.data_location;
    case 'card'
        % the data are on a flash card
        % FIXME - need a more flexible way to determine the drive letter.
        % locate_drive( 'Removable Disk' ) doesn't work for card reader.
        data_location = 'g:\';
    otherwise
        data_location = args.Results.data_path;
end

%--------------------------------------------------------------------------
% open a log file
fname_log = fullfile( getenv( 'FLUXROOT' ), 'Logs',...
                      'Card_Processing_Logs', ...
                      sprintf( '%s_%s_card_process.log', ...
                               datestr(now(), 'yyyy-mm-dd_HHMM' ), ...
                               char( UNM_sites( this_site ) ) ) );
fprintf( 'logging session to %s\n', fname_log );
diary( fname_log );

%--------------------------------------------------------------------------
% VALIDATE the card data directory and files

% Get data files
fprintf( 'validating files in %s\n', data_location );
card_files = dir( fullfile( data_location, '*.dat' ) );

% Error if data_loc is empty
if isempty( card_files )
    msg = sprintf( 'no data files found in %s', data_location );
    error( msg );
end

% Get modification dates
mod_date_arr = datenum({card_files.date});
% Check that mod date is not in future
if any( mod_date_arr > now() )
    error( 'Raw data has modification date in the future' );
end

% Issue a warning if the raw data files have different modification dates,
% This should normally be the case at some sites
if any( diff( mod_date_arr ) > 1e-4 )
    warning( sprintf( [ 'Raw data files have different modification dates.\n'...
        '         Using %s (the most recent).\n' ], ...
        datestr( max( mod_date_arr ) ) ) );
    last_mod_date = max( mod_date_arr );
    first_mod_date = min( mod_date_arr );
else
    last_mod_date = max( mod_date_arr );
    first_mod_date = last_mod_date - 31;
end

% Get the datalogger configuration for site
conf = parse_yaml_config( this_site, 'Dataloggers', ...
    [ first_mod_date, last_mod_date ] );

% Check for specified datalogger and extract its configuration
[dl_present, dl_idx] = ismember( logger_name, { conf.dataloggers.name });
if ~dl_present
    error( sprintf(['Datalogger not configured. ',...
        'Check Dataloggers.yaml for %s site\n'], char(this_site)));
else
    dl_conf = conf.dataloggers(dl_idx) ;
end

% Make sure datalogger ID in configuration matches that in the filenames
fname_tokens = cellfun( @(x) strsplit( x, '.' ), {card_files.name}, ...
    'UniformOutput', false );
first_tokens = cellfun( @(x) x{1}, fname_tokens, 'UniformOutput', false );
first_tokens = unique( first_tokens );

if length( first_tokens )==1 && strcmp( first_tokens, num2str(dl_conf.ID))
    fprintf( 'Card file IDs (%s) match configured datalogger.\n', ...
        first_tokens{1} )
else
    error( 'Configured datalogger ID and card filenames do not match!' );
end


%--------------------------------------------------------------------------
% copy the data from the card to the computer's hard drive
try    
    fprintf(1, '\n----------\n');
    fprintf(1, 'COPYING FROM CARD TO LOCAL DISK...\n');
    [card_copy_success, raw_data_dir] = retrieve_card_data_from_loc( ...
        this_site, logger_name, data_location, last_mod_date );
catch err
    % echo the error message
    fprintf( 'Error copying raw data from card to local drive.' )
    disp( getReport( err ) );
    main_success = 0;
    % if copying the data was unsuccessful there is nothing to do, so return
    diary off
    return
end

% If this is a flux datalogger card convert the data
if strcmp( logger_name, 'flux' )
    % convert the thirty-minute data to TOA5 file
    try
        fprintf(1, '\n----------\n');
        fprintf(1, 'CONVERTING THIRTY-MINUTE DATA TO TOA5 FORMAT...\n');
        [fluxdata_convert_success, toa5_fname] = thirty_min_2_TOA5(...
            this_site, raw_data_dir);
        fprintf(1, ' Done\n');
    catch err
        fluxdata_convert_success = false;
        % echo the error message
        fprintf( 'Error converting 30-minute data to TOA5 file.' )
        disp( getReport( err ) );
        main_success = 0;
    end
    
    %make diagnostic plots of the raw flux data from the card
    if args.Results.interactive
        if fluxdata_convert_success
            fluxraw = toa5_2_table(toa5_fname);
            % save( 'fluxraw_viewer_restart.mat' );  main_success = 1;
            % return
            h_viewer = fluxraw_table_viewer(fluxraw, this_site, ...
                last_mod_date);
            figure( h_viewer );  % bring h_viewer to the front
            waitfor( h_viewer );
            clear('fluxraw');
        else
            fprintf( 'there are no 30-minute data to display\n' );
        end
    end
    
    %convert the time series (10 hz) data to TOB1 files
    try
        fprintf(1, '\n----------\n');
        fprintf(1, 'CONVERTING TIME SERIES DATA TO TOB1 FILES...\n');
        [tsdata_convert_success, ts_data_fnames] = ...
            tsdata_2_TOB1(this_site, raw_data_dir);
        fprintf(1, ' Done\n');
    catch err
        % echo the error report
        fprintf( 'Error converting time series data to TOB1 files.' )
        disp( getReport( err ) );
        main_success = 0;
        if not( main_success )
            % if neither data file was converted successfully, exit
            fprintf( 'stopping logging... ' );
            diary off
            fprintf( 'logging stopped\n' );
            return
        end
    end
end

%copy uncompressed TOB1 data to MyBook
% try 
%     fprintf(1, '\n----------\n');
%     fprintf(1, 'COPYING UNCOMPRESSED TOB1 DATA TO MYBOOK...\n');
%     copy_uncompressed_TOB_files(this_site, ts_data_fnames);
%     fprintf(1, 'Done copying uncompressed TOB1 data to mybook\n');
% catch err
%     % echo the error report
%     fprintf( 'Error copying uncompressed TOB1 data to MyBook\n' );
%     disp( getReport( err ) );
%     fprintf( 'continuing with processing\n' );
% end
% 
% %copy uncompressed raw data to Story
% try
%     fprintf(1, '\n----------\n');
%     fprintf(1, 'COPYING UNCOMPRESSED RAW CARD DATA TO STORY...\n');
%     copy_uncompressed_raw_card_data(this_site, raw_data_dir);
%     fprintf(1, 'Done copying uncompressed card data to Story\n');
% catch err
%     % echo the error report
%     fprintf( 'Error copying uncompressed raw card data to Story\n' );
%     disp( getReport( err ) );
%     fprintf( 'continuing with processing\n' );
% end

%compress the raw data on the local drive
try
    fprintf(1, '\n----------\n');
    fprintf(1, 'COMPRESSING RAW DATA ON INTERNAL DRIVE...\n');
    [~, card_archive_name] = compress_raw_data_directory(raw_data_dir);
    fprintf(1, 'Done compressing\n');
catch err
    % echo the error report
    fprintf( 'Error compressing raw data\n' );
    disp( getReport( err ) );
    fprintf( 'continuing with processing\n' );
end

%copy compressed raw data to Story
try
    fprintf(1, '\n----------\n');
    fprintf(1, 'COPYING COMPRESSED RAW CARD DATA TO STORY...\n');
    copy_compressed_raw_card_data(this_site, card_archive_name);
    fprintf(1, 'Done copying compressed card data to Story\n');
catch err
    % echo the error report
    fprintf( 'Error copying compressed raw card data to Story\n' );
    disp( getReport( err ) );
    fprintf( 'continuing with processing\n' );
end

% transfer the compressed raw data to edac
try
    fprintf(1, '\n----------\n');
    if args.Results.interactive
        fprintf(1, 'TRANSFERING COMPRESSED RAW DATA TO EDAC...\n');
        h = msgbox( 'click to begin FTP transfer', '' );
        waitfor( h );
        transfer_2_edac(this_site, card_archive_name)
        fprintf(1, 'Done transferring.\n');
    else
        fprintf(1, ['Non-interactive -- skipping compressed raw data ' ...
                    'transfer to edac...\n']);
    end
catch err
    % echo the error report
    fprintf( 'Error transfering compressed raw data to edac\n' );
    disp( getReport( err ) );
    fprintf( 'continuing with processing\n' );
end

% This saves the MATLAB environment so that it can be restarted in case
% something bad happens
save( fullfile( getenv( 'FLUXROOT' ), 'FluxOut', 'card_restart_01.mat' ) );

% FIXME - Remove the original folder?
%     if (result == 0)  %indicates compression successful
%         delete(fullfile(raw_data_dir, '*'));
%         rmdir(raw_data_dir);
%         fprintf(1, 'removed %s\n', raw_data_dir);
%     end
% --------------------------------------------------
% the data are now copied from the card and backed up.
%%
% If this is a flux datalogger card process the data
if strcmp( logger_name, 'flux' )
    % merge the new data into the fluxall file
    try
        fprintf(1, '\n----------\n');
        fprintf(1, 'merging new data into FLUXALL file...\n');
        dates = cellfun( @get_TOA5_TOB1_file_date, ts_data_fnames );
        % Note that sometimes a card contains data from 2 years
        % 2 fluxall files need to be made in this case
        datesVec = datevec( dates );
        inclYears = unique( datesVec( :, 1 ) );
        if length( inclYears ) > 1
            start_first = min( dates );
            % FIXME - this date setting might be a problem (30 min shift?)
            end_first = datenum( inclYears( 1 ), 12, 31, 23, 30, 0 );
            start_second = datenum( inclYears( 2 ), 1, 1 );
            end_second = max( dates );
            cdp1 = card_data_processor( UNM_sites( this_site ), ...
                'date_start', start_first, ...
                'date_end', end_first );
            cdp1.update_fluxall();
            cdp2 = card_data_processor( UNM_sites( this_site ), ...
                'date_start', start_second, ...
                'date_end', end_second + 1 );
            cdp2.update_fluxall();
        else
            cdp = card_data_processor( UNM_sites( this_site ), ...
                'date_start', min( dates ), ...
                'date_end', max( dates ) + 1 );
            cdp.update_fluxall();
        end
    catch err
        % echo the error report
        fprintf( 'Error merging the new data into FLUXALL\n' );
        disp( getReport( err ) );
        main_success = 1;
        % if fluxall was not updated successfully, there is nothing else to do.
        diary off
        return
    end   
    % run RemoveBadData to create for gapfilling file, qc file.
    fprintf(1, '\n----------\n');
    fprintf(1, 'starting UNM_RemoveBadData...\n');
    [ year, ~, ~, ~, ~, ~ ] = datevec( min( dates ) );
    UNM_RemoveBadData( UNM_sites( this_site ), year, ...
        'draw_plots', double( args.Results.interactive ) );
    
    % fill missing temperature, PAR, relative humidity from nearby sites if
    % available.
    fprintf(1, '\n----------\n');
    fprintf(1, ['attempting to fill missing temperature, PAR, relative humidity ' ...
        'from nearby sites...\n'] );
    UNM_fill_met_gaps_from_nearby_site( UNM_sites( this_site ), year );
    
    % run RemoveBadData again to check visually that the filters did OK
    fprintf(1, '\n----------\n');
    fprintf(1, 'starting UNM_RemoveBadData...\n');
    [ year, ~, ~, ~, ~, ~ ] = datevec( min( dates ) );
    UNM_RemoveBadData( UNM_sites( this_site ), year, 'draw_plots', 3 );

% End flux card data processing
end

% close the log file
diary off