function tbl_out = merge_2007_fluxall_files( tbl_in, sitenum )
% MERGE_2007_FLUXALL_FILES - Merge data from old 2007 fluxall files into 
%       the incoming dataset.
%
% In 2007 the existing GLand and SLand sites and were acquired by 
% Marcy. The sites were then revamped (new programs and data handling)
% in late May/early June 2007. Data from before the revamp is present
% in old fluxall files, but I am unsure what had to be done to get this
% data into the old files. For now merge the old 2007 fluxall
% files into the current dataset and proceed with the QC process.
%
% USAGE
%    tbl_out = merge_2007_fluxall_files( tbl_in, sitenum )
%
% INPUTS
%     tbl_in : matlab table objects containing data to be merged
%     sitenum : integer indicating site (GLand = 1, SLand = 2)
%
% OUTPUTS
%     tbl_out: The merged table
%
% SEE ALSO
%     table
% 
% author: Gregory E. Maurer, UNM, July 2015

year = 2007;

old_path = fullfile( get_site_directory( sitenum ), 'old_fluxall');
old_fname = sprintf( '%s_FLUX_all_%d.txt', get_site_name( sitenum ), year );
    
% new_path = fullfile( get_site_directory( sitenum ));
% new_fname = sprintf( '%s_%d_fluxall.txt', get_site_name( sitenum ), year );
% 
% data_new = parse_fluxall_txt_file( sitenum, year, 'file', ...
%     fullfile( new_path, new_fname ));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Open old fluxall file and parse out dates and times
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

fprintf( 'merging 2007 fluxall versions:\n... loading %s...\n', old_fname );

fid = fopen( fullfile( old_path, old_fname ), 'r' );
headers = fgetl( fid );

% Split the headers on tab characters
headers_orig = regexp( headers, '\t', 'split' );

% Remove or replace characters that are illegal in matlab variable names
headers = clean_up_varnames( headers_orig );

% Read the numeric data
fmt = repmat( '%f', 1, numel( headers ) );
data = textscan( fid, ...
                 fmt, ...
                 'Delimiter', '\t' );
fclose( fid );
data = cell2mat( data );

% Replace -9999s with NaN using floating point test with tolerance of 0.0001
data = replace_badvals( data, [ -9999 ], 0.0001 );

% Create matlab dataset from data
empty_columns = find( cellfun( @length, headers ) == 0 );
headers( empty_columns ) = [];
data( :, empty_columns ) = [];
tbl = array2table( data, 'VariableNames', headers );

% There are not accurate timestamps in the old file, so they must be
% created and the file must be trimmed at the point where data from the new
% fluxall file can be used
if sitenum == 1
    start_d = datenum( year, 1, 1, 0, 30, 0);
    trim_to = datenum( year, 6, 5, 17, 30, 0);
elseif sitenum == 2
    start_d = datenum( year, 1, 8, 12, 30, 0);
    trim_to = datenum( year, 5, 30, 18, 0, 0);
end

end_d = datenum( year+1, 1, 1, 0, 0, 0);
tbl.timestamp = (start_d:1/48:end_d)';

tbl = tbl( tbl.timestamp < trim_to, : );

% Fill in the missing date/time columns

[y, m, d, H, M, S] = datevec(tbl.timestamp);
tbl.year = y;
tbl.month = m;
tbl.day = d;
tbl.hour = H;
tbl.min = M;
tbl.second = S;
tbl.jday = tbl.timestamp - datenum( year, 1, 1, 0, 0, 0);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Rename the old variables to the new format
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

renameOldVars = {'CO2flux_raw', 'ustar_frictionVelocity_M_s',...
           'CO2flux_raw_massman','CO2flux_water_term',...
           'CO2flux_heat_term_massman', 'H2Oflux_uncorrected', ...
           'H2Oflux_Euncorr_massman', 'H2Oflux_water_term', ...
           'H2Oflux_heat_term_massman', 'H2Oflux_corr_massman', ...
           'CO2flux_corr_massman_ourwpl', 'SensibleHeat_dry_WM2',...
           'LatentHeat_uncorrected_WM2', 'LatentHeat_uncorr_massman', ...
           'LatentHeat_corr_massman', 'CO2_mean_umol_molDryAir', ...
           'co2_mean', 'h2o_Avg', ...
           'rh_hmp', 't_hmp_mean', 'windDirection_theta', 'par_Avg', ...
           'Rad_long_Up_Avg', 'Rad_long_Dn_Avg'};

renameTo = {'Fc_raw', 'ustar',...
           'Fc_raw_massman','Fc_water_term',...
           'Fc_heat_term_massman', 'E_raw', ...
           'E_raw_massman', 'E_water_term', ...
           'E_heat_term_massman', 'E_wpl_massman', ...
           'Fc_raw_massman_ourwpl', 'SensibleHeat_dry',...
           'LatentHeat_raw', 'LatentHeat_raw_massman', ...
           'LatentHeat_wpl_massman', 'CO2_mean', ...
           'co2_mean_Avg', 'h2o_mean_Avg', ...
           'RH_Avg', 'AirTC_Avg', 'wind_direction', 'par_licor', ...
           'Rad_long_Up__Avg', 'Rad_long_Dn__Avg'};

tbl.Properties.VariableNames(renameOldVars) = renameTo(:);

% Fold in the data from the old file into the new dataset
tbl_out = table_foldin_data( tbl_in, tbl);

% Check that there aren't multiple years in the incoming data
% [ nRows, nCol ] = size( tbl );
% inYearRecords = tbl.year == year_arg ;
% %years = unique( tbl.year( 1:end-1 ));
% if sum( inYearRecords ) < ( nRows - 1 );
%     inYearIdx = find( inYearRecords );
%     keep = min( inYearIdx ) : ( max( inYearIdx ) + 1 ) ;
%     tbl = tbl( keep, : );
%     warning( 'Removing data outside of requested year' )
% end
