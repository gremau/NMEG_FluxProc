function cr23xData = get_PJ_cr23x_data( sitecode, year )
% PREPROCESS_PJ_SOIL_DATA - parse CR23X soil data for PJ or PJ_girdle.
%
% Creates datasets for soil temperature, soil water content, and soil heat flux
% with complete 30-minute timestamp record and duplicate timestamps removed via
% dataset_fill_timestamps.  When duplicate timestamps are detected, the first is
% kept and subsequent duplicates are discarded.
%
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

    fpath = fullfile( getenv( 'FLUXROOT' ), ...
                      'Flux_Tower_Data_by_Site', ...
                      sitename,  ...
                      'soil' );
    if year < 2014
        dirname = 'yearly_cr23x_compilations';
        fname = sprintf( 'cr23x_%s_%d_compilation.dat', sitename, year );
        fname = fullfile( fpath, dirname, fname );
        cr23xData = combine_and_fill_datalogger_files({fname}, 'cr23x');%,...
%             sprintf('%s_cr23x_Header_Resolutions.csv',...
%             get_site_name(sitecode) ) );
    else
        dirname = 'cr23x_files';
        data_dir = fullfile(fpath, dirname);
        % IMPORTANT: Make sure the files have the format:
        % 'cr23x_$sitename$_YYYY_MM_DD_HHMM.dat'
        re = '^cr23x_.*_(\d\d\d\d)_(\d\d)_(\d\d)_(\d\d)(\d\d).(dat|DAT)$';
        fnames = list_files( data_dir, re );
    
        % make datenums for the dates
        dns = tstamps_from_TOB1_filenames(fnames);
        %dns = cellfun( @get_TOA5_TOB1_file_date, fnames );
        % sort by datenum
        [ dns, idx ] = sort( dns );
        fnames = fnames( idx );
        
        cr23xData = combine_and_fill_datalogger_files(fnames, 'cr23x',...
            sprintf('%s_cr23x_Header_Resolutions.csv',...
            get_site_name(sitecode) ) );
    end
    
    % replace -9999 and -99999 with NaN
    badvals = [ -9999, 9999, -99999, 99999 ];
    cr23xData = replacedata( cr23xData, ...
                             @(x) replace_badvals( x, badvals, 1e-6 ) );
    

    
