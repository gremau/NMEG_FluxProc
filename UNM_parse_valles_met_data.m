function metTable = UNM_parse_valles_met_data( station_name, year_arg )
% Parse ancillary Valles Caldera met data files to matlab table
%
% See the README.md file in the $FLUXROOT/Ancillary_met_data/ directory for
% details on the files and their origin and formatting.
%
% The script issues an error if these files are not found.
%
% USAGE
%     metData = UNM_parse_valles_met_data( sitecode, year_arg );
%
% INPUTS
%     station_name: string; met station to retrieve data from (Redondo,
%         Headquarters, or Jemez)
%     year_arg: numeric; the year to parse
%
% OUTPUTS:
%     metTable: table array; the met data
%
% SEE ALSO
%     table
%
% author: Gregory E. Maurer, UNM, December 2014
% adapted from code by: Timothy W. Hilton, UNM, March 2012

% Choose network and get data
path = fullfile(getenv('FLUXROOT'), 'Ancillary_met_data');
fname_re = [ sprintf( 'VC_%s', station_name ), '_dri_.*\.dat'];
file_list = list_files( path, fname_re );

for i = 1:length( file_list )
    fprintf( 'Opening file: %s ...\n', file_list{i} );
    t = openVC( file_list{i} );
    % Check measurement frequency
    ndays = t.timestamp(end) - t.timestamp(1);
    measfreq = size(t, 1)/ndays;
    if abs( measfreq - 24 ) <= 0.1
        % hourly data - OK
        fprintf( 'Data in hourly frequency, OK ...\n' );
    elseif abs( measfreq - 144 ) <= 1.5
        % 10 minute frequency needs to be converted. Take hourly means of
        % all variables except Precip, which should be summed. Create a new
        % table from these hourly values.
        fprintf( 'Data in 10 min frequency, converting ...\n' );
        tvec = datevec( t.timestamp );
        mean_var_idx = ~ismember(t.Properties.VariableNames, ...
            {'Precip', 'timestamp', 'YYMMDDhhmm'} );
        mean_vars = t.Properties.VariableNames( mean_var_idx );
        [h_tvec, h_means] = consolidator( tvec( :, 1:4 ), ...
            table2array( t( :, mean_vars )), @nanmean );
        % Get precip
        [~, hsum_p] = consolidator( tvec( :, 1:4 ), ...
            table2array( t( :, {'Precip'} )), @nansum );
        % Reassemble into a table
        h_tvec(:,5:6) = 0;
        t = array2table( h_means, 'VariableNames', mean_vars );
        t.Precip = hsum_p;
        t.timestamp = datenum( h_tvec );
    else
        error( 'Observation frequency incorrect.' );
    end
    % Keep only variables consistently present and then concanenate
    keep_vars = {'timestamp', 'AvAirTemp', 'RelHumidty', 'SolarRad', ...
        'Precip', 'WindSpeed', 'WindDirec'};
    t = t( :, keep_vars );
    if i == 1
        metTable = t;
    else
        metTable = vertcat( metTable, t );
    end
end

% Trim to year
tvec = datevec( metTable.timestamp );
metTable = metTable( tvec( :, 1 ) == year_arg, : );

% Jemez station has accum. Precip - convert it
if strcmp( station_name, 'Jemez' )
    % Convert cumulative precip to hourly increments in mm
    p_diff = [ 0; diff( metTable.Precip )];
    %Remove negative increments
    p_diff( p_diff < 0 ) = 0;
    metTable.Precip = p_diff;
end


    function tbl = openVC( fname )
        % Set delimiter and open file
        delim = ',';
        fid = fopen( fname, 'r' );
        % Read header and units
        var_units = fgetl( fid );
        var_units = regexp( var_units, delim, 'split' );
        var_units = cellfun( @char, var_units, 'UniformOutput',  false );
        var_names = fgetl( fid );
        var_names = regexp( var_names, delim, 'split' );
        var_names = cellfun( @char, var_names, 'UniformOutput',  false );
        % Read data to array and replace bad data values
        n_vars = numel( var_names );
        fmt = repmat( '%f', 1, n_vars );
        data = cell2mat( textscan( fid, fmt, 'delimiter', delim ) );
        data =  replace_badvals( data, [ -9999 ], 1e-10 );
        % Close file
        fclose( fid );
        % Create table
        tbl = array2table( data, 'VariableNames', var_names );
        tbl.Properties.VariableUnits =  var_units;
        % Create at timestamp
        dstring = num2str( tbl.YYMMDDhhmm, '%010u' );
        tbl.timestamp = datenum( dstring, 'YYmmDDHHMM' );
