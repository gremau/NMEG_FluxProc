function fh = plot_siteyear_fingerprint_2x3array( sitecode, year, main_t_str )
% create fingerprint plots in a 2x3 array of panels from gapfilled Ameriflux
% file for site-year.  Plots Rg, RH, T, NEE, LE, H.
% 
% The data to be plotted are obtained from the site-year gapfilled Ameriflux
% file via get_ameriflux_filename and parse_ameriflux_file and are plotted by
% RBD_plot_fingerprints.
%
% USAGE
%   fh = plot_siteyear_fingerprint_2x3array( sitecode, year, main_t_str )
%
% INPUTS:
%     sitecode: UNM_sites object; specifies the site
%     year: four-digit integer; specifies the year
%     main_t_str: character string; main title to appear centered over all
%          six panels
%
% OUTPUTS:
%     fh: handle of the figure created.
%
% SEE ALSO
%     UNM_sites, get_ameriflux_filename, parse_ameriflux_file, RBD_plot_fingerprints
% 
% author: Timothy W. Hilton, UNM, July 2012


this_data = parse_ameriflux_file( ...
    get_ameriflux_filename( int8( sitecode ), ...
                            year, ...
                            'gapfilled' ) );

h = RBD_plot_fingerprints( sitecode, year, ...
                           this_data.DTIME, ...
                           this_data.Rg, this_data.RH, this_data.TA, ...
                           this_data.FC, this_data.LE, this_data.H, ...
                           main_t_str );
