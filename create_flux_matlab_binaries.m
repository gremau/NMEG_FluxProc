function create_flux_matlab_binaries( ameriflux, fluxall )
% CREATE_FLUX_MATLAB_BINARIES - create matlab binary .mat files for all UNM
%   site-years for Ameriflux files or fluxall files.  These files load into
%   matlab more quickly than their text representations.

all_sites = [ UNM_sites.GLand, UNM_sites.SLand, UNM_sites.JSav, UNM_sites.PJ, ...
              UNM_sites.PPine, UNM_sites.MCon, UNM_sites.PJ_girdle, ...
              UNM_sites.New_GLand ];

for this_site = all_sites
    for year = 2006:2011
        % Ameriflux binaries
        for suffix = { 'gapfilled', 'with_gaps' }
            ascii_fname = get_ameriflux_filename( this_site, ...
                                                  year, ...
                                                  suffix{ 1 } );
            binary_fname = fullfile( getenv( 'FluxRoot' ), ...
                                     'FluxOut', ...
                                     'BinaryData', ...
                                     sprintf( '%s_%d_%s.mat', ...
                                              char( this_site ), ...
                                              year, ...
                                              suffix{ 1 } ) );
            
            success = write_binary_if_necessary( ascii_fname, binary_fname );
            
        end 
            
        if year < 2012
            ext = '.xls';
        else
            ext = '.txt';
        end
        fluxall_fname = fullfile( getenv( 'FLUXDATA' ), ...
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
        
        write_binary_if_necessary( fluxall_fname, fluxall_binary_fname );
    end
end

%--------------------------------------------------            
function success = write_binary_if_necessary(  orig_fname, binary_fname)
% WRITE_BINARY_IF_NECESSARY - determine whether binary file is older, or binary does not exist
%   


if exist( orig_fname )
    write_binary_now = false;
    if exist( binary_fname )
        % if both files exist compare modification times
        orig_info = dir( orig_fname );
        t_orig = orig_info.date;
        binary_info = dir( binary_fname );
        t_binary = binary_info.date;
        write_binary_now = t_orig > t_binary;
    else
        if write_binary_now 
            this_data = parse_ameriflux_file( orig_fname );
            fprintf( 'saving %s\n', fname );
            %save( this_data, 'file', binary_fname );
        end
    end
end

            
        