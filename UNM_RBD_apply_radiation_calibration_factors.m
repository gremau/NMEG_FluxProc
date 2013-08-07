function [sw_incoming, sw_outgoing, Par_Avg ] = ...
    UNM_RBD_apply_radiation_calibration_factors( sitecode, year_arg, ...
                                                 decimal_day, ...
                                                 sw_incoming, sw_outgoing, ...
                                                 lw_incoming, lw_outgoing, ...
                                                 Par_Avg, NR_tot, ...
                                                 wnd_spd, CNR1TK )
% UNM_RBD_APPLY_RADIATION_CALIBRATION_FACTORS - Some site-years or portions
% thereof contain incorrect calibration factors in their datalogger code.  These
% corrections fix those problems.  This is a helper function for
% UNM_RemoveBadData.  It is not intended to be called on its own.  Input and
% output arguments are defined in UNM_RemoveBadData.
%   
% [sw_incoming, sw_outgoing, Par_Avg ] = ...
%     UNM_RBD_apply_radiation_calibration_factors( sitecode, year_arg, ...
%                                          decimal_day, ...
%                                          sw_incoming, sw_outgoing, ...
%                                          lw_incoming, lw_outgoing, Par_Avg, ...
%                                          NR_tot, wnd_spd, CNR1TK )
%
%
% (c) Timothy W. Hilton, UNM, 2013



%%%%%%%%%%%%%%%%% grassland
switch sitecode
  case UNM_sites.GLand
    if year_arg == 2007
        
        % calibration and unit conversion into W per m^2 for CNR1 variables
        % >> for first couple of weeks the program had one incorrect
        % conversion factor (163.66)
        sw_incoming(find(decimal_day > 156.71 & decimal_day < 162.52)) = sw_incoming(find(decimal_day > 156.71 & decimal_day < 162.52))./163.66.*(1000./8.49);
        sw_outgoing(find(decimal_day > 156.71 & decimal_day < 162.52)) = sw_outgoing(find(decimal_day > 156.71 & decimal_day < 162.52))./163.66.*(1000./8.49);
        lw_incoming(find(decimal_day > 156.71 & decimal_day < 162.52)) = lw_incoming(find(decimal_day > 156.71 & decimal_day < 162.52))./163.66.*(1000./8.49);
        lw_outgoing(find(decimal_day > 156.71 & decimal_day < 162.52)) = lw_outgoing(find(decimal_day > 156.71 & decimal_day < 162.52))./163.66.*(1000./8.49);
        % then afterward it had a different one (136.99)
        sw_incoming(find(decimal_day > 162.67)) = sw_incoming(find(decimal_day > 162.67)).*(1000./8.49)./136.99;
        sw_outgoing = sw_outgoing.*(1000./8.49)./136.99;
        lw_incoming = lw_incoming.*(1000./8.49)./136.99;
        lw_outgoing = lw_outgoing.*(1000./8.49)./136.99;
        % temperature correction just for long-wave
        lw_incoming = lw_incoming + 0.0000000567.*(CNR1TK).^4;
        lw_outgoing = lw_outgoing + 0.0000000567.*(CNR1TK).^4;

        Par_Avg(find(decimal_day > 162.14)) = Par_Avg(find(decimal_day > 162.14)).*1000./(5.7*0.604);
        % estimate par from sw_incoming
        Par_Avg(find(decimal_day < 162.15)) = sw_incoming(find(decimal_day < 162.15)).*2.025 + 4.715;
        
    elseif year_arg >= 2008
        % calibration correction for the li190
        Par_Avg = Par_Avg.*1000./(5.7*0.604);
        % calibration and unit conversion into W per m^2 for CNR1 variables
        % and adjust for program error
        sw_incoming = sw_incoming./136.99.*(1000./8.49);
        sw_outgoing = sw_outgoing./136.99.*(1000./8.49);
        lw_incoming = lw_incoming./136.99.*(1000./8.49);
        lw_outgoing = lw_outgoing./136.99.*(1000./8.49);
        % temperature correction just for long-wave
        lw_incoming = lw_incoming + 0.0000000567.*(CNR1TK).^4;
        lw_outgoing = lw_outgoing + 0.0000000567.*(CNR1TK).^4;
    end
    
    %%%%%%%%%%%%%%%%% shrubland 
  case UNM_sites.SLand
    if year_arg == 2007
        
        % calibration and unit conversion into W per m^2 for CNR1 variables
        % >> for first couple of weeks the program had one incorrect
        % conversion factor (163.66)
        sw_incoming(find(decimal_day >= 150.75 & decimal_day < 162.44)) = sw_incoming(find(decimal_day >= 150.75 & decimal_day < 162.44))./163.66.*(1000./12.34);
        sw_outgoing(find(decimal_day >= 150.75 & decimal_day < 162.44)) = sw_outgoing(find(decimal_day >= 150.75 & decimal_day < 162.44))./163.66.*(1000./12.34);
        lw_incoming(find(decimal_day >= 150.75 & decimal_day < 162.44)) = lw_incoming(find(decimal_day >= 150.75 & decimal_day < 162.44))./163.66.*(1000./12.34);
        lw_outgoing(find(decimal_day >= 150.75 & decimal_day < 162.44)) = lw_outgoing(find(decimal_day >= 150.75 & decimal_day < 162.44))./163.66.*(1000./12.34);
        % >> then afterward it had a different one (136.99)
        sw_incoming(find(decimal_day > 162.44)) = sw_incoming(find(decimal_day > 162.44))./136.99.*(1000./12.34); % adjust for program error and convert into W per m^2
        sw_outgoing = sw_outgoing./136.99.*(1000./12.34); % adjust for program error and convert into W per m^2
        lw_incoming = lw_incoming./136.99.*(1000./12.34); % adjust for program error and convert into W per m^2
        lw_outgoing = lw_outgoing./136.99.*(1000./12.34); % adjust for program error and convert into W per m^2        
        lw_incoming = lw_incoming + 0.0000000567.*(CNR1TK).^4; % temperature correction just for long-wave        
        lw_outgoing = lw_outgoing + 0.0000000567.*(CNR1TK).^4; % temperature correction just for long-wave 
        
        % calibration correction for the li190
        Par_Avg(find(decimal_day > 150.729)) = Par_Avg(find(decimal_day > 150.729)).*1000./(6.94*0.604);
        % estimate par from sw_incoming
        Par_Avg(find(decimal_day < 150.729)) = sw_incoming(find(decimal_day < 150.729)).*2.0292 + 3.6744;
        
    elseif year_arg >= 2008
        % calibration and unit conversion into W per m^2 for CNR1 variables
        % adjust for program error and convert into W per m^2
        sw_incoming = sw_incoming./136.99.*(1000./12.34);
        sw_outgoing = sw_outgoing./136.99.*(1000./12.34);
        lw_incoming = lw_incoming./136.99.*(1000./12.34);
        lw_outgoing = lw_outgoing./136.99.*(1000./12.34);
        % temperature correction just for long-wave
        lw_incoming = lw_incoming + 0.0000000567.*(CNR1TK).^4;
        lw_outgoing = lw_outgoing + 0.0000000567.*(CNR1TK).^4;
        % calibration correction for the li190
        Par_Avg = Par_Avg.*1000./(6.94*0.604);
    end

    %%%%%%%%%%%%%%%%% juniper savanna
  case UNM_sites.JSav
    if year_arg == 2007
        % calibration and unit conversion into W per m^2 for CNR1 variables
        sw_incoming = sw_incoming./163.666.*(1000./6.9); % convert into W per m^2
        sw_outgoing = sw_outgoing./163.666.*(1000./6.9); % convert into W per m^2
        lw_incoming = lw_incoming./163.666.*(1000./6.9); % convert into W per m^2
        lw_outgoing = lw_outgoing./163.666.*(1000./6.9); % convert into W per m^2        
        lw_incoming = lw_incoming + 0.0000000567.*(CNR1TK).^4; % temperature correction just for long-wave
        lw_outgoing = lw_outgoing + 0.0000000567.*(CNR1TK).^4; % temperature correction just for long-wave
                                                               % calibration for par-lite
        Par_Avg = Par_Avg.*1000./5.48;
    elseif year_arg >= 2008
        % calibration and unit conversion into W per m^2 for CNR1 variables
        sw_incoming = sw_incoming./163.666.*(1000./6.9); % convert into W per m^2
        sw_outgoing = sw_outgoing./163.666.*(1000./6.9); % convert into W per m^2
        lw_incoming = lw_incoming./163.666.*(1000./6.9); % convert into W per m^2
        lw_outgoing = lw_outgoing./163.666.*(1000./6.9); % convert into W per m^2        
        lw_incoming = lw_incoming + 0.0000000567.*(CNR1TK).^4; % temperature correction just for long-wave
        lw_outgoing = lw_outgoing + 0.0000000567.*(CNR1TK).^4; % temperature correction just for long-wave
                                                               % calibration for par-lite
        Par_Avg = Par_Avg.*1000./5.48;
    end
    
    % all cnr1 variables for jsav need to be (value/163.666)*144.928

    %%%%%%%%%%%%%%%%% pinyon juniper
  case UNM_sites.PJ
    if year_arg == 2007

        % this is the wind correction factor for the Q*7
        NR_tot(find(NR_tot < 0)) = NR_tot(find(NR_tot < 0)).*10.74.*((0.00174.*wnd_spd(find(NR_tot < 0))) + 0.99755);
        NR_tot(find(NR_tot > 0)) = NR_tot(find(NR_tot > 0)).*8.65.*(1 + (0.066.*0.2.*wnd_spd(find(NR_tot > 0)))./(0.066 + (0.2.*wnd_spd(find(NR_tot > 0)))));
        
        % now correct pars
        Par_Avg = NR_tot.*2.7828 + 170.93; % see notes on methodology (PJ) for this relationship
        sw_incoming = Par_Avg.*0.4577 - 1.8691; % see notes on methodology (PJ) for this relationship

    elseif year_arg == 2008
        % this is the wind correction factor for the Q*7
        NR_tot(find(decimal_day < 172 & NR_tot < 0)) = NR_tot(find(decimal_day < 172 & NR_tot < 0)).*10.74.*((0.00174.*wnd_spd(find(decimal_day < 172 & NR_tot < 0))) + 0.99755);
        NR_tot(find(decimal_day < 172 & NR_tot > 0)) = NR_tot(find(decimal_day < 172 & NR_tot > 0)).*8.65.*(1 + (0.066.*0.2.*wnd_spd(find(decimal_day < 172 & NR_tot > 0)))./(0.066 + (0.2.*wnd_spd(find(decimal_day < 172 & NR_tot > 0)))));
        % now correct pars
        Par_Avg(find(decimal_day < 42.6)) = NR_tot(find(decimal_day < 42.6)).*2.7828 + 170.93;
        % calibration for par-lite installed on 2/11/08
        Par_Avg(find(decimal_day > 42.6)) = Par_Avg(find(decimal_day > 42.6)).*1000./5.51;
        sw_incoming(find(decimal_day < 172)) = Par_Avg(find(decimal_day < 172)).*0.4577 - 1.8691;
        
        lw_incoming(find(decimal_day > 171.5)) = lw_incoming(find(decimal_day > 171.5)) + 0.0000000567.*(CNR1TK(find(decimal_day > 171.5))).^4; % temperature correction just for long-wave
        lw_outgoing(find(decimal_day > 171.5)) = ...
            lw_outgoing(find(decimal_day > 171.5)) + 0.0000000567.*(CNR1TK(find(decimal_day > 171.5))).^4; % temperature correction just for long-wave
        hour_0700 = 7 ./ 24;
        hour_1730 = 17.5 / 24;
        frac_day = decimal_day - floor( decimal_day );
        early_year_is_night = ( decimal_day < 42.6 ) & ...
            ( ( frac_day < hour_0700 ) | ( frac_day > hour_1730 ) );
        sw_incoming( early_year_is_night & ( abs( sw_incoming ) > 5 ) ) = NaN;
        sw_outgoing( early_year_is_night & ( abs( sw_incoming ) > 5 ) ) = NaN;
        Par_Avg( early_year_is_night & ( abs( sw_incoming ) > 5 ) ) = NaN;
    elseif year_arg >= 2009
        % calibration for par-lite installed on 2/11/08
        Par_Avg = Par_Avg.*1000./5.51;
        % temperature correction just for long-wave
        lw_incoming = lw_incoming + ( 0.0000000567 .* ( CNR1TK .^ 4 ) );
        lw_outgoing = lw_outgoing + ( 0.0000000567 .* ( CNR1TK .^ 4 ) );
    end

    %%%%%%%%%%%%%%%%% ponderosa pine
  case UNM_sites.PPine
    if year_arg == 2007
        % radiation values apparently already calibrated and unit-converted
        % in progarm for valles sites
        lw_incoming = lw_incoming + 0.0000000567.*(CNR1TK).^4; % temperature correction just for long-wave
        lw_outgoing = lw_outgoing + 0.0000000567.*(CNR1TK).^4; % temperature correction just for long-wave        
        Par_Avg=Par_Avg.*225;  % Apply correct calibration value 7.37, SA190 manual section 3-1
        Par_Avg=Par_Avg+(0.2210.*sw_incoming); % Apply correction to bring in to line with Par-lite from mid 2008 onwards
        
    elseif year_arg == 2008
        % radiation values apparently already calibrated and unit-converted
        % in progarm for valles sites
        lw_incoming = lw_incoming + 0.0000000567.*(CNR1TK).^4; % temperature correction just for long-wave
        lw_outgoing = lw_outgoing + 0.0000000567.*(CNR1TK).^4; % temperature correction just for long-wave        
                                                               % calibration for Licor sesor  
        Par_Avg(1:10063)=Par_Avg(1:10063).*225;  % Apply correct calibration value 7.37, SA190 manual section 3-1
        Par_Avg(1:10063)=Par_Avg(1:10063)+(0.2210.*sw_incoming(1:10063));
        % calibration for par-lite sensor
        Par_Avg(10064:end) = Par_Avg(10064:end).*1000./5.25;
        
    elseif year_arg  >= 2009
        lw_incoming = lw_incoming + 0.0000000567.*(CNR1TK).^4; % temperature correction just for long-wave
        lw_outgoing = lw_outgoing + 0.0000000567.*(CNR1TK).^4; % temperature correction just for long-wave        
                                                               % calibration for par-lite sensor
        Par_Avg = Par_Avg.*1000./5.25;
    end


    
    
    %%%%%%%%%%%%%%%%% mixed conifer
  case UNM_sites.MCon
    if year_arg == 2006 || year_arg == 2007
        % calibration and unit conversion into W per m^2 for CNR1 variables
        % cnr1 installed and working on 8/1/08
        %         sw_incoming(find(decimal_day > 214.75)) = sw_incoming(find(decimal_day > 214.75)).*(1000./9.96); % convert into W per m^2
        %         sw_outgoing(find(decimal_day > 214.75)) = sw_outgoing(find(decimal_day > 214.75)).*(1000./9.96); % convert into W per m^2
        %         lw_incoming(find(decimal_day > 214.75)) = lw_incoming(find(decimal_day > 214.75)).*(1000./9.96); % convert into W per m^2
        %         lw_outgoing(find(decimal_day > 214.75)) = lw_outgoing(find(decimal_day > 214.75)).*(1000./9.96); % convert into W per m^2        
        lw_incoming = lw_incoming + 0.0000000567.*(CNR1TK).^4; % temperature correction just for long-wave
        lw_outgoing = lw_outgoing + 0.0000000567.*(CNR1TK).^4; % temperature correction just for long-wave        
        
    elseif year_arg > 2007
        % radiation values apparently already calibrated and unit-converted
        % in progarm for valles sites   
        lw_incoming = lw_incoming + 0.0000000567.*(CNR1TK).^4; % temperature correction just for long-wave
        lw_outgoing = lw_outgoing + 0.0000000567.*(CNR1TK).^4; % temperature correction just for long-wave        
                                                               % calibration for par-lite sensor
        Par_Avg = Par_Avg.*1000./5.65;
        
    end
    
    %%%%%%%%%%%%%%%%% texas
  case UNM_sites.TX
    % calibration for the li-190 par sensor - sensor had many high
    % values, so delete all values above 6.5 first
    switch year_arg
      case 2007
        Par_Avg( Par_Avg > 6.5 ) = NaN;
      case { 2008, 2009 }
        Par_Avg( Par_Avg > 15.0 ) = NaN;
      case 2010
        Par_Avg( Par_Avg > 14.5 ) = NaN;
      case 2012
        Par_Avg( Par_Avg > 14.5 ) = NaN;
    end

    Par_Avg = Par_Avg.*1000./(6.16.*0.604);
    if year_arg == 2007 || year_arg == 2006 || year_arg == 2005
        % wind corrections for the Q*7
        NR_tot(find(NR_tot < 0)) = NR_tot(find(NR_tot < 0)).*10.91.*((0.00174.*wnd_spd(find(NR_tot < 0))) + 0.99755);
        NR_tot(find(NR_tot > 0)) = NR_tot(find(NR_tot > 0)).*8.83.*(1 + (0.066.*0.2.*wnd_spd(find(NR_tot > 0)))./(0.066 + (0.2.*wnd_spd(find(NR_tot > 0)))));

        % pyrronometer corrections
        sw_incoming = sw_incoming.*1000./27.34;
        sw_outgoing = sw_outgoing.*1000./19.39;
    elseif year_arg == 2008 || year_arg == 2009
        % par switch to par-lite on ??

    end
    
    [ ~, ~, ~, hr, ~, ~ ] = datevec( datenum( year_arg, 1, 0 ) + decimal_day );
    isnight = ( Par_Avg < 20.0 ) | ( sw_incoming < 20 );
    isnight = isnight | ( hr >= 22 ) | ( hr <= 5 );
    %remove nighttime Rg and RgOut values outside of [ -5, 5 ] added 15 Jun 2013 in
    % response to problems noted by Sebastian Wolf
    sw_incoming( isnight & ( abs( sw_incoming ) > 10 ) ) = NaN;
    sw_outgoing( isnight & ( abs( sw_outgoing ) > 10 ) ) = NaN;
    Par_Avg( isnight & ( abs( Par_Avg ) > 10 ) ) = NaN;
    
  case UNM_sites.TX_forest
    % for TX forest 2009, there was no PAR observation in the fluxall file on
    % 15 Mat 2012.  We substituted in PAR from the TX savana site. --  TWH &
    % ML
    if year_arg == 2009
        Par_Avg(find(Par_Avg > 13.5)) = NaN;
        Par_Avg = Par_Avg.*1000./(6.16.*0.604);
    end
    

    % nothing for TX_grassland for now
    
  case UNM_sites.SevEco
    % temperature correction just for long-wave
    lw_incoming = lw_incoming + ( 0.0000000567 .* ( CNR1TK .^ 4 ) );
    lw_outgoing = lw_outgoing + ( 0.0000000567 .* ( CNR1TK .^ 4 ) );
    % recalculate net radiation with T-adjusted longwave
    
    %%%%%%%%%%%%%%%%% New Grassland
  case UNM_sites.New_GLand
    % calibration correction for the li190
    Par_Avg = Par_Avg.*1000./(5.7*0.604);
    % calibration and unit conversion into W per m^2 for CNR1 variables
    % and adjust for program error
    sw_incoming = sw_incoming./136.99.*(1000./8.49);
    sw_outgoing = sw_outgoing./136.99.*(1000./8.49);
    lw_incoming = lw_incoming./136.99.*(1000./8.49);
    lw_outgoing = lw_outgoing./136.99.*(1000./8.49);
    % temperature correction just for long-wave
    lw_incoming = lw_incoming + 0.0000000567.*(CNR1TK).^4;
    lw_outgoing = lw_outgoing + 0.0000000567.*(CNR1TK).^4;
end

% remove negative Rg_out values
sw_outgoing( sw_outgoing < -50 ) = NaN;

isnight = ( Par_Avg < 20.0 ) | ( sw_incoming < 20 );
%remove nighttime Rg and RgOut values outside of [ -5, 5 ]
% added 13 May 2013 in response to problems noted by Bai Yang
sw_incoming( isnight & ( abs( sw_incoming ) > 5 ) ) = NaN;
sw_outgoing( isnight & ( abs( sw_outgoing ) > 5 ) ) = NaN;
