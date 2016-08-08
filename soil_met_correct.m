function T_soil_corr =  soil_met_correct( sitecode, year, write_qc, write_rbd )
% SOIL_MET_CORRECT - extracts soil water content (SWC), soil temperature,
% and soil heat flux (SHF and TCAV) data from fluxall files corrects it.
%
% Depending on site and instrumentation this involves converting raw
% sensor outputs to other units and making corrections to these data.
% cs616 sensor period is converted to VWC and temperature corrected. Most
% other sensors are left as is (for now).
%   
% USAGE
%    T_out =  UNM_Ameriflux_prepare_soil_met( sitecode, year, data, precip );
%
% INPUTS:
%    sitecode: UNM_sites object; specifies the site
%    year: four-digit year: specifies the year
%
% OUTPUTS
%    T_out: MATLAB table: soil variables extracted from data
%
% SEE ALSO
%    table, parse_fluxall_txt_file
%
% author: Gregory E. Maurer, UNM, Aug 2015
% adapted from UNM_Ameriflux_prepare_soil_met by Timothy W. Hilton

% Load data
sitecode = UNM_sites( sitecode );
fluxall_T = parse_fluxall_txt_file( sitecode, year );

% -----
% Get soil water content and soil temperature data from fluxall data
% -----

% Get header resolution
% Use sitecode and dataloggerType to find appropriate header resolution file
resFileName = sprintf('%s_HeaderResolution.csv', 'flux');
resFilePathName = fullfile( getenv('FLUXROOT'), 'FluxProcConfig', ...
    'HeaderResolutions', char( sitecode ), resFileName );
res = readtable( resFilePathName );
    
% Get soil data from fluxall
% First find QC headers matching regexp
re_soil = '[Ss][Ww][Cc]|SOILT|SHF|TCAV';
res_idx = find( ~cellfun( @isempty, regexp( res.qc_mapping, re_soil )));
% Index CURRENT headers in fluxall that match these QC headers
fluxall_idx = ismember(res.current( res_idx ), fluxall_T.Properties.VariableNames);
% Extract indexed soil columns from the fluxall table
T_soil = fluxall_T( :, res.current( res_idx( fluxall_idx) ) );
% Rename extracted soil columns with the qc_mapping names
T_soil.Properties.VariableNames = res.qc_mapping( res_idx( fluxall_idx) );

% Get SWC column names
[cols_swc, ~] = regexp_header_vars( T_soil, 'SWC' );

% Separate sensor data that is already converted to VWC,
% Includes columns marked with "echo" or "conv"
[cols_conv, ~] = regexp_header_vars( T_soil, 'SWC_echo|SWC_conv|SWC_DRI|SWC_SAHRA' );
if length( cols_conv ) > 0
    convtest = ismember( cols_swc, cols_conv );
    cols_swc = cols_swc( ~convtest );
end

% Get SoilT column names
[cols_ts, ~] = regexp_header_vars( T_soil, 'SOILT' );

% Get SHF and TCAV data column names
[cols_shf, ~] = regexp_header_vars( T_soil, 'SHF|TCAV' );

switch sitecode
    % sites with cs616s
    case { UNM_sites.GLand, UNM_sites.SLand, UNM_sites.JSav, ...
            UNM_sites.New_GLand, UNM_sites.MCon, UNM_sites.PPine }
        
        % If CS616s are present we need to convert period to VWC and 
        % temperature correct them. Make arrays of matched SoilT and SWC 
        % column names (by pit/depth) to send to cs616_period2vwc
        cols_swc_tcor = cols_swc;
        cols_ts_tcor = cols_ts;
        
        % Check for SOILT_AVG column. This column is (supposedly) a surface
        % level measurement that can be used to correct surface soil water
        % measurements.
        % If found separate from other columns
        [SOILT_AVG_col, loc] = ismember( 'SOILT_AVG', cols_ts_tcor);
        if SOILT_AVG_col
            cols_ts_tcor( loc ) = [];
        end
        
        % If there are remaining soil temperature columns, create a table of
        % soil temperature measurements in the order that matches the pit and
        % depths in the swc616 table
        if length( cols_ts_tcor ) > 0
            
            % Get the pit and depth info from 616 column headers
            tmp = regexp( cols_swc_tcor, '_', 'split' );
            id_616 = cellfun( @(x) [ x{2} '_' x{3} ], tmp,...
                'UniformOutput', false );
            % Get the pit and depth info from SoilT column headers
            tmp = regexp( cols_ts_tcor, '_', 'split' );
            id_ts = cellfun( @(x) [ x{2} '_' x{3} ], tmp,...
                'UniformOutput', false );
            
            % Find and sort matched cs616 and SoilT sensors by pit/depth
            [ ts_match, ts_loc ] = ismember( id_616, id_ts );
            
            % Subset and reorder columns so cs616 and SoilT columns match
            cols_swc_tcor = cols_swc_tcor( ts_match );
            cols_ts_tcor = cols_ts_tcor( ts_loc( ts_match ) );

        end
        
        % If there is a SOILT_AVG column it should be used for shallow sensors,
        % unless there are soil T sensors at all depths. Series of logic
        % statements to parse out the different possibilities
        %
        % If both are present
        if SOILT_AVG_col && length( cols_swc_tcor ) > 0
            swc_c = cs616_period2vwc( T_soil( :, cols_swc ),...
                'draw_plots', false );
            swc_c_tc = cs616_period2vwc( T_soil( :, cols_swc_tcor ), ...
                'T_soil', T_soil( :, cols_ts_tcor ), 'draw_plots', false );
            swc_c_tc_a = cs616_period2vwc( T_soil( :, cols_swc ), ...
                'T_soil', T_soil( :, 'SOILT_AVG' ), 'draw_plots', false );
            % Use SOILT_AVG corrected data only where proper depth
            % corrected data is NaN
            tc_a_cols = swc_c_tc_a.Properties.VariableNames;
            for i = 1:length( tc_a_cols );
                test = isnan( swc_c_tc{ :, tc_a_cols{i} } );
                swc_c_tc{ test, tc_a_cols{i} } = ...
                    swc_c_tc_a{ test, tc_a_cols{i} };
            end
        % Only the SOILT_AVG column present
        elseif SOILT_AVG_col
            swc_c = cs616_period2vwc( T_soil( :, cols_swc ),...
                'draw_plots', false );
            swc_c_tc = cs616_period2vwc( T_soil( :, cols_swc ), ...
                'T_soil', T_soil( :, 'SOILT_AVG' ), 'draw_plots', false );
        % Only matched SoilT sensor columns present
        elseif length( cols_ts_tcor ) > 0
            swc_c = cs616_period2vwc( T_soil( :, cols_swc ),...
                'draw_plots', false );
            swc_c_tc = cs616_period2vwc( T_soil( :, cols_swc_tcor ), ...
                'T_soil', T_soil( :, cols_ts_tcor ), 'draw_plots', false );
        % No SoilT data present
        else
            swc_c = cs616_period2vwc( T_soil( :, cols_swc ),...
                'draw_plots', false );
        end
        
    case { UNM_sites.PJ, UNM_sites.PJ_girdle, UNM_sites.TestSite }
        % There were echo probes early on that mostly look like garbage.
        % In early to mid 2009 the TDR system came online and data look
        % better. This does not need a temperature correction.
        swc_c = T_soil( :, cols_swc );
end

% Now concatenate the different tables.
T_soil_corr = [ swc_c T_soil( :, cols_ts ) T_soil( :, cols_shf ) ];
if exist( 'swc_c_tc', 'var' )
    % Rename columns to indicate temperature corrections applied
    swc_c_tc.Properties.VariableNames = ...
        cellfun(@(x) [x '_tcor'], swc_c_tc.Properties.VariableNames,...
        'UniformOutput', false);
    T_soil_corr = [ T_soil_corr, swc_c_tc ];
end
if length( cols_conv ) > 0
    T_soil_corr = [ T_soil_corr T_soil( :, cols_conv ) ];
end

% Get timestamp for exporting data to file
tstamps = fluxall_T( :, {'year', 'month', 'day', 'hour', 'min', 'second'});
% Write file
if write_qc
    %Export to soilmet_qc file with timestamps
    outpath = fullfile( get_site_directory( sitecode ), 'processed_soil\');
    fname = [outpath sprintf('%s_%d_soilmet_qc.txt', ...
        get_site_name( sitecode ), year )];
    fprintf( 'Writing %s...\n', fname );
    writetable( [ tstamps T_soil_corr ], fname, 'Delimiter', ',' );
end

%========================REMOVE BAD DATA===============================

T_soil_rbd = T_soil_corr;

% If there is data to clean follow these steps
if ~isempty( T_soil_rbd )
    % Get SWC column names
    [cols_swc_corr, swc_loc] = regexp_header_vars( T_soil_rbd, 'SWC' );
    
    % Remove SWC values > .45 and < 0
    data = table2array( T_soil_rbd );
    subset = data( :, swc_loc );
    bad_swc = subset > 0.45 | subset <= 0;
    subset( bad_swc ) = NaN;
    data( :, swc_loc ) = subset;
    T_soil_rbd = array2table( data, ...
        'VariableNames', T_soil_corr.Properties.VariableNames );
    
    % Get SoilT column names
    [cols_ts_corr, ts_loc] = regexp_header_vars( T_soil_rbd, 'SOILT' );
    
    % Remove SoilT values > 120 and < -30
    data = table2array( T_soil_rbd );
    subset = data( :, ts_loc );
    bad_ts = subset > 60 | subset < -22.5;
    subset( bad_ts ) = NaN;
    data( :, ts_loc ) = subset;
    T_soil_rbd = array2table( data, ...
        'VariableNames', T_soil_corr.Properties.VariableNames );
    
    % Clean out columns that are all NaN
    allnan = sum( isnan( table2array( T_soil_rbd ))) >= ...
        size( T_soil_rbd, 1 ) - 48;
    T_soil_rbd( :, allnan ) = [];
    
    % Now filter with the standard deviation filter
    % First set up filter - PJ sites need more filtering
    if sitecode==UNM_sites.PJ || sitecode==UNM_sites.PJ_girdle ...
            || sitecode==UNM_sites.TestSite
        sd_filter_windows = [ 1, 1, 1, 1, 1, 1 ];
    else
        sd_filter_windows = [ 1, 1, 1 ];
    end
    sd_filter_thresh = 3;
    
    for i = 1:length( T_soil_rbd.Properties.VariableNames )
        colname = T_soil_rbd.Properties.VariableNames{ i };
        col = T_soil_rbd( :, colname );
        % Sometimes too little data available to filter
        if sum( ~isnan( col{:,1} ) ) < min( sd_filter_windows )*48*2
            filt_col = col;
            filt_col{ ~isnan( col{:,1} ), 1 } = nan;
        else
            % Get the values flagged for std deviation
            [ filt_col, ~ ] = stddev_filter( col, ...
                sd_filter_windows, sd_filter_thresh, sitecode, year );
        end
        T_soil_rbd( :, colname ) = filt_col;
    end
    
end % if ~empty

%============ Individual site bad data removal ============
% 
ts = datenum( table2array( tstamps ) );
%
switch sitecode
  case UNM_sites.GLand
    switch year
      case {2007, 2008}
          % G3 12p5 SWC is mostly bad data before 2009
          idx = ts < datenum( 2008, 11, 15 );
          T_soil_rbd{ idx, 'SWC_G3_12p5_AVG' } = NaN;
      case 2009
          % Most of 2009 SWC data after Feb is bad
          idx = ts > datenum( 2009, 2, 27, 12, 30, 0 );
          [cols_rbd, ~] = regexp_header_vars( T_soil_rbd, 'SWC_O|SWC_G' );
          T_soil_rbd{ idx, cols_rbd } = NaN;
      case 2011
          % There is a level shift in late 2011 SWC data
          idx = ts > datenum( 2011, 3, 21, 11, 0, 0 );
          [cols_rbd, ~] = regexp_header_vars( T_soil_rbd, 'SWC_echo_O1' );
          T_soil_rbd{ idx, cols_rbd } = NaN;
      case {2012, 2013}
          % All 2012 and 2013 SWC data from G1 52p5 is bad
          T_soil_rbd{ :, 'SWC_G1_52p5_AVG' } = NaN;
      case 2014
          % There is a bad data period in 2014
          idx = ts > datenum( 2014, 1, 21, 14, 0, 0 ) & ...
              ts < datenum( 2014, 2, 17, 11, 0, 0 );
          [cols_rbd, ~] = regexp_header_vars( T_soil_rbd, 'SOILT_(G1|G2|O1|O2)' );
          T_soil_rbd{ idx, cols_rbd } = NaN;
    end

    
  case UNM_sites.New_GLand
    switch year
      case 2010
        % Most of 2010 SWC from install to May 12 is bad
          idx = ts < datenum( 2010, 5, 12, 17, 0, 0 );
          [cols_rbd, ~] = regexp_header_vars( T_soil_rbd, 'SWC_O|SWC_G' );
          T_soil_rbd{ idx, cols_rbd } = NaN;
          % Small sensor swap - not in logs. removing
          idx = ts > datenum( 2010, 6, 27, 15, 0, 0 ) & ...
              ts < datenum( 2010, 7, 16, 15, 30, 0 );
          [cols_rbd, ~] = regexp_header_vars( T_soil_rbd, 'SWC_O|SWC_G' );
          T_soil_rbd{ idx, cols_rbd } = NaN;
          % 2 sensors with zero data
          T_soil_rbd{ :, {'SOILT_G1_2p5_AVG', 'SOILT_G1_12p5_AVG'}} = NaN;
      case 2011
          % 2 sensors with zero data
          idx = ts < datenum( 2011, 11, 17, 14, 0, 0 );
          T_soil_rbd{ idx, {'SOILT_G1_2p5_AVG', 'SOILT_G1_12p5_AVG'}} = NaN;
      case {2012, 2013}
          % Noisy winter data in SWC_G1_12p5 sensor
          idx1 = ts > datenum( year, 11, 1 );
          idx2 = T_soil_rbd.SWC_G1_12p5_AVG > .125;
          T_soil_rbd.SWC_G1_12p5_AVG( idx1 & idx2 ) = NaN;
      case 2014
          % Noisy winter data in SWC_G1_12p5 sensor
          idx1 = ts < datenum( 2014, 2, 1 );
          idx2 = T_soil_rbd.SWC_G1_12p5_AVG > .125;
          T_soil_rbd.SWC_G1_12p5_AVG( idx1 & idx2 ) = NaN;
    end
 
    
  case UNM_sites.SLand
    switch year
      case {2007, 2008}
          T_soil_rbd{ :, {'SWC_O2_22p5_AVG', 'SWC_O2_52p5_AVG'} } = NaN;
      case 2009
          % There is a bad SoilT data period in 2009
          idx = ts < datenum( 2009, 7, 20, 14, 0, 0 );
          [cols_rbd, ~] = regexp_header_vars( T_soil_rbd, 'SOILT_[SO]' );
          T_soil_rbd{ idx, cols_rbd } = NaN;
          % and still some bad data from O2
          idx = ts < datenum( 2009, 5, 7, 13, 30, 0 );
          T_soil_rbd{ idx, {'SWC_O2_22p5_AVG', 'SWC_O2_52p5_AVG'} } = NaN;
          % O1 22p5 SoilT
          T_soil_rbd{ :, 'SOILT_O1_22p5_AVG' } = NaN;
      case 2010
          % O1 22p5 SoilT
          T_soil_rbd{ :, 'SOILT_O1_22p5_AVG' } = NaN;
      case 2011
          idx = ts > datenum( 2011, 5, 23, 9, 30, 0 ) & ...
              ts < datenum( 2011, 5, 24, 13, 00, 0 );
          [cols_rbd, ~] = regexp_header_vars( T_soil_rbd, 'SOILT_[SO]' );
          T_soil_rbd{ idx, cols_rbd } = NaN;
          % O1 22p5 SoilT
          T_soil_rbd{ :, 'SOILT_O1_22p5_AVG' } = NaN;
      case 2012
          % O1 22p5 SoilT
          T_soil_rbd{ :, 'SOILT_O1_22p5_AVG' } = NaN;
      case 2013
          idx = ts > datenum( 2013, 2, 13, 09, 30, 0 ) & ...
              ts < datenum( 2013, 3, 19, 10, 30, 0 );
          [cols_rbd, ~] = regexp_header_vars( T_soil_rbd, 'SOILT_[SO]' );
          T_soil_rbd{ idx, cols_rbd } = NaN;
          % O1 22p5 SoilT
          T_soil_rbd{ :, 'SOILT_O1_22p5_AVG' } = NaN;
      case 2014
        % There are some level-shifted bits that need to be removed. These
        % don't appear to be sensor swaps
          idx = ts > datenum( 2014, 1, 17, 14, 0, 0 ) & ...
              ts < datenum( 2014, 3, 04, 12, 0, 0 );
          [cols_rbd, ~] = regexp_header_vars( T_soil_rbd, ...
              'SWC_(O[12]_(12p5|37p5)|S[12]_(2p5|22p5))');
          T_soil_rbd{ idx, cols_rbd } = NaN;
          % O1 22p5 SoilT
          idx = ts < datenum( 2014, 10, 22, 09, 30, 0 );
          T_soil_rbd{ idx, 'SOILT_O1_22p5_AVG' } = NaN;
    end
    
  case UNM_sites.JSav
    % From early 2012 to early 2014 there was no cs616 period logged for
    % the SWC_J1_5 sensor. There was a datalogger converted VWC value
    % though (SWC_conv_J1_5_AVG) . Copy this into the appropriate range
    % in SWC_J1_5_AVG
    if year > 2011 && year < 2015
        idx = ts > datenum( 2012, 5, 2, 11, 0, 0 ) & ...
            ts < datenum( 2014, 1, 10, 10, 30, 0 );
        T_soil_rbd( idx, 'SWC_J1_5_AVG' ) = T_soil_rbd( idx, 'SWC_conv_J1_5_AVG' );
    end
    % Now individual year fixes.
    switch year
      case {2007, 2008}
          % Bad SoilT data in early years
          [cols_rbd, ~] = regexp_header_vars( T_soil_rbd, 'SOILT_(O[12]|J1_5)' );
          T_soil_rbd{ :, cols_rbd } = NaN;
      case 2009
          % constant value data in 2009
          idx = ts > datenum( 2009, 2, 2, 12, 30, 0 ) & ...
              ts < datenum(2009, 3, 6, 15, 0, 0);
          [cols_rbd, ~] = regexp_header_vars( T_soil_rbd, 'SWC_(O[12]|[EJ]1)' );
          T_soil_rbd{ idx, cols_rbd } = NaN;
          % Bad SoilT data in early years
          idx = ts < datenum( 2009, 7, 8, 16, 0, 0 );
          [cols_rbd, ~] = regexp_header_vars( T_soil_rbd, 'SOILT_(O[12]|J1|E1)' );
          T_soil_rbd{ idx, cols_rbd } = NaN;
          % Bad SoilT in J1 5 and 10 starts in 2009
          idx = ts > datenum( 2009, 7, 8, 15, 30, 0 );
          [cols_rbd, ~] = regexp_header_vars( T_soil_rbd, 'SOILT_J1_(5|10)' );
          T_soil_rbd{ idx, cols_rbd } = NaN;
      case {2010, 2011}
          % Bad SoilT in J1 5 and 10 starts in 2009
          idx = ts < datenum( 2011, 11, 18, 17, 30, 0 );
          [cols_rbd, ~] = regexp_header_vars( T_soil_rbd, 'SOILT_J1_(5|10)' );
          T_soil_rbd{ idx, cols_rbd } = NaN;
      case 2013
          % Constant values to remove
          idx = ts > datenum( 2013, 7, 25, 13, 0, 0 ) & ...
              ts < datenum( 2013, 10, 22, 13, 0, 0 );
          [cols_rbd, ~] = regexp_header_vars( T_soil_rbd, 'SOILT_[OJ][1-3]' );
          T_soil_rbd{ idx, cols_rbd } = NaN;
      case 2014
        % Bad period before sensor pits were redone
          idx = ts > datenum( 2014, 1, 10, 10, 0, 0 ) & ...
              ts < datenum( 2014, 2, 27, 18, 30, 0 );
          [cols_rbd, ~] = regexp_header_vars( T_soil_rbd, 'SWC_[OJ][1-3]' );
          T_soil_rbd{ idx, cols_rbd } = NaN;
           % Bad period in summer
          idx = ts > datenum( 2014, 7, 1, 23, 30, 0 ) & ...
              ts < datenum( 2014, 7, 15, 22, 0, 0 );
          T_soil_rbd{ idx, 'SOILT_J2_5_AVG' } = NaN;
    end
    
    case { UNM_sites.PJ, UNM_sites.PJ_girdle, sitecode==UNM_sites.TestSite }
        if year > 2008 && year < 2014
            if sitecode==UNM_sites.PJ | sitecode==UNM_sites.TestSite
                site_token = 'PJC';
            elseif sitecode==UNM_sites.PJ_girdle
                site_token = 'PJG';
            end
            % Get the name of Laura Morillas's QC'd soil data file
            soilqcPathFileName = fullfile(get_site_directory(sitecode), ...
                'secondary_loggers', 'soil_sap', ...
                'LM_CR23xCompilations_qc', num2str( year ), sprintf( ...
                'SWC_%s_%d_REFINED_30min.CSV', site_token, year) );
            soilqc = readtable( soilqcPathFileName, 'FileType', 'text', ...
                'Delimiter', ',', 'TreatAsEmpty', {'NA'} );
            % Fix funny header names
            newColNames = regexprep( soilqc.Properties.VariableNames, ...
                '(^x[0-9][0-9]WC|^WC)', 'SWC_LM' );
            newColNames = regexprep(newColNames, 'AVGH', 'AVG');
            soilqc.Properties.VariableNames = newColNames;
            % Now join with T_soil_rbd
            new = array2table( repmat( nan, 1, size( soilqc, 2 )), ...
                'VariableNames', newColNames );
            soilqc = [ soilqc; new ];
            T_soil_rbd = [ T_soil_rbd, ...
                soilqc( :, ~cellfun( 'isempty', ...
                strfind(newColNames, '_LM_' )))];
        end
        if year == 2013
            % Our 30cm SOILT probe has a spike
            idx = ts > datenum( 2013,8,5,4,30,0 ) & ts < datenum( 2013,9,26 );
            [cols_rbd, ~] = regexp_header_vars( T_soil_rbd, 'SOILT_J3_30' );
            T_soil_rbd{ idx, cols_rbd } = NaN;
        elseif year == 2014
            % Our 30cm SOILT probe has a spike
            idx = ts > datenum( 2014,1,24 ) & ts < datenum( 2014,2,13 );
            [cols_rbd, ~] = regexp_header_vars( T_soil_rbd, 'SOILT_O1_30' );
            T_soil_rbd{ idx, cols_rbd } = NaN;
        elseif year == 2015
            % Our 30cm SOILT probe has a spike
            idx = ts > datenum( 2015,7,31 ) & ts < datenum( 2015,6,6,12,0,0 );
            [cols_rbd, ~] = regexp_header_vars( T_soil_rbd, 'SOILT_J3' );
            T_soil_rbd{ idx, cols_rbd } = NaN;
        end
    case  UNM_sites.PPine
        if year <= 2014
            % Prior to Oct 2nd 2014, all our probes look crazy
            [cols_rbd, ~] = regexp_header_vars( T_soil_rbd, '(SWC|SOILT)_P[1-3]' );
            idx = ts < datenum( 2014, 10, 3 );
            T_soil_rbd{ idx, cols_rbd } = NaN;
            % Our 60cm SWC probes look bad
            [cols_rbd, ~] = regexp_header_vars( T_soil_rbd, 'SWC_P[1-3]_60' );
            T_soil_rbd{ :, cols_rbd } = NaN;
        end
        if year >= 2015
        % Our 60cm SWC probes look bad
            [cols_rbd, ~] = regexp_header_vars( T_soil_rbd, 'SWC_P[1-3]_60' );
            T_soil_rbd{ :, cols_rbd } = NaN;
        end
    case UNM_sites.MCon
        %SAHRA soil T had problems in summer from 2010-2012
        if year == 2010
            idx1 = ts > datenum( 2010,7,14 ) & ts < datenum( 2010,8,2 );
            idx2 = ts > datenum( 2010,8,13 ) & ts < datenum( 2010,8,15 );
            idx3 = ts > datenum( 2010,8,17,10,0,0 ) & ts < datenum( 2010,8,29 );
            idx4 = ts > datenum( 2010,9,17 ) & ts < datenum( 2010,9,19 );
            idx5 = ts > datenum( 2010,10,5,18,0,0 ) & ts < datenum( 2010,11,4 );
            [cols_rbd, ~] = regexp_header_vars( T_soil_rbd, '(SWC|SOILT)_SAHRA_P1' );
            T_soil_rbd{ idx1 | idx2 | idx3 | idx4 | idx5, cols_rbd } = NaN;
        elseif year == 2011
            idx1 = ts > datenum( 2011,7,11 ) & ts < datenum( 2011,10,9 );
            [cols_rbd, ~] = regexp_header_vars( T_soil_rbd, '(SWC|SOILT)_SAHRA_P1' );
            T_soil_rbd{ idx1, cols_rbd } = NaN;
        elseif year == 2012
            idx1 = ts > datenum( 2012,6,29,12,0,0 );
            [cols_rbd, ~] = regexp_header_vars( T_soil_rbd, '(SWC|SOILT)_SAHRA_P1' );
            T_soil_rbd{ idx1, cols_rbd } = NaN;
        elseif year == 2015
            % Our 60cm SOILT probe has a spike
            idx = ts > datenum( 2015,5,6,4,30,0 ) & ts < datenum( 2015,5,9 );
            [cols_rbd, ~] = regexp_header_vars( T_soil_rbd, 'SOILT_P2_60' );
            T_soil_rbd{ idx, cols_rbd } = NaN;
            % Our 60cm  SWC probe looks bad
            idx = ts > datenum( 2015,1,1 ) & ts < datenum( 2015,7,6,12,0,0 );
            [cols_rbd, ~] = regexp_header_vars( T_soil_rbd, 'SWC_P2_60' );
            T_soil_rbd{ idx, cols_rbd } = NaN;
        end
      
end



%===============Write file==================

if write_rbd
    %Export to soilmet_qc file
    outpath = fullfile( get_site_directory( sitecode ), 'processed_soil\');
    fname = [ outpath sprintf('%s_%d_soilmet_qc_rbd.txt', ...
        get_site_name( sitecode ), year )];
    fprintf( 'Writing %s...\n', fname );
    writetable( [tstamps T_soil_rbd], fname, 'Delimiter', ',' );
end
%        
%         t0 = now();
%         cs616_pd_smoothed = UNM_soil_data_smoother( cs616_pd, 6, false );
%         SWC_smoothed = true;
%         fprintf( 'smooth cs616: %0.2f mins\n', ( now() - t0 ) * 24 * 60 );
%         
%         if ( sitecode == UNM_sites.GLand ) & ( year == 2011 )
%             % GLand SWC probes were reinstalled on 22 Mar 2011, introducing an
%             % artificial discontinuity in most of the probes.  Correct that by
%             % raising signal after 22 Mar to its pre-22 Mar level.
%             draw_plots = false;  % set to true to see the corrections
%             cs616_pd_smoothed = GLand_2011_correct_22Mar( cs616_pd_smoothed, ...
%                 draw_plots );
%         end
%         
%         
%         if ( sitecode == UNM_sites.JSav ) & ( year == 2009 )
%             cs616_pd = data( :, regexp_header_vars( data, ...
%                 'cs616SWC_[A-Za-z]+_[0-9]+_[0-9]+.*' ) );
%             
%             t0 = now();
%             cs616_pd_smoothed = UNM_soil_data_smoother( cs616_pd, 6, false );
%             SWC_smoothed = true;
%             fprintf( 'smooth cs616: %0.2f mins\n', ( now() - t0 ) * 24 * 60 );
%         end
%         
%         if ( sitecode == UNM_sites.JSav ) & ( year == 2012 )
%             draw_plots = false;  % set to true to see the corrections
%             cs616_pd_smoothed = ...
%                 JSav_2012_datalogger_transition( cs616_pd, ...
%                 6, ...
%                 draw_plots );
%         end
%         
%         % if necessary, convert CS616 periods to volumetric water content
%         [ cs616_smoothed, ...
%             cs616_Tc_smoothed ] = cs616_period2vwc( cs616_pd_smoothed, ...
%             Tsoil, ...
%             'draw_plots', false, ...
%             'save_plots', false, ...
%             'sitecode', sitecode, ...
%             'year', year );
%         
%         % t0 = now();
%         % cs616_Tc_smoothed = UNM_soil_data_smoother( cs616_Tc, 6, false );
%         % fprintf( 'smooth T-corrected SWC: %0.2f mins\n', ( now() - t0 ) * 24 * 60 );
%         
%         if ( year == 2011 ) & sitecode == ( UNM_sites.SLand )
%             cs616_Tc_smoothed = fix_2011_SLand_SWC( cs616_Tc_smoothed );
%         end
%         
%         TCAV = data( :, regexp_header_vars( data, ...
%             'TCAV_[A-Za-z]+.*' ) );
%     case { UNM_sites.PPine }
%         cs616 = preprocess_PPine_soil_data( year );
%         two_mins = 2;
%         [ ~, cs616 ] = merge_datasets_by_datenum( data, cs616, ...
%             'timestamp', 'timestamp', ...
%             two_mins, ...
%             min( data.timestamp ), ...
%             max( data.timestamp ) );
%         % cs616 = cs616( find_unique( cs616.timestamp ), : );
%         cs616.timestamp = [];
%         cs616_Tc = cs616;  % PPine SWC data are already in VWC form
%         
%         
%         re_Tsoil = 'soilT.*';
%         Tsoil = data( :, regexp_header_vars( data, re_Tsoil ) );
%         
%         TCAV = data( :, regexp_header_vars( data, ...
%             'TCAV_[A-Za-z]+.*' ) );
%         
%   case { UNM_sites.MCon }
%     cs616 = preprocess_MCon_soil_data( year, data.timestamp );
%     cs616.timestamp = [];
%     cs616_Tc = cs616;  % MCon SWC data are already in VWC form
% 
%     re_Tsoil = 'soilT.*';
%     Tsoil = data( :, regexp_header_vars( data, re_Tsoil ) );
%     
%     TCAV = data( :, regexp_header_vars( data, ...
%                                     'TCAV_[A-Za-z]+.*' ) );
%         
%   case { UNM_sites.PJ, UNM_sites.PJ_girdle }
%     % PJ and PJ_girdle store their soil data outside of FluxAll.
%     % These data are already converted to VWC.
%     
%     [ Tsoil, cs616, SHF ] = preprocess_PJ_soil_data( sitecode, year );
% %         preprocess_PJ_soil_data( sitecode, ...
% %                                  year, ...
% %                                  't_min', min( data.timestamp ), ...
% %                                  't_max', max( data.timestamp ) );
%     if any( ( Tsoil.tstamps - data.timestamp ) > 1e-10 )
%         error( 'soil data timestamps do not match fluxall timestamps' );
%     end
%     Tsoil.tstamps = [];
%     cs616.tstamps = [];
%     SHF.tstamps = [];
%     cs616_Tc = cs616; %replacedata( cs616, repmat( NaN, size( cs616 ) ) );
%     TCAV = [];
%     
% end
% 
% switch sitecode
%   case UNM_sites.SLand
%     switch year
%       case 2009
%         temp = double( Tsoil );
%         temp( 1:DOYidx( 201.5 ), : ) = NaN;
%         Tsoil = replacedata( Tsoil, temp );
%     end
% end
% 
% % these sensors have problems with electrical noise -- remove noisy points
% Tsoil_smoothed = UNM_soil_data_smoother( Tsoil, 12, false );
% if not( SWC_smoothed )
%     fprintf( 'smoothing soil water\n' );
%     cs616_Tc_smoothed = UNM_soil_data_smoother( cs616_Tc, 12, false );
% end
% draw_plots = false;
% Tsoil_smoothed = fill_soil_temperature_gaps( Tsoil_smoothed, ...
%                                              ds_qc.precip, ...
%                                              draw_plots );
% cs616_Tc_smoothed = fill_soil_water_gaps( cs616_Tc_smoothed, ...
%                                           ds_qc.precip, ...
%                                           draw_plots );
% 
% % remove data from specific periods at specific probes that are obviously bogus
% [ Tsoil_smoothed, cs616_Tc_smoothed ] = ...
%     remove_problematic_soil_probe_data( sitecode, ...
%                                         year, ...
%                                         Tsoil_smoothed, ...
%                                         cs616_Tc_smoothed );
% 
% % calculate averages by cover type, depth
% [ Tsoil_cover_depth_avg, ...
%   Tsoil_cover_avg, ...
%   Tsoil_depth_avg ] = soil_data_averager( Tsoil_smoothed, ...
%                                           'draw_plots', false, ...
%                                           'fill_type', 'interp' );
% [ VWC_cover_depth_avg, ...
%   VWC_cover_avg, ...
%   VWC_depth_avg ] = soil_data_averager( cs616_Tc_smoothed, ...
%                                         'draw_plots', false, ...
%                                         'fill_type', 'interp' );
% 
% if ( sitecode == UNM_sites.GLand ) & ( year == 2011 )
%     [ VWC_depth_avg, VWC_cover_depth_avg ] = ...
%         fill_JunJul_2011_GLand_SWC_gap( VWC_depth_avg, VWC_cover_depth_avg );
% end
% 
% if not( isempty( TCAV ) )
%     soil_surface_T = TCAV;
% else
%     soil_surface_T = Tsoil_cover_avg;
% end
% 
% if sitecode == UNM_sites.JSav
%     soil_surface_T = Tsoil_cover_avg;
% end
% 
% % if there's only one soil temp measurement, use it for all SWC measurements
% if size( soil_surface_T, 2 ) == 1
%     soil_surface_T = ...
%         repmat( soil_surface_T, 1, size( VWC_cover_avg, 2 ) );
%     % give the replicated T values descriptive names
%     soil_surface_T.Properties.VarNames = ...
%         regexprep( VWC_cover_avg.Properties.VarNames, ...
%                    'VWC', ...
%                    'soilT' );
% end
% 
% fprintf( 'second smoothing pass\n' );
% Tsoil_smoothed = UNM_soil_data_smoother( Tsoil_smoothed, 12, false );
% cs616_Tc_smoothed = UNM_soil_data_smoother( cs616_Tc_smoothed, 12, false );
% 
% % -----
% % -----
% % now we have T-corrected VWC and soil T. Calculate heat flux with storage.
% % -----
% % -----
% 
% SHF_pars = define_SHF_pars( sitecode, year );
% if not( ismember( sitecode, [ UNM_sites.PJ, UNM_sites.PJ_girdle ] ) )
%     SHF = data( :, shf_vars );
%     shf_vars = cellfun( @(x) [ x, '_0' ], shf_vars, 'UniformOutput', false );
%     SHF.Properties.VarNames = shf_vars; 
% end
% if not( isempty( SHF ) )
%     [ SHF_cover_depth_avg, ...
%       SHF_cover_avg, ...
%       SHF_depth_avg ] = soil_data_averager( SHF, ...
%                                             'draw_plots', false, ...
%                                             'fill_type', 'interp' );
% else
%     SHF_cover_depth_avg = [];
%     SHF_cover_avg = [];
%     SHF_depth_avg = [];
% end
% 
% switch sitecode
%   case UNM_sites.SLand
%     % do not calculate SHF with storage at the "grass" pits -- we don't have
%     % SWC and soil T observations for SLand grass, and there isn't much grass
%     % there anyway (as per conversation with Marcy 6 Aug 2012).
%     [ ~, SHF_grass_idx ] = regexp_header_vars( SHF_cover_avg, 'grass' );
%     SHF_cover_avg( :, SHF_grass_idx ) = [];
%   case UNM_sites.JSav
%     if year >= 2009
%         % similarly, ignore "edge" pits at JSav
%         [ ~, JSav_edge_idx ] = regexp_header_vars( SHF_cover_avg, 'edge' );
%         SHF_cover_avg( :, JSav_edge_idx ) = [];
%     end
%   case UNM_sites.MCon
%     % here there is only one soil heat flux plate, so use the average T and
%     % VWC of all soil covers for calculating storage
%     VWC_cover_avg_out = VWC_cover_avg;...
%     VWC_cover_avg = dataset( { nanmean( double( VWC_cover_avg ), 2 ), ...
%                         'VWC_mcon_1' } );
%     soil_surface_T = dataset( { nanmean( double( soil_surface_T ), 2 ), ...
%                         'soilT_mcon_1' } );
% end
% 
% % %----- soil data for Matt -- remove this later -----
% % soil_data_for_matt = horzcat( Tsoil_runmean, cs616_runmean );
% % fname = fullfile( getenv( 'FLUXROOT' ), 'FluxOut', 'SoilForMatt', ...
% %                   sprintf( '%s_%d_soil.mat', char( sitecode ), year ) );
% % fprintf( 'saving %s\n', fname );
% % save( fname, 'soil_data_for_matt' );
% % %----- soil data for Matt -- remove this later -----
% 
% if not( isempty( SHF_cover_avg ) )
%     SHF = calculate_heat_flux( soil_surface_T, ...
%                                VWC_cover_avg, ...
%                                SHF_pars, ...
%                                SHF_cover_avg, ...
%                                1.0 );
% else
%     SHF = dataset( { repmat( NaN, size( data, 1 ), 1 ), ...
%                      sprintf( 'SHF_%s', char( sitecode ) ) } );
% end
% 
% %======================================================================
% % assign all the variables created above to a dataset to be returned to
% % the caller
% %======================================================================
% 
% switch sitecode
%   case UNM_sites.MCon
%     VWC_cover_avg = VWC_cover_avg_out;
% end
% 
% % create output dataset with attention to any duplicated data names
% out_names = genvarname( [ Tsoil_smoothed.Properties.VarNames, ...
%                     Tsoil_depth_avg.Properties.VarNames, ...
%                     Tsoil_cover_depth_avg.Properties.VarNames, ...
%                     cs616_Tc_smoothed.Properties.VarNames, ...
%                     VWC_depth_avg.Properties.VarNames, ...
%                     VWC_cover_depth_avg.Properties.VarNames, ...
%                     SHF.Properties.VarNames ] );
% out_data = [ double( Tsoil_smoothed ), ...
%              double( Tsoil_depth_avg ), ...
%              double( Tsoil_cover_depth_avg ), ...
%              double( cs616_Tc_smoothed ), ...
%              double( VWC_depth_avg ), ...
%              double( VWC_cover_depth_avg ), ...
%              double( SHF ) ];
% % out_names = genvarname( [ cs616_Tc_smoothed.Properties.VarNames, ...
% %                     VWC_depth_avg.Properties.VarNames, ...
% %                     VWC_cover_depth_avg.Properties.VarNames, ...
% %                     SHF.Properties.VarNames ] );
% % out_data = [ double( cs616_Tc_smoothed ), ...
% %              double( VWC_depth_avg ), ...
% %              double( VWC_cover_depth_avg ), ...
% %              double( SHF ) ];
% 
% % the soil data smoothing/averaging routine is setup to fill constant values
% % past the last valid observation in cases where there is a gap at the end of
% % the record, and there is no precipitation during that gap.  However, we
% % don't want to fill past the end of the most recent data collected from the
% % field (or, worse, into the future!).  So, make sure the soil data contain
% % only NaNs after the end of the most recent set of observations.
% out_data( (last_obs_row + 1) : end, : ) = NaN;
% 
% ds_out = dataset( { out_data, out_names{ : } } );
% 
% 
% % add timestamp columns
% [ YEAR, ~, ~, ~, ~, ~ ] = datevec( data.timestamp );
% DTIME = data.timestamp - datenum( YEAR, 1, 0, 0, 0, 0 );
% DOY = floor( DTIME );
% HRMIN = str2num( datestr( data.timestamp, 'HHMM' ) );
% ds_out = [ dataset( YEAR, DOY, HRMIN, DTIME ), ds_out ];
% 
% % calculate execution time and write status message
% t_tot = ( now() - t0 ) * 24 * 60 * 60;
% fprintf( 1, ' Done (%.0f secs)\n', t_tot );
% 
% 
% 
% 
% %----------------------------------------------------------------------    
% %----------------------------------------------------------------------    
% % helper functions start here
% %----------------------------------------------------------------------    
% %----------------------------------------------------------------------    
% 
% function [ ds ] = soildata_2_dataset(fluxall, columns, labels)
% 
% % SOILDATA_2_DATASET - pulls soil data from parsed Fluxall data into matlab
% % dataset.  Helper function for UNM_Ameriflux_prepare_soil_met.
% %   
% 
% % '.' is not a legal character for matlab variable names -- replace '.' in depth
% % labels (now in format e.g. 12.5) with p (e.g. 12p5)
% varnames = regexprep( labels, '([0-9])\.([0-9])', '$1p$2' );
% 
% ds = dataset( { fluxall( : ,columns ), varnames{ : } } );
% 
% %----------------------------------------------------------------------
% 
% function SHF_pars = define_SHF_pars( sitecode, year )
% % DEFINE_SHF_PARS - specifies parameters for calculating soil heat flux.
% % Helper function for UNM_Ameriflux_prepare_soil_met
% %   
% % author: Timothy W. Hilton, UNM, April 2012
% 
% % set parameter values for soil heat flux
% % scap and wcap do not vary among sites
% SHF_pars.scap = 837; 
% SHF_pars.wcap = 4.19e6; 
% SHF_pars.depth = 0.05;
% 
% switch sitecode
%     % bulk and depth vary across site-year
%   case UNM_sites.GLand
%     SHF_pars.bulk = 1398; 
%   case UNM_sites.SLand
%     SHF_pars.bulk=1327; 
%   case UNM_sites.JSav
%     SHF_pars.bulk=1720; 
%   case UNM_sites.PJ
%     SHF_pars.bulk=1437; 
%   case UNM_sites.PPine
%     warning( 'check PPine SHF parameters' );
%     SHF_pars.bulk = 1071;
%   case UNM_sites.MCon
%     warning( 'check MCon SHF parameters' );
%     SHF_pars.bulk = 1071;
%   case UNM_sites.TX
%     SHF_pars.bulk = 1114;
%   case UNM_sites.TX_forest
%     warning( 'check TX_forest SHF parameters -- bulk is currently NaN' );
%     SHF_pars.bulk = NaN;
%   case UNM_sites.TX_grass
%     warning( 'check TX_grass SHF parameters -- bulk is currently NaN' );
%     SHF_pars.bulk = NaN;
%   case UNM_sites.PJ_girdle
%     SHF_pars.bulk = NaN;
%     SHF_pars.bulk=1437; 
%     warning( ['check PJ_girdle SHF parameters -- bulk is currently set to PJ ' ...
%               'value (1437)'] );
%   case UNM_sites.New_GLand
%     SHF_pars.bulk = 1398;
% end %switch sitecode -- soil heat flux parameters
% 
% %--------------------------------------------------
% 
% function swc_smooth = JSav_2012_datalogger_transition( swc_raw, win, draw_plots )
% % JSAV_2012_DATALOGGER_TRANSITION - The JSav soil water content probes were
% %   moved to a CR1000 datalogger on 1 May 2012.  After the switch the datalogger
% %   recorded volumetric water content, not cs616 period in microseconds as
% %   before the switch.  Smoothing the data across that transition messes things
% %   up, so smooth the two halves of the record separately here
% 
% may1 = datenum( 2012, 5, 1 ) - datenum( 2012, 1, 0 ); 
% may1 = DOYidx( may1 );
% 
% swc_smooth1 = UNM_soil_data_smoother( swc_raw( 1:may1-1, : ), win, draw_plots ); 
% swc_smooth2 = UNM_soil_data_smoother( swc_raw( may1:end, : ), win, draw_plots ); 
% 
% swc_smooth = vertcat( swc_smooth1, swc_smooth2 );
% 
% 
% 
% %--------------------------------------------------
% 
% function VWC = GLand_2011_correct_22Mar( VWC, draw_plots )
% % GLAND_2011_CORRECT_22MAR - GLand SWC probes were reinstalled on 22 Mar 2011,
% % introducing an artificial discontinuity in most of the probes.  Correct that
% % by raising signal after 22 Mar to its pre-22 Mar level.
% %   
% 
% if draw_plots
%     figure();
%     plot( VWC, '.-' );
%     xlim( [ 3800, 4000 ] );
%     ylim( [ 0, 0.1 ] );
%     ylabel( 'VWC (m^3 m^{-3})');
%     xlabel( '30-minute array index' );
%     title( 'before' );
% end
% 
% % index for 14 Jun 00:00
% jun_14 = DOYidx( datenum( 2011, 6, 14 ) - datenum( 2011, 1, 0 ) );
% 
% delta_22mar = ( nanmean( double( VWC( 3812:3912, : ) ) ) - ...
%                 nanmean( double( VWC( 3920:4020, : ) ) ) );
% 
% % shift the post-22 Mar data to make them continuous with the pre-22 Mar data
% temp = double( VWC( 3920 : jun_14, : ) );
% temp = temp + repmat( delta_22mar, size( temp, 1 ), 1 );
% VWC( 3920 : jun_14, : )  = ...
%     replacedata( VWC( 3920 : jun_14, : ), temp );
% 
% % remove and fill by interpolation two periods of two and four hours,
% % respectively, where all the probes were going haywire
% temp = double( VWC( 1 : 4000, : ) );
% temp( 3912:3920, : ) = NaN;
% temp( 3815:3820, : ) = NaN;
% temp = column_inpaint_nans( temp, 4 );
% VWC( 1:4000, : )  = ...
%     replacedata( VWC( 1:4000, : ), temp );
% 
% if draw_plots
%     figure();
%     plot( VWC, '.-' );
%     xlim( [ 3800, 4000 ] );
%     ylim( [ 0, 0.1 ] );
%     ylabel( 'VWC (m^3 m^{-3})');
%     xlabel( '30-minute array index' );
%     title( 'after' );
% end
% 
% %--------------------------------------------------
% 
% function [ VWC_depth_avg, VWC_cover_depth_avg ] = ...
%     fill_JunJul_2011_GLand_SWC_gap( VWC_depth_avg, VWC_cover_depth_avg )
% % FILL_JUNJUL_2011G_LAND_SWC_GAP - there was a datalogger malfunction at GLand
% % from 13 June to 27 July 2011 that resulted in the loss of all data.  Here
% % we fill the cover--depth average volumetric water content using the same
% % averages from New_GLand.
% 
% varnames = { 'VWC_grass_2p5cm_Avg', 'VWC_grass_12p5cm_Avg', ...
%              'VWC_grass_22p5cm_Avg', 'VWC_grass_37p5cm_Avg', ...
%              'VWC_grass_52p5cm_Avg', ...
%              'VWC_open_2p5cm_Avg', 'VWC_open_12p5cm_Avg', ... 
%              'VWC_open_22p5cm_Avg', 'VWC_open_37p5cm_Avg' };
% 
% VWC = VWC_cover_depth_avg;
% 
% temp = double( VWC( 7401:10201, varnames ) );
% temp(:) = NaN;
% VWC( 7401:10201, varnames ) = replacedata( VWC( 7401:10201, varnames ), temp );
% 
% %-----
% % grass pit adjustments
% 
% % grass 2.5cm
% VWC.VWC_grass_2p5cm_Avg( 8670 ) = VWC.VWC_grass_2p5cm_Avg( 7400 );
% VWC.VWC_grass_2p5cm_Avg( 8676 ) = VWC.VWC_grass_2p5cm_Avg( 8670 ) + 0.025;
% VWC.VWC_grass_2p5cm_Avg( 8880 ) = VWC.VWC_grass_2p5cm_Avg( 8670 ) + 0.024;
% VWC.VWC_grass_2p5cm_Avg( 9198 ) = VWC.VWC_grass_2p5cm_Avg( 8670 ) + 0.007;
% VWC.VWC_grass_2p5cm_Avg( 9300 ) = VWC.VWC_grass_2p5cm_Avg( 8670 ) + 0.014;
% VWC.VWC_grass_2p5cm_Avg( 10000 ) = VWC.VWC_grass_2p5cm_Avg( 8670 ) + 0.0075;
% 
% % grass 12.5 cm
% VWC.VWC_grass_12p5cm_Avg( 8670 ) = VWC.VWC_grass_12p5cm_Avg( 7400 ) - 0.003;
% VWC.VWC_grass_12p5cm_Avg( 8920 ) = VWC.VWC_grass_12p5cm_Avg( 8670 ) + 0.004;
% VWC.VWC_grass_12p5cm_Avg( 10190 ) = VWC.VWC_grass_12p5cm_Avg( 8670 ) - 0.002;
% 
% % grass 22.5 cm
% VWC.VWC_grass_22p5cm_Avg( 8700 ) = VWC.VWC_grass_22p5cm_Avg( 7395 ) - 0.01;
% VWC.VWC_grass_22p5cm_Avg( 9500 ) = VWC.VWC_grass_22p5cm_Avg( 8700 ) + 0.001;
% VWC.VWC_grass_22p5cm_Avg( 10200 ) = VWC.VWC_grass_22p5cm_Avg( 7395 ) - 0.015;
% 
% % grass 37.5 cm
% VWC.VWC_grass_37p5cm_Avg( 8670 ) = VWC.VWC_grass_37p5cm_Avg( 7395 ) - 0.008;
% VWC.VWC_grass_37p5cm_Avg( 9100 ) = VWC.VWC_grass_37p5cm_Avg( 8670 ) + 0.001;
% VWC.VWC_grass_37p5cm_Avg( 10200 ) = VWC.VWC_grass_37p5cm_Avg( 10300 );
% 
% % grass 52.5 cm
% 
% 
% %-----
% % open pits
% 
% % open 2.5 cm
% VWC.VWC_open_2p5cm_Avg( 8670 ) = VWC.VWC_open_2p5cm_Avg( 7400 );
% VWC.VWC_open_2p5cm_Avg( 8775 ) = VWC.VWC_open_2p5cm_Avg( 8670 ) + 0.0175;
% VWC.VWC_open_2p5cm_Avg( 8925 ) = VWC.VWC_open_2p5cm_Avg( 8670 ) + 0.0175;
% VWC.VWC_open_2p5cm_Avg( 9200 ) = VWC.VWC_open_2p5cm_Avg( 8670 ) + 0.003;
% VWC.VWC_open_2p5cm_Avg( 9300 ) = VWC.VWC_open_2p5cm_Avg( 8670 ) + 0.015;
% VWC.VWC_open_2p5cm_Avg( 10000 ) = VWC.VWC_open_2p5cm_Avg( 8670 ) + 0.004;
% 
% % open 12.5 cm
% VWC.VWC_open_12p5cm_Avg( 8670 ) = VWC.VWC_open_12p5cm_Avg( 7400 ) - 0.002;
% VWC.VWC_open_12p5cm_Avg( 9100 ) = VWC.VWC_open_12p5cm_Avg( 8670 ) + 0.009;
% VWC.VWC_open_12p5cm_Avg( 10200 ) = VWC.VWC_open_12p5cm_Avg( 8670 );
% 
% % open 22.5 cm
% VWC.VWC_open_22p5cm_Avg( 8670 ) = VWC.VWC_open_22p5cm_Avg( 7400 ) - 0.008;
% VWC.VWC_open_22p5cm_Avg( 9100 ) = VWC.VWC_open_22p5cm_Avg( 7400 );
% VWC.VWC_open_22p5cm_Avg( 9600 ) = VWC.VWC_open_22p5cm_Avg( 9100 );
% VWC.VWC_open_22p5cm_Avg( 10200 ) = VWC.VWC_open_22p5cm_Avg( 9600 ) - 0.008;
% 
% % open 37.5 cm
% % linear interpolation of entire gap should be ok here
% 
% % open 52.5 cm
% New_GLand11 = parse_ameriflux_file( ...
%     get_ameriflux_filename( UNM_sites.New_GLand, 2011, 'soil' ) );
% offset = New_GLand11.VWC_open_520x2E5_Avg( 10000 ) - ...
%          VWC.VWC_open_52p5cm_Avg( 10000 );
% 
% VWC.VWC_open_52p5cm_Avg( 1:10000 ) = ...
%     New_GLand11.VWC_open_520x2E5_Avg( 1:10000 ) - offset;
% 
% % fill the gap by linear interpolation between the inflection points
% % specified above
% temp = VWC( 7400:10202, varnames );
% temp = double( temp );
% temp = column_inpaint_nans( temp, 4 );
% 
% % replace the gap in the input dataset with the interpolated data
% VWC( 7400:10202, varnames ) = ...
%     replacedata( VWC( 7400:10202, varnames ),  temp );
% 
% VWC_cover_depth_avg = VWC;
% 
% % recalculate the site-wide-by-depth averages with the filled data
% VWC_depth_avg( :, 'VWC_2p5cm_Avg' ) = replacedata( ...
%     VWC_depth_avg( :, 'VWC_2p5cm_Avg' ), ...
%     mean( [ double( VWC_cover_depth_avg( :, 'VWC_grass_2p5cm_Avg' ) ), ...
%             double( VWC_cover_depth_avg( :, 'VWC_open_2p5cm_Avg' ) ) ], 2 ) );
% VWC_depth_avg( :, 'VWC_12p5cm_Avg' ) = replacedata( ...
%     VWC_depth_avg( :, 'VWC_12p5cm_Avg' ), ...
%     mean( [ double( VWC_cover_depth_avg( :, 'VWC_grass_12p5cm_Avg' ) ), ...
%             double( VWC_cover_depth_avg( :, 'VWC_open_12p5cm_Avg' ) ) ], 2 ) );
% VWC_depth_avg( :, 'VWC_37p5cm_Avg' ) = replacedata( ...
%     VWC_depth_avg( :, 'VWC_37p5cm_Avg' ), ...
%     mean( [ double( VWC_cover_depth_avg( :, 'VWC_grass_37p5cm_Avg' ) ),...
%             double( VWC_cover_depth_avg( :, 'VWC_open_37p5cm_Avg' ) ) ], 2 ) );
% VWC_depth_avg( :, 'VWC_52p5cm_Avg' ) = replacedata( ...
%     VWC_depth_avg( :, 'VWC_52p5cm_Avg' ), ...
%     mean( [ double( VWC_cover_depth_avg( :, 'VWC_grass_52p5cm_Avg' ) ), ...
%             double( VWC_cover_depth_avg( :, 'VWC_open_52p5cm_Avg' ) ) ], 2 ) );
% 
% 
% %--------------------------------------------------
% 
% function VWC = fix_2011_SLand_SWC( VWC )
% % FIX_2011_SLAND_SWC - there is an obviously-incorrect step change in many of
% %   the SLand 2011 soil water probes around 22 May, perhaps from a lightnig
% %   strike or other electrical anomaly.  Using GLand and New_GLand as guides,
% %   here we implement best-approximation fixes to the SWC records for SLand
% %   2011.
% 
% figure(); h0 = plot( VWC.cs616SWC_open_1_2p5, '.k' );
% VWC.cs616SWC_open_1_2p5( 6800:7200 ) = NaN;
% idx = 7200:9500;
% VWC.cs616SWC_open_1_2p5( idx ) = VWC.cs616SWC_open_1_2p5( idx ) - 0.0125;
% hold on; h1 = plot( VWC.cs616SWC_open_1_2p5, '-ob' ); 
% title( 'open\_1\_2.5' ); legend( [ h0, h1 ], 'before', 'after' );
% 
% figure(); h0 = plot( VWC.cs616SWC_open_1_12p5, '.k' );
% VWC.cs616SWC_open_1_12p5( 6800:7200 ) = NaN;
% idx = 7200:10063;
% VWC.cs616SWC_open_1_12p5( idx ) = VWC.cs616SWC_open_1_12p5( idx ) - 0.01;
% hold on; h1 = plot( VWC.cs616SWC_open_1_12p5, '-ob' ); 
% title( 'open\_1\_12.5' ); legend( [ h0, h1 ], 'before', 'after' );
% 
% figure(); h0 = plot( VWC.cs616SWC_open_1_22p5, '.k' );
% idx = 6800:13276;
% VWC.cs616SWC_open_1_22p5( idx ) = VWC.cs616SWC_open_1_22p5( idx ) + 0.01;
% hold on; h1 = plot( VWC.cs616SWC_open_1_22p5, '-ob' ); 
% title( 'open\_1\_22.5' ); legend( [ h0, h1 ], 'before', 'after' );
% 
% figure(); h0 = plot( VWC.cs616SWC_open_1_37p5, '.k' );
% VWC.cs616SWC_open_1_37p5( 6800:end ) = ...
%     VWC.cs616SWC_open_1_37p5( 6800:end ) + 0.065;
% VWC.cs616SWC_open_1_37p5( 6750:6910 ) = NaN;
% hold on; h1 = plot( VWC.cs616SWC_open_1_37p5, '-ob' ); 
% title( 'open\_1\_37.5' );legend( [ h0, h1 ], 'before', 'after' );
% 
% figure(); h0 = plot( VWC.cs616SWC_open_1_52p5, '.k' );
% idx = 6891:size( VWC, 1 );
% VWC.cs616SWC_open_1_52p5( idx ) = VWC.cs616SWC_open_1_52p5( idx ) + 0.032;
% hold on; h1 = plot( VWC.cs616SWC_open_1_52p5, '-ob' ); 
% title( 'open\_1\_52.5' ); legend( [ h0, h1 ], 'before', 'after' );
% 
% figure(); h0 = plot( VWC.cs616SWC_cover_1_2p5, '.k' );
% VWC.cs616SWC_cover_1_2p5( 6800:7200 ) = NaN;
% idx = 6890:9140;
% VWC.cs616SWC_cover_1_2p5( idx ) = VWC.cs616SWC_cover_1_2p5( idx ) + 0.0137;
% hold on; h1 = plot( VWC.cs616SWC_cover_1_2p5, '-ob' ); 
% title( 'cover\_1\_2.5' ); legend( [ h0, h1 ], 'before', 'after' );
% 
% figure(); h0 = plot( VWC.cs616SWC_cover_1_12p5, '.k' );
% VWC.cs616SWC_cover_1_12p5( 6800:7200 ) = NaN;
% idx = 6890:10034;
% VWC.cs616SWC_cover_1_12p5( idx ) = VWC.cs616SWC_cover_1_12p5( idx ) + 0.0388;
% hold on; h1 = plot( VWC.cs616SWC_cover_1_12p5, '-ob' ); 
% title( 'cover\_1\_12.5' ); legend( [ h0, h1 ], 'before', 'after' );
% 
% figure(); h0 = plot( VWC.cs616SWC_cover_1_22p5, '.k' );
% VWC.cs616SWC_cover_1_22p5( 6800:7200 ) = NaN;
% idx = 6890:16903;
% VWC.cs616SWC_cover_1_22p5( idx ) = VWC.cs616SWC_cover_1_22p5( idx ) + 0.0388;
% hold on; h1 = plot( VWC.cs616SWC_cover_1_22p5, '-ob' ); 
% title( 'cover\_1\_22.5' ); legend( [ h0, h1 ], 'before', 'after' );
% 
% figure(); h0 = plot( VWC.cs616SWC_cover_1_37p5, '.k' );
% VWC.cs616SWC_cover_1_37p5( 6800:end ) = ...
%     VWC.cs616SWC_cover_1_37p5( 6800:end ) + 0.045;
% VWC.cs616SWC_cover_1_37p5( 6750:6910 ) = NaN;
% hold on; h1 = plot( VWC.cs616SWC_cover_1_37p5, '-ob' ); 
% title( 'cover\_1\_37.5' );legend( [ h0, h1 ], 'before', 'after' );
% 
% figure(); h0 = plot( VWC.cs616SWC_cover_1_52p5, '.k' );
% VWC.cs616SWC_cover_1_52p5( 6800:end ) = ...
%     VWC.cs616SWC_cover_1_52p5( 6800:end ) + 0.0225;
% VWC.cs616SWC_cover_1_52p5( 6750:6910 ) = NaN;
% hold on; h1 = plot( VWC.cs616SWC_cover_1_52p5, '-ob' ); 
% title( 'cover\_1\_52.5' );legend( [ h0, h1 ], 'before', 'after' );
% 
% figure(); h0 = plot( VWC.cs616SWC_open_2_2p5, '.k' );
% idx = 7156:7848;
% VWC.cs616SWC_open_2_2p5( idx ) = VWC.cs616SWC_open_2_2p5( idx ) - 0.02;
% hold on; h1 = plot( VWC.cs616SWC_open_2_2p5, '-ob' ); 
% title( 'open\_1\_2.5' ); legend( [ h0, h1 ], 'before', 'after' );
% 
% figure(); h0 = plot( VWC.cs616SWC_open_2_12p5, '.k' );
% idx = 7172:7995;
% VWC.cs616SWC_open_2_12p5( idx ) = VWC.cs616SWC_open_2_12p5( idx ) + 0.02057;
% hold on; h1 = plot( VWC.cs616SWC_open_2_12p5, '-ob' ); 
% title( 'open\_1\_12.5' ); legend( [ h0, h1 ], 'before', 'after' );
% 
% figure(); h0 = plot( VWC.cs616SWC_open_2_22p5, '.k' );
% VWC.cs616SWC_open_2_22p5( 6900:end ) = ...
%     VWC.cs616SWC_open_2_22p5( 6900:end ) + 0.019027;
% hold on; h1 = plot( VWC.cs616SWC_open_2_22p5, '-ob' ); 
% title( 'cover\_1\_22.5' ); legend( [ h0, h1 ], 'before', 'after' );
% 
% figure(); h0 = plot( VWC.cs616SWC_open_2_37p5, '.k' );
% VWC.cs616SWC_open_2_37p5( 6901:end ) = ...
%     VWC.cs616SWC_open_2_37p5( 6901:end ) + 0.035248;
% hold on; h1 = plot( VWC.cs616SWC_open_2_37p5, '-ob' ); 
% title( 'cover\_1\_37.5' ); legend( [ h0, h1 ], 'before', 'after' );
% 
% figure(); h0 = plot( VWC.cs616SWC_open_2_52p5, '.k' );
% VWC.cs616SWC_open_2_52p5( 6683:8600 ) = NaN;
% VWC.cs616SWC_open_2_52p5( 8601:end ) = ...
%     VWC.cs616SWC_open_2_52p5( 8601:end ) + 0.026436;
% hold on; h1 = plot( VWC.cs616SWC_open_2_52p5, '-ob' ); 
% title( 'cover\_1\_52.5' ); legend( [ h0, h1 ], 'before', 'after' );
% 
% 
% figure(); h0 = plot( VWC.cs616SWC_cover_2_2p5, '.k' );
% idx = 6982:9200;
% VWC.cs616SWC_cover_2_2p5( idx ) = VWC.cs616SWC_cover_2_2p5( idx ) - 0.083827;
% hold on; h1 = plot( VWC.cs616SWC_cover_2_2p5, '-ob' ); 
% title( 'open\_1\_2.5' ); legend( [ h0, h1 ], 'before', 'after' );
% 
% % cover_2_12.5 actually looks ok
% 
% figure(); h0 = plot( VWC.cs616SWC_cover_2_22p5, '.k' );
% VWC.cs616SWC_cover_2_22p5( 6741:end ) = ...
%     VWC.cs616SWC_cover_2_22p5( 6741:end ) + 0.028255;
% hold on; h1 = plot( VWC.cs616SWC_cover_2_22p5, '-ob' ); 
% title( 'cover\_1\_22.5' ); legend( [ h0, h1 ], 'before', 'after' );
% 
% figure(); h0 = plot( VWC.cs616SWC_cover_2_37p5, '.k' );
% VWC.cs616SWC_cover_2_37p5( 6901:end ) = ...
%     VWC.cs616SWC_cover_2_37p5( 6901:end ) + 0.054706;
% hold on; h1 = plot( VWC.cs616SWC_cover_2_37p5, '-ob' ); 
% title( 'cover\_1\_37.5' ); legend( [ h0, h1 ], 'before', 'after' );
% 
% 
% figure(); h0 = plot( VWC.cs616SWC_cover_2_52p5, '.k' );
% VWC.cs616SWC_cover_2_52p5( 6683:8600 ) = NaN;
% VWC.cs616SWC_cover_2_52p5( 8601:end ) = ...
%     VWC.cs616SWC_cover_2_52p5( 8601:end ) + 0.027;
% hold on; h1 = plot( VWC.cs616SWC_cover_2_52p5, '-ob' ); 
% title( 'cover\_1\_52.5' ); legend( [ h0, h1 ], 'before', 'after' );
% 
