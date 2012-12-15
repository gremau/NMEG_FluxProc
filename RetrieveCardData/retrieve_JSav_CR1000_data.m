function [ dest_dir, mod_date ] = retrieve_JSav_CR1000_data( varargin )
% RETRIEVE_JSAV_CR1000_DATA - copy JSav soil water content raw data from card
% to local disk
%   

% -----
% define optional inputs, with defaults and typechecking
% -----
args = inputParser;
args.addParamValue( 'raw_data_dir', '', @ischar );
args.addParamValue( 'dryrun', false, @islogical );
args.parse( varargin{ : } );
raw_data_dir = args.Results.raw_data_dir;
% -----

if isempty( raw_data_dir );
    raw_data_dir = uigetdir( 'G:\', 'select data file directory' );
end

tower_files = dir( fullfile( raw_data_dir, '*.dat' ) );

if isempty( tower_files )
    msg = sprintf( 'no data files found in %s', data_location );
    error( msg );
end
if numel( tower_files ) > 1
    msg = sprintf( 'multiple data files found in %s', data_location );
    error( msg );
end

% get modification date of file
mod_date = datenum( tower_files(1).date );

% create a time-stamped directory for the data file
src = fullfile( raw_data_dir, tower_files( 1 ).name );
dest_dir = get_local_raw_data_dir( UNM_sites.JSav, mod_date );
dest_dir = regexprep( dest_dir, 'JSav-', 'JSav_soil-' );

if exist(dest_dir) ~= 7
    [mkdir_success, msg, msgid] = mkdir( dest_dir );
    if mkdir_success
        sprintf('created %s', dest_dir);
    else
        error(msgid, msg);
    end
end

fprintf('%s --> %s...', src, dest_dir);
if not( args.Results.dryrun )
    [copy_success, msgid, msg] = copyfile(src, dest_dir);
    if copy_success
        fprintf('done\n');
    else
        fprintf('\n');
        error(msgid, msg);
    end
end