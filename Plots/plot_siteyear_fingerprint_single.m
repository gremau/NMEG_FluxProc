function fh = plot_siteyear_fingerprint_single( sitecode, year, var, varargin )
% PLOT_SITEYEAR_FINGERPRINT_SINGLE: wrapper for plot_fingerprint for a
% specific site-year and variable.
%
% The data to be plotted are obtained from the site-year gapfilled Ameriflux
% file via get_ameriflux_filename and parse_ameriflux_file and are plotted by
% plot_fingerprint.
%
% USAGE 
%     fh = plot_siteyear_fingerprint_single( sitecode, year, var, varargin );
%
% INPUTS
%     sitecode: UNM_sites object; specifies the site
%     year: four-digit integer; specifies the year
%     var: character string: the variable to be plotted (from Ameriflux file
%         column headers)
%     varargin: these arguments are passed directly to plot_fingerprint
%
% OUTPUTS
%     fh: handle to the figure created.
%
% SEE ALSO
%     UNM_sites, get_ameriflux_filename, parse_ameriflux_file, plot_fingerprint
%
% author: Timothy W. Hilton, UNM, July 2012

this_data = parse_ameriflux_file( ...
    get_ameriflux_filename( int8( sitecode ), ...
                            year, ...
                            'gapfilled' ) );

fh = plot_fingerprint( this_data.DTIME, ...
                       this_data.( var ), ...
                       sprintf( '%s %d %s', char( sitecode ), year, var ), ...
                       varargin{ : });
