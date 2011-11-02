function result = flux_raw_diagnostic_plot_wrapper(this_site, mod_date)
% FLUX_RAW_DIAGNOSTIC_PLOT_WRAPPER - identifies 30-min flux data from card and
%   draws diagnostic plot of all variables
    
    flux_file = ls(fullfile('E:', '*flux.dat'));
    flux_file = fullfile('E:', flux_file);
    fluxraw = toa5_2_dataset(flux_file);
    [result, fname] = flux_raw_diagnostic_plot(fluxraw, this_site, mod_date);
    
    h = warndlg(sprintf('wrote %s.  Press OK to continue', fname));
    waitfor(h)
    
    result = 0;
    
