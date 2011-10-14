function result = flux_raw_diagnostic_plot(fluxraw, site, mod_date)
% FLUX_RAW_DIAGNOSTIC_PLOT - makes diagnostic plots of each variable from a
%   Campbell Scientific datalogger *.flux.dat 30-minute file
    
    nvar = length(fluxraw.Properties.VarNames);
    
    psname = fullfile(getenv('PLOTDEPOT'), ...
                      sprintf('%s_%s_flux_raw.ps', site, ...
                              datestr(mod_date, 'YYYY-mm-dd')));

    Fc_wpl_idx = find(strcmp(fluxraw.Properties.VarNames, 'Fc_wpl'));
    this_fig = figure();
    plot(fluxraw.record_num, fluxraw.Fc_wpl, '.k');
    ylim([-50, 50]);
    xlabel('record number');
    ylabel(sprintf('%s (%s)', 'Fc\_wpl', fluxraw.Properties.Units{Fc_wpl_idx}));
    title(sprintf('%s %s', strrep(site, '_', '\_'), mod_date));
    print('-dpsc2', psname, sprintf('-f%d', this_fig));
    waitforbuttonpress;
    

    for i=1:10
        this_var = fluxraw.Properties.VarNames{i};
        this_units = fluxraw.Properties.Units{i};
        plot(fluxraw.record_num, ...
             fluxraw.(this_var), ...
             '.k');
        xlabel('record number');
        ylabel(sprintf('%s (%s)', strrep(this_var, '_', '\_'), this_units));
        title(sprintf('%s %s', strrep(site, '_', '\_'), mod_date));
        print('-dpsc2', psname, '-append', '-loose', sprintf('-f%d', this_fig));
        waitforbuttonpress();
    end

    pdfname = strrep(psname, '.ps', '.pdf');
    ps2pdf('psfile', psname, ...
           'pdffile', pdfname, ...
           'deletepsfile', 1);
    
    [result, msg] = system('which pdfcrop');
    if result == 0
        system(sprintf('pdfcrop %s %s', pdfname, pdfname));
    end