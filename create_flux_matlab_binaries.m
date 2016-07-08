function success = create_flux_matlab_binaries( ameriflux, fluxall )
% CREATE_FLUX_MATLAB_BINARIES - create matlab binary .mat files for all UNM
% site-years for Ameriflux files or fluxall files.
%
% These binary files load into matlab much more quickly than their text
% representations.
%
% USAGE
%   success = create_flux_matlab_binaries( ameriflux, fluxall );
%
% INPUTS
%   ameriflux: true|false; if true, create binaries for Ameriflux files.
%   fluxall: true|false; if true, create binaries for fluxall files.
%
% OUTPUTS
%   success: true|false; true if all requested binary files are created
%       successfully, false otherwise.
%
% 
% author: Timothy W. Hilton, UNM, July 2012
success = true;

[ this_year, ~, ~, ~, ~, ~ ] = datevec( now() );

all_sites = [ UNM_sites.GLand, UNM_sites.SLand, UNM_sites.JSav, UNM_sites.PJ, ...
              UNM_sites.PPine, UNM_sites.MCon, UNM_sites.PJ_girdle, ...
              UNM_sites.New_GLand, UNM_sites.MCon_SS, UNM_sites.TestSite ];

for this_site = all_sites
    for year = 2007:this_year
        fprintf( '%s %d\n', char( this_site ), year );
        if ameriflux            
            % Ameriflux binaries
            update_combined_mat_file = false; 
            
            for suffix = { 'gapfilled', 'with_gaps' }
                ascii_fname = get_ameriflux_filename( this_site, ...
                                                      year, ...
                                                      suffix{ 1 } );
                binary_fname = fullfile( getenv( 'FLUXROOT' ), ...
                                         'FluxOut', ...
                                         'BinaryData', ...
                                         sprintf( '%s_%d_%s.mat', ...
                                                  char( this_site ), ...
                                                  year, ...
                                                  suffix{ 1 } ) );
                
                [ this_success, wrote_file ] = ...
                    write_binary_if_necessary( this_site, ...
                                               year, ...
                                               ascii_fname, ...
                                               binary_fname );
                sucess = success & this_success;
                update_combined_mat_file = update_combined_mat_file | wrote_file;
            end
            
            if update_combined_mat_file & ( year == this_year )
                % if any of the site-years were updated, write a new combined 
                % file
                this_data = assemble_multi_year_ameriflux( this_site, ...
                                                           2006:this_year );
                fname = fullfile( getenv( 'FLUXROOT' ), ...
                                  'FluxOut', ...
                                  'BinaryData', ...
                                  sprintf( '%s_all_%s.mat', ...
                                           char( this_site ), ...
                                           suffix{ 1 } ) );
                fprintf( 'saving %s\n', fname );
                save( fname, 'this_data' );
            end
                                
        end
        
        if fluxall
            if year < this_year
                ext = 'xls';
            else
                ext = 'txt';
            end
            fluxall_fname = fullfile( getenv( 'FLUXROOT' ), ...
                                      'SiteData', ...
                                      char( this_site ), ...
                                      sprintf( '%s_FLUX_all_%d.%s', ...
                                               char( this_site ), ...
                                               year, ...
                                               ext ) );
            fluxall_binary_fname = fullfile( getenv( 'FluxRoot' ), ...
                                             'FluxOut', ...
                                             'BinaryData', ...
                                             sprintf( '%s_%d_fluxall.mat', ...
                                                      char( this_site ), ...
                                                      year ) );
            
            [ this_success, wrote_file ] = ...
                write_binary_if_necessary( this_site, ...
                                           year, ...
                                           fluxall_fname, ...
                                           fluxall_binary_fname );
            success = success & this_success;
            
        end
    end
end

%--------------------------------------------------            
function [ success, wrote ] = write_binary_if_necessary(  sitecode, year, ...
                                               orig_fname, binary_fname)
% WRITE_BINARY_IF_NECESSARY - write single-year binary file if it does not
% exist, or exists but is older than the non-binary file that it represents.
%   
% Do nothing if binary file exists and is newer than the non-binary file.
%
% USAGE: 
%     [ success, wrote ] = write_binary_if_necessary( sitecode, year, ...
%                                               orig_fname, binary_fname );
%
% INPUTS: 
%     sitecode: UNM_sites object; specifies the site
%     year: four digit year: specifies the year
%     orig_fname: character string; name of non-binary data file (Ameriflux
%         or fluxall) 
%     binary_fname: character string; name of binary data file to update if
%         necessary 
%
% OUTPUTS
%     success: true|false; true if function complete successfully
%     wrote: true|false; true if new binary file was written, false if not
%

success = false;
wrote = false;

if exist( orig_fname )
    
    % if binary file does not exist, create it
    write_binary_now = not( exist( binary_fname ) );

    % if binary file exists, check that it is up to date
    if not( write_binary_now )
        orig_info = dir( orig_fname );
        t_orig = datenum( orig_info.date );
        binary_info = dir( binary_fname );
        t_binary = datenum( binary_info.date );
        write_binary_now = t_orig > t_binary;
    end

    if write_binary_now 
        fprintf( '\tparsing %s\n', orig_fname );
        if not( isempty( regexpi( orig_fname, 'flux_all', 'once' ) ) )
            this_data = UNM_parse_fluxall_xls_file( int8( sitecode ), year );
        else
            this_data = parse_ameriflux_file( orig_fname );
        end
        fprintf( '\tsaving %s\n', binary_fname );
        save( binary_fname, 'this_data' );
    end
    wrote = write_binary_now;
end

success = true;

            
        