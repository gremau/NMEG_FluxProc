function h_array = UNM_Ameriflux_make_plots(aflx1, aflx2)
% UNM_AMERIFLUX_MAKE_PLOTS - plot data that to be written out to Ameriflux files
%   

    month_divide=linspace(1,17520,13);
    md=cat(1,month_divide,month_divide);
    md2=[5 5 5 5 5 5 5 5 5 5 5 5 5];
    md3=md2.*-1;
    md4=cat(1,md2,md3);

    % use new partitioning

    figure('Name','Fluxes','NumberTitle','off')
    subplot(3,1,1)
    plot(NEE_f,'r.'); hold on
    plot(NEE_obs,'.'); hold on
    plot(md,md4,'k'); hold on
    ylabel('NEE'); %ylim([-20 20])
    legend('Model','Obs')
    subplot(3,1,2)
    plot(GPP_f,'r.'); hold on
    plot(GPP_obs,'.'); hold on
    ylabel('GPP'); %ylim([0 50])
    subplot(3,1,3)
    plot(RE_f,'r.'); hold on
    plot(RE_obs,'.'); hold on
    ylabel('RE'); %ylim([0 50])

    %%

    figure('Name','Cumulative Fluxes','NumberTitle','off')
    subplot(3,1,1)
    plot(cumsum(NEE_f(~isnan(NEE_f))).*0.0216,'r'); hold on
    plot(cumsum(NEE_2(~isnan(NEE_2))).*0.0216,'b'); hold on;
    ylabel('NEE')
    legend('Model','Obs')
    subplot(3,1,2)
    plot(cumsum(GPP_f(~isnan(GPP_f))).*0.0216,'r'); hold on
    plot(cumsum(GPP_2(~isnan(GPP_2))).*0.0216,'b'); hold on;
    ylabel('GPP')
    subplot(3,1,3)
    plot(cumsum(RE_f(~isnan(RE_f))).*0.0216,'r'); hold on
    plot(cumsum(RE_2(~isnan(RE_2))).*0.0216,'b'); hold on;
    ylabel('RE')

    figure('Name','Energy Fluxes','NumberTitle','off')
    subplot(3,1,1)
    plot(H_f,'r.'); hold on
    plot(H_obs,'.'); hold on;
    ylabel('H'); %ylim([-200 1000])
    subplot(3,1,2)
    plot(LE_f,'r.'); hold on
    plot(LE_obs,'.'); hold on;
    ylabel('LE'); %ylim([-200 1000])
    subplot(3,1,3)
    plot(Rg_f,'.');
    ylabel('Rg'); %ylim([0 1500])

    figure('Name','Soil data','NumberTitle','off')
    subplot(3,1,1)
    plot(ground); hold on;
    ylabel('Ground')
    subplot(3,1,2)
    plot(Tsoil_1); hold on;
    ylabel('Soil T')
    subplot(3,1,3)
    plot(SWC_1); hold on;
    ylabel('SWC')

    figure('Name','Met data','NumberTitle','off')
    subplot(2,3,1)
    plot(air_temp_hmp,'.'); hold on;
    ylabel('Air temp')
    subplot(2,3,2)
    plot(wnd_spd,'.'); hold on;
    ylabel('Wnd Spd')
    subplot(2,3,3)
    plot(precip); hold on;
    ylabel('PPT')
    subplot(2,3,4)
    plot(VPD_f,'.'); hold on;
    ylabel('VPD'); %ylim([0 10])
    subplot(2,3,5)
    plot(NR_tot,'.'); hold on;
    ylabel('NR tot')
    subplot(2,3,6)
    plot(Par_Avg,'.'); hold on;
    %    plot(par_down_Avg,'r.');
    ylabel('Par Avg')

    figure('Name','Radiation components','NumberTitle','off')
    subplot(2,2,1)
    plot(sw_incoming,'.'); hold on;
    ylabel('sw incoming')
    subplot(2,2,2)
    plot(sw_outgoing,'.'); hold on;
    ylabel('sw outgoing')
    subplot(2,2,3)
    plot(lw_incoming,'.'); hold on;
    ylabel('lw incoming')
    subplot(2,2,4)
    plot(lw_outgoing,'.'); hold on;
    ylabel('lw outgoing')

    figure('Name','Concentrations','NumberTitle','off')
    subplot(2,2,1)
    plot(CO2_mean,'.'); hold on;
    ylabel('CO2 Mean')
    subplot(2,2,2)
    plot(H2O_mean,'.'); hold on;
    ylabel('H2O mean')
    subplot(2,2,3)
    plot(E_wpl_massman.*18,'.'); hold on;
    ylabel('Water flux')
    subplot(2,2,4)
    plot(atm_press,'.'); hold on;
    ylabel('atm press')

    %    'Is this looking OK?'
    %
    %     pause
    %%
