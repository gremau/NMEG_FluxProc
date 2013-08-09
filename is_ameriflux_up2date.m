function up2date = is_ameriflux_up2date( sitecode, year )
% IS_AMERIFLUX_UP2DATE - Utility to check whether the ameriflux file for a
% specified siteyear was produced from the most recently processed flux
% files. Returns true if the Ameriflux file for the siteyear is up to date,
% false otherwise.  The Ameriflux file is "up to date" if the modification times
% of the precursor files satisfy:
% 
% most recent
% -----------
%
% ameriflux file
%     |
% DataSetafterFluxPartGL2010_YYYY.txt, DataSetafterFluxPart_YYYY.txt
%     |
% flux_all_YYYY_for_gap_filling_filled.txt
%     |
% flux_all_YYYY_for_gap_filling.txt
%
% ------------
% least recent
%
% If any of the files do not satisfy that order (or do not exist), all five
% file names and their modification dates are written to stdout.
%
% USAGE
%    up2date = is_ameriflux_up2date( sitecode, year );
%
% INPUTS: 
%    sitecode: UNM_sites object
%    year: four digit year
%
% OUTPUTS
%    up2date: true|false; true if files are up to date
%
% SEE ALSO
%    dataset
%
% author: Timothy W. Hilton, UNM, May 2012

site_info = parse_UNM_site_table();

%-----
% build the file names
fname_ameriflux = fullfile( get_out_directory( sitecode ), ...
                            sprintf( '%s_%d_with_gaps.txt', ...
                                     site_info.Ameriflux{ sitecode }, ...
                                     year ) );

fname_GL = fullfile( get_site_directory( sitecode ), ...
                     'processed_flux', ...
                     sprintf( 'DataSetafterFluxpartGL2010_%d.txt', year ) );

fname_MR = fullfile( get_site_directory( sitecode ), ...
                     'processed_flux', ...
                     sprintf( 'DataSetafterFluxpart_%d.txt', year ) );

fmt = '%s_flux_all_%d_for_gap_filling_filled.txt';
fname_forgap_filled = fullfile( get_site_directory( sitecode ), ...
                                'processed_flux', ...
                                sprintf( fmt, ...
                                         get_site_name( sitecode ), year ) );

fmt = '%s_flux_all_%d_for_gap_filling.txt';
fname_forgap = fullfile( get_site_directory( sitecode ), ...
                         'processed_flux', ...
                         sprintf( fmt, ...
                                  get_site_name( sitecode ), year ) );

%-----
% check that the files exist, read modification timestamps
file_names = { fname_ameriflux, fname_GL, fname_MR, fname_forgap_filled, ...
              fname_forgap };

file_info = cellfun( @dir, file_names, 'UniformOutput', false );
file_dates = cellfun( @(x) datenum( x.date, 'dd-mmm-yyyy HH:MM:SS' ),  ...
                      file_info );

%-----
% are modification dates in the proper order?
if any( diff( file_dates ) > 0 )
    for i = 1:numel( file_names )
        fprintf( '%s\t%s\n', file_info{ i }.date, file_info{ i }.name );
    end
else
    fprintf( '%s %d is up to date\n', site_info.Ameriflux{ sitecode }, year );
end

