function cr23xData = get_PJ_cr23x_data( sitecode, year )
% PREPROCESS_PJ_SOIL_DATA - parse CR23X soil data for PJ or PJ_girdle.
%
% FIXME - documentation and cleanup
%
% Creates datasets for soil temperature, soil water content, and soil heat flux
% with complete 30-minute timestamp record and duplicate timestamps removed via
% dataset_fill_timestamps.  When duplicate timestamps are detected, the first is
% kept and subsequent duplicates are discarded.
% FIXME - documentation
% USAGE
%    [ soilT, SWC, SHF ] = preprocess_PJ_soil_data( sitecode, year )
%
% INPUTS
%    sitecode: integer or UNM_sites object; either PJ or PJ_girdle
%    year: integer; year of data to preprocess
% PARAMETER-VALUE PAIRS
%    t_min, t_max: matlab datenums; if specified, data will be truncated to
%        the interval t_min, t_max
%
% OUTPUTS:
%    soilT, SWC, SHF: matlab dataset arrays containing soil observations
%        (soil temperature, soil water content, and soil heat flux,
%        respectively)
%
% SEE ALSO
%    dataset, dataset_fill_timestamps
%
% author: Timothy W. Hilton, UNM, April 2012

if isa( sitecode, 'UNM_sites' )
    sitecode = int8( sitecode );
end

% determine file path
    sitename = get_site_name( sitecode );

    filePath = fullfile( getenv( 'FLUXROOT' ), ...
                      'Flux_Tower_Data_by_Site', ...
                      sitename,  ...
                      'soil' );
    if year < 2014
        directoryName = 'yearly_cr23x_compilations';
        fileName = sprintf( 'cr23x_%s_%d_compilation.dat', sitename, year );
        fileName = fullfile( filePath, directoryName, fileName );
        % Get the data - note that there is NO HEADER RESOLUTION
        % We are assuming headers in the compiled files are ok
        cr23xData = combine_and_fill_datalogger_files( ...
            'file_names', fileName, 'datalogger_type', 'cr23x', ...
            'resolve_headers', false);
    else
        directoryName = 'cr23x_files';
        dataDirectory = fullfile(filePath, directoryName);
        % IMPORTANT: Make sure the files have the format:
        % 'cr23x_$sitename$_YYYY_MM_DD_HHMM.dat'
        regularExpr = ...
            '^cr23x_.*_(\d\d\d\d)_(\d\d)_(\d\d)_(\d\d)(\d\d).(dat|DAT)$';
        fileNames = list_files( dataDirectory, regularExpr );
    
        % make datenums for the dates
        dateNumbers = tstamps_from_filenames(fileNames);
        %dateNumbers = cellfun( @get_TOA5_TOB1_file_date, fileNames );
        % sort by datenum
        [ dateNumbers, idx ] = sort( dateNumbers );
        fileNames = fileNames( idx );
        % Get the data and resolve headers in process
        cr23xData = combine_and_fill_datalogger_files( ...
            'file_names', fileNames, 'datalogger_type', 'cr23x', ...
            'resolve_headers', true );
    end
    
    % replace -9999 and -99999 with NaN
    badValues = [ -9999, 9999, -99999, 99999 ];
    cr23xData = replacedata( cr23xData, ...
                             @(x) replace_badvals( x, badValues, 1e-6 ) );
    

    
