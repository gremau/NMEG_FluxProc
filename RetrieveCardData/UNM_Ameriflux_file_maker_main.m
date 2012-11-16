function result = UNM_Ameriflux_file_maker_main( sitecode, ...
                                                 year, ...
                                                 job_num, ...
                                                 varargin )
% UNM_AMERIFLUX_FILE_MAKER_MAIN - Top level function to create Ameriflux files.
%   Assumes that the online flux gapfiller/partitioner has run and the results
%   are ready to download, but have not been downloaded yet.  This function
%   downloads the gapfiller/partitioner results and creates gapfilled,
%   with_gaps, and soil Ameriflux files.

% USAGE
%    result = UNM_Ameriflux_file_maker_main( sitecode, year, job_num, ... )
%
% KEYWORD ARGUMENTS:
%    write_files: logical; if false, do not write the Ameriflux files (useful
%        for debugging without writing over good ameriflux files)
%    process_soil_data: logical; if false, do not produce soil file
%
% Timothy W. Hilton, UNM, Dec 2011 - Jan 2012

%-----
% parse arguments
args = inputParser;
args.addRequired( 'sitecode', @(x) ( isnumeric(x) | isa( x, 'UNM_sites' ) ) ); 
args.addRequired( 'year', @isintval );
args.addRequired( 'job_num', @isintval );
args.addParamValue( 'write_files', true, @(x) ( islogical(x) & ...
                                                numel( x ) ==  1 ) );
args.addParamValue( 'process_soil_data', true, @(x) ( islogical(x) & ...
                                                  numel( x ) ==  1 ) );
args.parse( sitecode, year, job_num, varargin{ : } );
% -----

download_gapfilled_partitioned_flux( args.Results.job_num );

UNM_Ameriflux_file_maker_TWH( args.Results.sitecode, ...
                              args.Results.year, ...
                              varargin{ : } );
