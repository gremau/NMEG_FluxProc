function [sw_incoming, sw_outgoing, lw_incoming, lw_outgoing, Par_Avg ] = ...
    UNM_RBD_apply_radiation_calibration_factors( sitecode, year_arg, ...
    decimal_day, ...
    sw_incoming, sw_outgoing, ...
    lw_incoming, lw_outgoing, ...
    Par_Avg, NR_tot, ...
    wnd_spd, CNR1TK )
% UNM_RBD_APPLY_RADIATION_CALIBRATION_FACTORS - correct for radiation
% calibration factors that were incorrectly specified in datalogger code at
% various sites and time periods.
%
% Some site-years or portions thereof contain incorrect calibration factors in
% their datalogger code.  These corrections fix those problems.
%
% This is a helper function for UNM_RemoveBadData.  It is not intended to be
% called on its own.  Input and output arguments are defined in
% UNM_RemoveBadData.
%
% [sw_incoming, sw_outgoing, ...
%  lw_incoming, lw_outgoing, Par_Avg ] = ...
%     UNM_RBD_apply_radiation_calibration_factors( sitecode, year_arg, ...
%                                   decimal_day, ...
%                                   sw_incoming, sw_outgoing, ...
%                                   lw_incoming, lw_outgoing, Par_Avg, ...
%                                   NR_tot, wnd_spd, CNR1TK )
%
% INPUTS/OUTPUTS
%     see UNM_RemoveBadData and UNM_RemoveBadData_pre2012
%
% SEE ALSO:
%     UNM_RemoveBadData, UNM_RemoveBadData_pre2012
%
% author: Timothy W. Hilton, UNM, 2013
% modified by: Gregory E. Maurer, UNM, 2015-2016

%%%%%%%%%%%%%%%%% grassland
switch sitecode
    case UNM_sites.GLand
        % Current multiplier for CNR1
        cnr1_sensitivity = 8.49; % from current program
        cnr1_mult = 1000 / cnr1_sensitivity;
        % Pre-2014 multipliers to be corrected
        cnr1_mult_old1 = 163.66;
        cnr1_mult_old2 = 136.99;
        
        % PAR multipliers - see the current datalogger program
        PAR_KZ_new_up_sens = 8.6; % New Par_lite sensor
        PAR_KZ_old_up_sens = 4.9; % Older Par_lite - starting ~5/7/2009
        PAR_KZ_dn_sens = 8.68; % K&Z down
        % PAR_LI_old_sens = 7.7; % LiCor, 2007-5/7/2009 ( Multiply by .604 )
        PAR_LI_old_sens = 5.7; % LiCor, 2007-5/7/2009 ( Multiply by .604 )
        PAR_KZ_new_up_mult = 1000 / PAR_KZ_new_up_sens;
        PAR_KZ_old_up_mult = 1000 / PAR_KZ_old_up_sens;
        PAR_LI_old_mult = 1000 / (PAR_LI_old_sens * .604);
        
        if year_arg == 2007
            % Calibration and unit conversion into W per m^2 for 
            % CNR1 variables and adjust for incorrect cal factor in
            % datalogger program
            % For first couple of weeks the program had one incorrect
            % conversion factor (163.666)
            idx1 = find(decimal_day > 156.71 & decimal_day < 162.52);
            sw_incoming(idx1) = (sw_incoming(idx1) ./ cnr1_mult_old1) .* cnr1_mult;
            sw_outgoing(idx1) = sw_outgoing(idx1) ./ cnr1_mult_old1 .* cnr1_mult;
            lw_incoming(idx1) = lw_incoming(idx1) ./ cnr1_mult_old1 .* cnr1_mult;
            lw_outgoing(idx1) = lw_outgoing(idx1) ./ cnr1_mult_old1 .* cnr1_mult;
            % then afterward it had a different one (136.99)
            idx2 = find(decimal_day >= 162.52);
            sw_incoming(idx2) = sw_incoming(idx2) ./ cnr1_mult_old2 .* cnr1_mult;
            sw_outgoing(idx2) = sw_outgoing(idx2) ./ cnr1_mult_old2 .* cnr1_mult;
            lw_incoming(idx2) = lw_incoming(idx2) ./ cnr1_mult_old2 .* cnr1_mult;
            lw_outgoing(idx2) = lw_outgoing(idx2) ./ cnr1_mult_old2 .* cnr1_mult;
            % temperature correction just for long-wave
            [lw_incoming, lw_outgoing] = lw_correct(lw_incoming, lw_outgoing);
            % Until PAR sensor online, estimate par from sw_incoming
            Par_Avg(find(decimal_day < 162.15)) = ...
                sw_incoming(find(decimal_day < 162.15)).*2.025 + 4.715;
            % After PAR sensor operational use old licor calibration
            Par_Avg(find(decimal_day > 162.14)) = ...
                Par_Avg(find(decimal_day > 162.14)) * PAR_LI_old_mult;
            
        elseif year_arg == 2008
            % Calibration and unit conversion into W per m^2 for 
            % CNR1 variables and adjust for incorrect cal factor in
            % datalogger program
            sw_incoming = sw_incoming ./ cnr1_mult_old2 .* cnr1_mult;
            sw_outgoing = sw_outgoing ./ cnr1_mult_old2 .* cnr1_mult;
            lw_incoming = lw_incoming ./ cnr1_mult_old2 .* cnr1_mult;
            lw_outgoing = lw_outgoing ./ cnr1_mult_old2 .* cnr1_mult;
            % Temperature correction just for long-wave
            [lw_incoming, lw_outgoing] = ...
                lw_correct( lw_incoming, lw_outgoing );
            % I think the LiCor was in use this year
            Par_Avg = Par_Avg * PAR_LI_old_mult;
            
        elseif year_arg >= 2009 & year_arg <= 2013
            % Calibration and unit conversion into W per m^2 for 
            % CNR1 variables and adjust for incorrect cal factor in
            % datalogger program
            sw_incoming = sw_incoming ./ cnr1_mult_old2 .* cnr1_mult;
            sw_outgoing = sw_outgoing ./ cnr1_mult_old2 .* cnr1_mult;
            lw_incoming = lw_incoming ./ cnr1_mult_old2 .* cnr1_mult;
            lw_outgoing = lw_outgoing ./ cnr1_mult_old2 .* cnr1_mult;
            % temperature correction just for long-wave
            [lw_incoming, lw_outgoing] = ...
                lw_correct( lw_incoming, lw_outgoing );
            % Use multiplier for the first K&Z Par_lite sensor since 
            % the PPFD data prior to its install is corrected to it 
            % in combine_PARavg_PARlite.m 
            Par_Avg = Par_Avg .* PAR_KZ_old_up_mult;
            
        elseif year_arg == 2014
            % Calibration added to datalogger programs on 01/17/2014
            idx = find( decimal_day < 17.7 );
            sw_incoming( idx ) = ...
                sw_incoming(idx) ./ cnr1_mult_old2 .* cnr1_mult;
            sw_outgoing( idx ) = ...
                sw_outgoing(idx) ./ cnr1_mult_old2 .* cnr1_mult;
            lw_incoming( idx ) = ...
                lw_incoming(idx) ./ cnr1_mult_old2 .* cnr1_mult;
            lw_outgoing( idx ) = ...
                lw_outgoing(idx) ./ cnr1_mult_old2 .* cnr1_mult;
            % Temperature correction just for long-wave
            % FIXME - drop and use CG3CO vars?
            [lw_incoming, lw_outgoing] = ...
                lw_correct( lw_incoming, lw_outgoing );
            % Calibration correction for the older K & Z PAR sensor.
            Par_Avg( idx ) = Par_Avg( idx ) .* PAR_KZ_old_up_mult;
            
        elseif year_arg == 2015
            % Temperature correction just for long-wave
            % FIXME - drop and use CG3CO vars?
            [lw_incoming, lw_outgoing] = ...
                lw_correct( lw_incoming, lw_outgoing );
        end
        
        %%%%%%%%%%%%%%%%% shrubland
    case UNM_sites.SLand
         % Current multiplier for CNR1
        cnr1_sensitivity = 12.34; % from current program
        cnr1_mult = 1000 / cnr1_sensitivity;
        % Pre-2014 multipliers to be corrected
        cnr1_mult_old1 = 163.666;
        cnr1_mult_old2 = 136.99;
        
        % PAR multipliers - see the current datalogger program
        PAR_KZ_new_up_sens = 8.6; % New Par_lite sensor
        PAR_KZ_old_up_sens = 4.19; % Older Par_lite
        PAR_KZ_dn_sens = 8.36; % Par_lite down
        PAR_LI_old_sens = 6.94; % LiCor, 2007-2009? ( Multiply by .604 )
        PAR_KZ_new_up_mult = 1000 / PAR_KZ_new_up_sens;
        PAR_KZ_old_up_mult = 1000 / PAR_KZ_old_up_sens;
        PAR_LI_old_mult = 1000 / (PAR_LI_old_sens * .604);
        
        if year_arg == 2007
            % Calibration and unit conversion into W per m^2 for 
            % CNR1 variables and adjust for incorrect cal factor in
            % datalogger program
            % For first couple of weeks the program had one incorrect
            % conversion factor (163.666)
            idx1 = find(decimal_day >= 150.75 & decimal_day < 162.44);
            sw_incoming( idx1 ) = sw_incoming( idx1 ) ...
                ./ cnr1_mult_old1 .* cnr1_mult;
            sw_outgoing( idx1 ) = sw_outgoing( idx1 ) ...
                ./ cnr1_mult_old1 .* cnr1_mult;
            lw_incoming( idx1 ) = lw_incoming( idx1 ) ...
                ./ cnr1_mult_old1 .* cnr1_mult;
            lw_outgoing( idx1 ) = lw_outgoing( idx1 ) ...
                ./ cnr1_mult_old1 .* cnr1_mult;
            % then afterward it had a different one (136.99)
            idx2 = find(decimal_day >= 162.44);
            sw_incoming( idx2 ) = sw_incoming( idx2 ) ...
                ./ cnr1_mult_old2 .* cnr1_mult;
            sw_outgoing( idx2 ) = sw_outgoing( idx2 ) ...
                ./ cnr1_mult_old2 .* cnr1_mult;
            lw_incoming( idx2 ) = lw_incoming( idx2 ) ...
                ./ cnr1_mult_old2 .* cnr1_mult;
            lw_outgoing( idx2 ) = lw_outgoing( idx2 ) ...
                ./ cnr1_mult_old2 .* cnr1_mult;
            % There was a strange spike on day 126
            idx = find(decimal_day >= 126.4 & decimal_day < 126.9);
            sw_incoming( idx ) = NaN;
            % temperature correction for long-wave
            [lw_incoming, lw_outgoing] = lw_correct(lw_incoming, lw_outgoing);
            % Estimate par from sw_incoming prior to install of li 190
            Par_Avg(find(decimal_day <= 150.729)) = ...
                sw_incoming(find(decimal_day <= 150.729)).*2.0292 + 3.6744;
            % Calibration correction for the li190
            Par_Avg(find(decimal_day > 150.729)) = ...
                Par_Avg(find(decimal_day > 150.729)) * PAR_LI_old_mult;
            
        elseif year_arg == 2008
            % Calibration and unit conversion into W per m^2 for 
            % CNR1 variables and adjust for incorrect cal factor in
            % dataloger program
            sw_incoming = sw_incoming ./ cnr1_mult_old2 .* cnr1_mult;
            sw_outgoing = sw_outgoing ./ cnr1_mult_old2 .* cnr1_mult;
            lw_incoming = lw_incoming ./ cnr1_mult_old2 .* cnr1_mult;
            lw_outgoing = lw_outgoing ./ cnr1_mult_old2 .* cnr1_mult;
            % Temperature correction just for long-wave
            [lw_incoming, lw_outgoing] = ...
                lw_correct( lw_incoming, lw_outgoing );
            % I think the LiCor was in use this year
            Par_Avg = Par_Avg * PAR_LI_old_mult;
            
        elseif year_arg >= 2009 && year_arg <= 2013
            % Calibration and unit conversion into W per m^2 for 
            % CNR1 variables and adjust for incorrect cal factor in
            % dataloger program
            sw_incoming = sw_incoming ./ cnr1_mult_old2 .* cnr1_mult;
            sw_outgoing = sw_outgoing ./ cnr1_mult_old2 .* cnr1_mult;
            lw_incoming = lw_incoming ./ cnr1_mult_old2 .* cnr1_mult;
            lw_outgoing = lw_outgoing ./ cnr1_mult_old2 .* cnr1_mult;
            % temperature correction just for long-wave
            [lw_incoming, lw_outgoing] = ...
                lw_correct( lw_incoming, lw_outgoing );
            % Use multiplier for the first K&Z Par_lite sensor since 
            % the PPFD data prior to its install is corrected to it 
            % in combine_PARavg_PARlite.m 
            Par_Avg = Par_Avg .* PAR_KZ_old_up_mult;
            
        elseif year_arg == 2014
            % Calibration added to datalogger programs on 01/17/2014
            idx = find( decimal_day < 17.5 );
            sw_incoming( idx ) = ...
                sw_incoming(idx) ./ cnr1_mult_old2 .* cnr1_mult;
            sw_outgoing( idx ) = ...
                sw_outgoing(idx) ./ cnr1_mult_old2 .* cnr1_mult;
            lw_incoming( idx ) = ...
                lw_incoming(idx) ./ cnr1_mult_old2 .* cnr1_mult;
            lw_outgoing( idx ) = ...
                lw_outgoing(idx) ./ cnr1_mult_old2 .* cnr1_mult;
            % Temperature correction just for long-wave
            % FIXME - drop and use CG3CO vars?
            [lw_incoming, lw_outgoing] = ...
                lw_correct( lw_incoming, lw_outgoing );
            % Calibration correction for the older K & Z PAR sensor.
            Par_Avg( idx ) = Par_Avg( idx ) .* PAR_KZ_old_up_mult;
            
            % Fix one spiky period
            idx = decimal_day > 257 & decimal_day < 267 & Par_Avg > 2100;
            Par_Avg(idx) = NaN;
        
        elseif year_arg == 2015
            % Temperature correction just for long-wave
            % FIXME - drop and use CG3CO vars?
            [lw_incoming, lw_outgoing] = ...
                lw_correct( lw_incoming, lw_outgoing );
            % Fix one miswired period
            idx1 = decimal_day > 310.58;
            Par_Avg(idx1) = -Par_Avg(idx1) - 60;
        end
        
        %%%%%%%%%%%%%%%%% juniper savanna
    case UNM_sites.JSav
        % Current multiplier for CNR1
        cnr1_sensitivity = 6.9; % from instrument master list - changes in 2014
        cnr1_mult = 1000 / cnr1_sensitivity;
        % Pre-2014 multiplier to be corrected
        cnr1_mult_old = 163.666;
        
        % PAR multipliers - see the current datalogger program
        PAR_KZ_new_up_sens = 8.97; % New Par_lite sensor
        PAR_KZ_old_up_sens = 5.48; % Older Par_lite
        PAR_KZ_dn_sens = 8.35; % Par_lite down
        PAR_LI_old_sens = 5.75; % LiCor, 2007-2008? ( Multiply by .604 )
        PAR_KZ_new_up_mult = 1000 / PAR_KZ_new_up_sens;
        PAR_KZ_old_up_mult = 1000 / PAR_KZ_old_up_sens;
        PAR_LI_old_mult = 1000 / (PAR_LI_old_sens * .604);
        
        if year_arg == 2007
            % calibration and unit conversion into W per m^2 for CNR1 variables
            % convert into W per m^2
            sw_incoming = sw_incoming ./ cnr1_mult_old .* cnr1_mult;
            sw_outgoing = sw_outgoing ./ cnr1_mult_old .* cnr1_mult;
            lw_incoming = lw_incoming ./ cnr1_mult_old .* cnr1_mult;
            lw_outgoing = lw_outgoing ./ cnr1_mult_old .* cnr1_mult;
            % temperature correction for long-wave
            [lw_incoming, lw_outgoing] = lw_correct(lw_incoming, lw_outgoing);
            % calibration for LiCor PAR
            Par_Avg = Par_Avg .* PAR_LI_old_mult;
            
        elseif year_arg == 2008
            % calibration and unit conversion into W per m^2 for CNR1 variables
            % convert into W per m^2
            sw_incoming = sw_incoming ./ cnr1_mult_old .* cnr1_mult;
            sw_outgoing = sw_outgoing ./ cnr1_mult_old .* cnr1_mult;
            lw_incoming = lw_incoming ./ cnr1_mult_old .* cnr1_mult;
            lw_outgoing = lw_outgoing ./ cnr1_mult_old .* cnr1_mult;
            % temperature correction for long-wave
            [lw_incoming, lw_outgoing] = lw_correct(lw_incoming, lw_outgoing);
            % calibration for LiCor PAR
            idx = decimal_day <= 164.022;
            Par_Avg(idx) = Par_Avg(idx) .* PAR_LI_old_mult;
            % calibration for par-lite
            idx2 = decimal_day > 164.022;
            Par_Avg(idx2) = Par_Avg(idx2) .* PAR_KZ_old_up_mult;
            % Make a small correction for a wierd calibration problem
            % in fall 2008
            idx = decimal_day > 296.5 & decimal_day < 332;
            Par_Avg( idx ) = Par_Avg( idx ) + 133;
            
        elseif year_arg >= 2009 & year_arg <= 2013
            % calibration and unit conversion into W per m^2 for CNR1 variables
            % convert into W per m^2
            sw_incoming = sw_incoming ./ cnr1_mult_old .* cnr1_mult;
            sw_outgoing = sw_outgoing ./ cnr1_mult_old .* cnr1_mult;
            lw_incoming = lw_incoming ./ cnr1_mult_old .* cnr1_mult;
            lw_outgoing = lw_outgoing ./ cnr1_mult_old .* cnr1_mult;
            % temperature correction for long-wave
            [lw_incoming, lw_outgoing] = lw_correct(lw_incoming, lw_outgoing);
            % calibration for par-lite
            Par_Avg = Par_Avg .* PAR_KZ_old_up_mult;
            % Make a small correction for a wierd calibration problem
            % at start of 2009
            if year_arg == 2009
                idx = decimal_day > 20.4 & decimal_day < 33.7;
                Par_Avg( idx ) = Par_Avg( idx ) + 133;
            end
            % Outgoing longwave was messed up for a couple periods in 2013,
            % remove it.
            if year_arg == 2013
                idx1 = decimal_day > 185.6 & decimal_day < 205.65;
                idx2 = decimal_day > 241.45 & decimal_day < 295.5;
                lw_outgoing( idx1 | idx2 ) = NaN;
            end
            
        elseif year_arg == 2014
            % CNR1 was damaged by hail in spring and had to be replaced.
            % Several sensors with different sensitivities were used for
            % the next year (See logs).
            % The calibration thus changed multiple times this year, but
            % this should be accounted for in datalogger programs.

            % Calibration in datalogger programs on 01/10/2014
            idx = find(decimal_day < 10.38);
            sw_incoming(idx) = ...
                sw_incoming(idx) ./ cnr1_mult_old .* cnr1_mult;
            sw_outgoing(idx) = ...
                sw_outgoing(idx) ./ cnr1_mult_old .* cnr1_mult;
            lw_incoming(idx) = ...
                lw_incoming(idx) ./ cnr1_mult_old .* cnr1_mult;
            lw_outgoing(idx) = ...
                lw_outgoing(idx) ./ cnr1_mult_old .* cnr1_mult;
            % Calibration for par-lite
            Par_Avg(idx) = Par_Avg(idx) .* PAR_KZ_old_up_mult;
            % Temperature correction for long-wave
            % FIXME - start using CG3CO variables?
            [lw_incoming, lw_outgoing] = lw_correct(lw_incoming, lw_outgoing );
            % LW outgoing and LW incoming need to be cleaned up
            idx1 = decimal_day > 144.4 & decimal_day < 175.5;
            idx2 = decimal_day >= 175.5 & decimal_day < 211.5;
            lw_incoming( idx1 | idx2 ) = NaN;
            lw_outgoing( idx2 ) = NaN;
            % SW_incoming has some noise
            idx = sw_incoming > 1150;
            sw_incoming( idx ) = NaN;
        elseif year_arg == 2015
            % Temperature correction for long-wave
            % FIXME - start using CG3CO variables?
            [lw_incoming, lw_outgoing] = lw_correct(lw_incoming, lw_outgoing );
        end
        
        %%%%%%%%%%%%%%%%% pinon juniper
    case { UNM_sites.PJ , UNM_sites.TestSite }
        % Current multiplier for CNR1
        cnr1_sensitivity = 9.69; % from current datalogger program
        cnr1_mult = 1000 / cnr1_sensitivity;
        % This multiplier (103.199) appears correct in datalogger program
        
        % PAR multipliers - see the current datalogger program
        PAR_KZ_new_up_sens = 9.06; % New Par_lite sensor
        PAR_KZ_old_up_sens = 5.51; % Older Par_lite
        PAR_KZ_dn_sens = 8.48; % Par_lite down
        PAR_LI_old_sens = 7.27; % LiCor, 2007-2009? ( Multiply by .604 )
        PAR_KZ_new_up_mult = 1000 / PAR_KZ_new_up_sens;
        PAR_KZ_old_up_mult = 1000 / PAR_KZ_old_up_sens;
        PAR_LI_old_mult = 1000 / PAR_LI_old_sens * .604;
        
        if year_arg == 2007
            % this is the wind correction factor for the Q*7
            NR_tot(find(NR_tot < 0)) = NR_tot(find(NR_tot < 0)) ...
                .*10.74.*((0.00174.*wnd_spd(find(NR_tot < 0))) + 0.99755);
            NR_tot(find(NR_tot > 0)) = NR_tot(find(NR_tot > 0)) ...
                .*8.65.*(1 + (0.066.*0.2.*wnd_spd(find(NR_tot > 0))) ...
                ./(0.066 + (0.2.*wnd_spd(find(NR_tot > 0)))));
            % now correct pars; see notes on PJ methodology for this relationship
            Par_Avg = NR_tot.*2.7828 + 170.93;
            sw_incoming = Par_Avg.*0.4577 - 1.8691;
            
        elseif year_arg == 2008
            % CNR1 not functioning until June 19
            preCNR1_idx = decimal_day <= 171.5;
            CNR1idx = find(decimal_day > 171.5);
            % this is the wind correction factor for the Q*7
            NR_idx_1 = find(preCNR1_idx & NR_tot < 0);
            NR_tot(NR_idx_1) = NR_tot(NR_idx_1).*10.74 ...
                .*((0.00174.*wnd_spd(NR_idx_1)) + 0.99755);
            NR_idx_2 = find(preCNR1_idx & NR_tot > 0);
            NR_tot(NR_idx_2) = NR_tot(NR_idx_2).*8.65 ...
                .*(1 + (0.066.*0.2.*wnd_spd(NR_idx_2)) ...
                ./(0.066 + (0.2.*wnd_spd(NR_idx_2))));
            % Now correct pars
            % There doesn't seem to be any NR_tot data prior to day 42, so
            % I am just setting it to NaN - GEM
            Par_Avg(find(decimal_day < 42.6)) = NaN; %...
%                 NR_tot(find(decimal_day < 42.6)).*2.7828 + 170.93;
            % calibration for par-lite installed on 2/11/08
            Par_Avg(find(decimal_day > 42.6)) = ...
                Par_Avg(find(decimal_day > 42.6)) .* PAR_KZ_old_up_mult;
            % Prior to fixed CNR1, estimate SW_IN from PAR
            sw_incoming(find(preCNR1_idx)) = ...
                Par_Avg(find(preCNR1_idx)).*0.4577 - 1.8691;
            % Temperature correction just for long-wave
            [lw_incoming, lw_outgoing] = ...
                lw_correct(lw_incoming, lw_outgoing, CNR1idx);

            %What is this?
%             hour_0700 =  7.0 / 24.0;
%             hour_1730 = 17.5 / 24.0;
%             frac_day = decimal_day - floor( decimal_day );
%             early_year_is_night = ( decimal_day < 42.6 ) & ...
%                 ( ( frac_day < hour_0700 ) | ( frac_day > hour_1730 ) );
%             sw_incoming( early_year_is_night & ( abs( sw_incoming ) > 5 ) ) = NaN;
%             sw_outgoing( early_year_is_night & ( abs( sw_incoming ) > 5 ) ) = NaN;
%             Par_Avg( early_year_is_night & ( abs( sw_incoming ) > 5 ) ) = NaN;
            
        elseif year_arg >= 2009 & year_arg <= 2013
            % Calibrate par-lite installed on 2/11/08
            Par_Avg = Par_Avg .* PAR_KZ_old_up_mult;
            % Temperature correction just for long-wave
            [lw_incoming, lw_outgoing] = lw_correct(lw_incoming, lw_outgoing);
            
        elseif year_arg == 2014
            % Cals added to datalogger programs on 01/10/2014
            % Calibrate par-lite installed on 2/11/08
            Par_Avg(find(decimal_day < 10.6)) = ...
                Par_Avg(find(decimal_day < 10.6)) .* PAR_KZ_old_up_mult;

            % Entire year needs lw temperature correction - GEM
            % FIXME - start using CG3CO vars?
            [lw_incoming, lw_outgoing] = lw_correct(lw_incoming, lw_outgoing);
        elseif year_arg == 2015
            % FIXME - start using CG3CO vars?
            [lw_incoming, lw_outgoing] = lw_correct(lw_incoming, lw_outgoing);
        end
        
        %%%%%%%%%%%%%%%%% pj girdle
    case UNM_sites.PJ_girdle
        % Current multiplier for CNR1
        cnr1_sensitivity = 10.25; % from current datalogger program
        cnr1_mult = 1000 / cnr1_sensitivity;
        % This multiplier (97.561) was pretty close, but not exactly
        % correct in old datalogger program (was about 100)
        
        % PAR multipliers - see the current datalogger program
        PAR_KZ_up_sens = 5.8; % Par_lite sensor up
        PAR_LI_dn_sens = 7.37; % Licor down ( Multiply by .604 )
        PAR_KZ_up_mult = 1000 / PAR_KZ_up_sens;
        PAR_LI_dn_mult = 1000 / PAR_LI_dn_sens * .604;
        
        % Correct longwave
        if year_arg==2009
            % Temperature correction happened correctly for the first part
            % of 2009, but not for the second part.
            idx = decimal_day > 113.5 & decimal_day <= 366.0;
            [lw_incoming, lw_outgoing] = ...
                lw_correct(lw_incoming, lw_outgoing, idx );
        elseif year_arg==2014
            [lw_incoming, lw_outgoing] = lw_correct(lw_incoming, lw_outgoing);
            % Fix some strange PAR drops in 2014
            idx = decimal_day > 50 & decimal_day < 77 & Par_Avg < -1;
            Par_Avg( idx ) = NaN;
        else
            [lw_incoming, lw_outgoing] = lw_correct(lw_incoming, lw_outgoing);
        end
        
        % Apply a linear correction to lw_incoming because the sensor is
        % off a little from the PJ control site
        if year_arg == 2009
            slp = 0.91; % Slope from analysis of 2009-2013 data
            icpt = 39.714; % Intercept from analysis of 2009-2013 data
        elseif year_arg == 2010
            slp = 0.92;
            icpt = 36.688;
        elseif year_arg == 2011
            slp = 0.918;
            icpt = 37.696;
        elseif year_arg == 2012
            slp = 0.925;
            icpt = 35.944;
        elseif year_arg == 2013
            slp = 0.899;
            icpt = 34.387;
        else % Otherwise use an average of the other years
            slp = 0.914;
            icpt = 36.8858;
        end
        lw_incoming = linfit_var(lw_incoming, slp, icpt);
        
        % FIXME Note for 2016 - there is a period of incorrect calibration
        % from 22-1-2016 until 18-3-2016. Need to put them in here!
        
        %%%%%%%%%%%%%%%%% ponderosa pine
    case UNM_sites.PPine
        % Multipliers for CNR1
        % A CNR1 was damaged, removed 11/13/12 for repair, 
        % prior to repair sensitivity = 6.11
        cnr1_mult_old = 1000 / 6.11;
        % The more recent CNR1 (recalibrated, and reinstalled 5/02/13)
        % had sensitivity of 7.0
        cnr1_mult = 1000 / 7.0;
        % I think the dates on these installs/calibrations and the
        % application of the correct multipliers has been lost and mixed up
        % over the years (Not much in logs). I try to correct it, but I
        % have fairly low confidence that it is correct. GEM
        
        % There was also a CNR2 briefly (see below in 2012 case for 
        % details)
        %
        % Final note - the lw_incoming (up) on the CNR1 was broken for many
        % years, beginning in summer 2007. Daytime longwave_in is removed
        % here and it can be filled in with modeled radiation.
        % (maybe model lw incoming based on air T? Look up 
        % Brutsaert method and some Marks/Dozier papers).

        % PAR multipliers - see the current datalogger program
        PAR_KZ_new_up_sens = 8.69; % New Par_lite sensors
        PAR_KZ_new_dn_sens = 8.37;
        PAR_KZ_old_up_sens = 5.25; % Older Par_lite
        PAR_LI_old_sens = 6.75; % Licor down ( Multiply by .604 )
        PAR_KZ_old_up_mult = 1000 / PAR_KZ_old_up_sens;
        PAR_LI_old_mult = 1000 / (PAR_LI_old_sens * .604);
        
        % NOTE: For the most part PPine radiation values are calibrated and
        % unit converted in the datalogger programs, but they should be
        % checked
        
        if year_arg == 2007
            % daytime lw_incoming failed after July - remove it
            idx = decimal_day > 200.45 & sw_incoming > 25;
            lw_incoming( idx ) = nan;
            idx = decimal_day > 200.45 & lw_incoming > 5;
            lw_incoming( idx ) = nan;

            % temperature correction just for long-wave
            [lw_incoming, lw_outgoing] = lw_correct(lw_incoming, lw_outgoing);
            % Apply correct calibration value 7.37, SA190 manual section 3-1
            Par_Avg  = Par_Avg .* PAR_LI_old_mult;
            
        elseif year_arg == 2008
            % daytime lw_incoming failed this year - remove it
            idx = lw_incoming > 5 | sw_incoming > 25;
            lw_incoming( idx ) = nan;
            % temperature correction just for long-wave
            [lw_incoming, lw_outgoing] = lw_correct(lw_incoming, lw_outgoing);
            % calibration for Licor sesor
            idx = decimal_day > 99.5 & decimal_day < 190.5;
            Par_Avg( idx ) = NaN;
            idx = decimal_day > 210 & decimal_day < 223;
            Par_Avg( idx ) = NaN;
            % Apply correct calibration value 7.37, SA190 manual section 3-1
            idx = decimal_day < 224.75;
            Par_Avg( idx ) = Par_Avg( idx ) .* PAR_LI_old_mult;
            % calibration for par-lite sensor
            idx = decimal_day >= 224.75;
            Par_Avg( idx ) = Par_Avg( idx ) .* PAR_KZ_old_up_mult; 

        elseif year_arg >= 2009 & year_arg <= 2012
            % daytime lw_incoming failed this year - remove it
            idx = lw_incoming > 5 | sw_incoming > 25;
            lw_incoming( idx ) = nan;
            % CNR1 multiplier was good in these years
            [lw_incoming, lw_outgoing] = lw_correct(lw_incoming, lw_outgoing);
            Par_Avg = Par_Avg .* PAR_KZ_old_up_mult;
            
            % NOTE that there was a CNR2 installed here in late 2012
            % through mid 2013 that never seemed to work.
            
        elseif year_arg == 2013
            % CNR1 calibration factor was wrong from 11/19/2013 through 
            % 01/15/2014 (it was the old one).
            idx = decimal_day > 323.7 & decimal_day <= 366.0;
            sw_incoming( idx ) = ...
                sw_incoming( idx ) / cnr1_mult_old * cnr1_mult;
            lw_incoming( idx ) = ...
                lw_incoming( idx ) / cnr1_mult_old * cnr1_mult;
            sw_outgoing( idx ) = ...
                sw_outgoing( idx ) / cnr1_mult_old * cnr1_mult;
            lw_outgoing( idx ) = ...
                lw_outgoing( idx ) / cnr1_mult_old * cnr1_mult;
            
            [lw_incoming, lw_outgoing] = lw_correct(lw_incoming, lw_outgoing);
            % Cal applied in program after Dec 28
            idx =  decimal_day < 362.5;
            Par_Avg( idx ) = Par_Avg( idx ) .* PAR_KZ_old_up_mult;
            
        elseif year_arg == 2014
            % CNR1 calibration factor was wrong from 05/02/2013 through 
            % 01/15/2014 (it was the old one).
            idx = decimal_day > 0.0 & decimal_day <= 15.6;
            sw_incoming( idx ) = ...
                sw_incoming( idx ) / cnr1_mult_old * cnr1_mult;
            lw_incoming( idx ) = ...
                lw_incoming( idx ) / cnr1_mult_old * cnr1_mult;
            sw_outgoing( idx ) = ...
                sw_outgoing( idx ) / cnr1_mult_old * cnr1_mult;
            lw_outgoing( idx ) = ...
                lw_outgoing( idx ) / cnr1_mult_old * cnr1_mult;
            % Temp-correct longwave
            % FIXME - should we just use CG3co values?
            [lw_incoming, lw_outgoing] = lw_correct(lw_incoming, lw_outgoing);
        elseif year_arg == 2015
            % Temp-correct longwave
            % FIXME - should we just use CG3co values?
            [lw_incoming, lw_outgoing] = lw_correct(lw_incoming, lw_outgoing);
        end
        
        %%%%%%%%%%%%%%%%% mixed conifer
    case UNM_sites.MCon
        % Current multiplier for CNR1
        cnr1_sensitivity = 9.96;
        cnr1_mult = 1000 / cnr1_sensitivity;

        % PAR multipliers - see the current datalogger program
        PAR_KZ_new_up_sens = 8.17; % New Par_lite sensors
        PAR_KZ_new_dn_sens = 8.74;
        PAR_KZ_old_up_sens = 5.65; % Older Par_lite
        PAR_LI_old_dn_sens = 6.33; % Licor down ( Multiply by .604 )
        
        PAR_KZ_old_up_mult = 1000 / PAR_KZ_old_up_sens;
        PAR_LI_old_dn_mult = 1000 / PAR_LI_old_dn_sens * .604;
        
        % NOTE: For the most part MCon radiation values are calibrated and
        % unit converted in the datalogger programs, but they should be
        % checked
        
        if year_arg >= 2006 & year_arg <= 2008
            % No idea if this is the correct "old" multiplier, just trying
            % to make data match with 2009 forward - GEM
            cnr1_mult_old = 1000/11.0;
            idx = decimal_day > 115;
            sw_incoming(idx) = ...
                sw_incoming(idx) / cnr1_mult_old * cnr1_mult;
            % temperature correction just for long-wave
            [lw_incoming, lw_outgoing] = lw_correct(lw_incoming, lw_outgoing);
            % calibration for par-lite sensor
            Par_Avg = Par_Avg * PAR_KZ_old_up_mult;
            
        elseif year_arg >= 2009 & year_arg < 2012
            % temperature correction just for long-wave
            [lw_incoming, lw_outgoing] = lw_correct(lw_incoming, lw_outgoing);
            % calibration for par-lite sensor
            Par_Avg = Par_Avg * PAR_KZ_old_up_mult;
            
        elseif year_arg == 2012
            % There are a bunch of "stuck" PPFD periods to remove
            PAR_diff = diff( Par_Avg );
            rem_idx = PAR_diff == 0;
            Par_Avg( rem_idx ) = NaN;
            % And one period with bad SW_in and SW_out
            rem_idx = decimal_day > 254.4 & decimal_day < 263.7;
            sw_incoming( rem_idx ) = NaN;
            sw_outgoing( rem_idx ) = NaN;
            NR_tot( rem_idx ) = NaN;
            % temperature correction just for long-wave
            [lw_incoming, lw_outgoing] = lw_correct(lw_incoming, lw_outgoing);
            % calibration for par-lite sensor
            Par_Avg = Par_Avg * PAR_KZ_old_up_mult;
            
        elseif year_arg == 2013
            % temperature correction just for long-wave
            [lw_incoming, lw_outgoing] = lw_correct(lw_incoming, lw_outgoing);
            % calibration for par-lite sensor, after this it is in
            % datalogger program
            idx = decimal_day > 0.0 & decimal_day < 122.5;
            Par_Avg( idx ) = Par_Avg( idx ) * PAR_KZ_old_up_mult;
            
        elseif year_arg == 2014
            % temperature correction just for long-wave;
            [lw_incoming, lw_outgoing] = lw_correct(lw_incoming, lw_outgoing);
            % Bad PPFD values early in 2014 - GEM
            Par_Avg(find(decimal_day > 52.0 & decimal_day < 107.0)) = NaN;
        elseif year_arg == 2015
            % After the solar scaffold collapsed the CNR1 was miswired for
            % a little while.
            idx = decimal_day > 338.5;
            patch = lw_incoming( idx );
            lw_incoming( idx ) = sw_outgoing ( idx );
            sw_outgoing( idx ) = patch;
            idx = decimal_day > 328.61 & decimal_day < 338.58;
            lw_outgoing( idx ) = NaN;
            % Temp-correct longwave
            % FIXME - should we just use CG3co values?
            [lw_incoming, lw_outgoing] = lw_correct(lw_incoming, lw_outgoing);
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
        if year_arg == 2005 || year_arg == 2006 || year_arg == 2007
            % wind corrections for the Q*7
            NR_tot(find(NR_tot < 0)) = NR_tot(find(NR_tot < 0)).*10.91 ...
                .*((0.00174.*wnd_spd(find(NR_tot < 0))) + 0.99755);
            NR_tot(find(NR_tot > 0)) = NR_tot(find(NR_tot > 0)).*8.83 ...
                .*(1 + (0.066.*0.2.*wnd_spd(find(NR_tot > 0))) ...
                ./(0.066 + (0.2.*wnd_spd(find(NR_tot > 0)))));
            
            % pyrronometer corrections
            sw_incoming = sw_incoming.*1000./27.34;
            sw_outgoing = sw_outgoing.*1000./19.39;
            
        elseif year_arg == 2008 || year_arg == 2009
            % par switch to par-lite on ??
            
        end
        
        [ ~, ~, ~, hr, ~, ~ ] = datevec( datenum( year_arg, 1, 0 ) + decimal_day );
        isnight = ( Par_Avg < 20.0 ) | ( sw_incoming < 20 );
        isnight = isnight | ( hr >= 22 ) | ( hr <= 5 );
        % remove nighttime Rg and RgOut values outside of [ -5, 5 ]
        % added 15 Jun 2013 in response to problems noted by Sebastian Wolf
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
        [lw_incoming, lw_outgoing] = lw_correct(lw_incoming, lw_outgoing);
        % recalculate net radiation with T-adjusted longwave?????????
        
        %%%%%%%%%%%%%%%%% New Grassland
    case UNM_sites.New_GLand
        % Current multiplier for CNR1
        cnr1_sensitivity = 5.09; % from current program
        cnr1_mult = 1000 / cnr1_sensitivity;
        % Pre-2014 multiplier to be corrected
        cnr1_mult_old = 163.66;
        
        % PAR multipliers
        % FIXME - these are from the current program, but I still can't
        % tell if they right (PAR_in seems low)
        PAR_up_sensitivity = 6.4;
        % PAR_dn_sensitivity = 6.32;
        PAR_up_mult = 1000 / (PAR_up_sensitivity  * 0.604 );
        
        if year_arg <= 2013
            % calibration correction for the li190
            Par_Avg = Par_Avg * PAR_up_mult;
            % Calibration and unit conversion into W per m^2 for CNR1
            % variables. First correct for the old datalogger program
            % that had the wrong CNR1 sensitivity.
            sw_incoming = sw_incoming ./ cnr1_mult_old .* cnr1_mult;
            sw_outgoing = sw_outgoing ./ cnr1_mult_old .* cnr1_mult;
            lw_incoming = lw_incoming ./ cnr1_mult_old .* cnr1_mult;
            lw_outgoing = lw_outgoing ./ cnr1_mult_old .* cnr1_mult;
            % Temperature correction just for long-wave
            [lw_incoming, lw_outgoing] = lw_correct(lw_incoming, lw_outgoing);
            
        elseif year_arg == 2014
            % Datalogger program changed on Jan 17m 2014 to include the
            % correct radiation calibrations - correct to this data only
            cal_idx = find( decimal_day > 0.0 & decimal_day < 17.5 );
            Par_Avg( cal_idx ) = Par_Avg( cal_idx ) * PAR_up_mult;
            sw_incoming( cal_idx ) = ...
                sw_incoming( cal_idx ) ./ cnr1_mult_old .* cnr1_mult;
            sw_outgoing( cal_idx ) = ...
                sw_outgoing( cal_idx ) ./ cnr1_mult_old .* cnr1_mult;
            lw_incoming( cal_idx ) = ...
                lw_incoming( cal_idx ) ./ cnr1_mult_old .* cnr1_mult;
            lw_outgoing( cal_idx ) = ...
                lw_outgoing( cal_idx ) ./ cnr1_mult_old .* cnr1_mult;
            % Temperature correction just for long-wave
            [lw_incoming, lw_outgoing] = lw_correct(lw_incoming, lw_outgoing);
        elseif year_arg == 2015
            % Temperature correction just for long-wave
            [lw_incoming, lw_outgoing] = lw_correct(lw_incoming, lw_outgoing);
        end
end

    % A function for temperature correcting longwave radiation
    function [ lw_in_co, lw_out_co ] = ...
            lw_correct( lw_in, lw_out, varargin )
        if nargin > 2
            cor_idx = varargin{ 1 };
        else
            cor_idx = find( decimal_day >= 0.0 );
        end
        lw_in_co = lw_in;
        lw_out_co = lw_out;
        lw_in_co( cor_idx ) = lw_in( cor_idx ) + ...
            0.0000000567 .* ( CNR1TK( cor_idx )) .^4;
        lw_out_co( cor_idx ) = lw_out( cor_idx ) + ...
            0.0000000567 .* ( CNR1TK( cor_idx )) .^4;
    end

    % A function for applying a linear correction to data
    function var_fit = linfit_var( x, slope, int, varargin )
         if nargin > 3
            fit_idx = varargin{1};
        else
            fit_idx = find(decimal_day >= 0.0);
         end
        var_fit = x;
        var_fit( fit_idx ) = x( fit_idx ) * slope + int;
    end

end
