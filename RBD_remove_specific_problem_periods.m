function [ fc_raw_massman_wpl, E_wpl_massman, E_raw_massman, ...
    E_heat_term_massman, HL_wpl_massman, ...
    HSdry, HSdry_massman, CO2_mean, H2O_mean, atm_press, NR_tot, ...
    sw_incoming, sw_outgoing, lw_incoming, lw_outgoing, precip, ...
    rH, Par_Avg, Tdry, vpd ] = ...
    RBD_remove_specific_problem_periods( sitecode, ...
    year, ...
    fc_raw_massman_wpl, ...
    E_wpl_massman, ...
    E_raw_massman, ...
    E_heat_term_massman, ...
    HL_wpl_massman, ...
    HSdry, ...
    HSdry_massman, ...
    CO2_mean, ...
    H2O_mean, ...
    atm_press, ...
    NR_tot, ...
    sw_incoming, ...
    sw_outgoing, ...
    lw_incoming, ...
    lw_outgoing, ...
    precip, ...
    rH, ...
    Par_Avg, ...
    Tdry, ...
    vpd )

% Helper function for UNM_RemoveBadData (RBD for short).  Specifies periods
% where various flux observations did not activate any of the RBD filters,
% yet are deemed biologically impossible.

% if sitecode passed as integer, convert to UNM_sites object
if not( isa( sitecode, 'UNM_sites' ) )
    sitecode = UNM_sites( sitecode );
end

% GLand 2007
switch sitecode
    case UNM_sites.GLand
        switch year
            case 2007
                % Precip data was bad this entire year
                precip(1:end) = NaN;
                
                % IRGA problems
                % There is a [CO2] jump, but the flux looks OK here - GEM
%                 idx = DOYidx( 156 ) : DOYidx( 163 );
%                 fc_raw_massman_wpl( idx ) = NaN;
%                 E_wpl_massman( idx ) = NaN;
%                 E_raw_massman( idx ) = NaN;
%                 E_heat_term_massman( idx ) = NaN;
%                 HL_wpl_massman( idx ) = NaN;
%                 CO2_mean( idx  ) = NaN;
%                 H2O_mean( idx ) = NaN;
%                 atm_press( idx ) = NaN;
                
                % IRGA problems here ---
                % big jump in [CO2] and suspicious looking fluxes
                % Coarse filter catches this though (<350ppm) - GEM
%                 idx = DOYidx( 228.5 ) : DOYidx( 235.5 );
%                 fc_raw_massman_wpl( idx ) = NaN;
%                 H2O_mean( idx ) = NaN;
                
            case 2008
                % Pretty sure the precip gauge was not functioning up until
                % Aug 30
                precip( 1 : DOYidx( 244 ) ) = NaN;
                % Dont see problem here - GEM
                %sw_incoming( DOYidx( 7 ) : DOYidx( 9 ) ) = NaN;
                
            case 2010
                % IRGA problems - seems to affect latent only
                idx = DOYidx( 102 ) : DOYidx( 119.5 );
                E_wpl_massman( idx ) = NaN;
                E_raw_massman( idx ) = NaN;
                E_heat_term_massman( idx ) = NaN;
                HL_wpl_massman( idx ) = NaN;
                H2O_mean( idx ) = NaN;
                
                H2O_mean( DOYidx( 85.5 ) : DOYidx( 102.5 ) ) = NaN;
                
                fc_raw_massman_wpl( DOYidx( 327 ) : DOYidx( 328 ) ) = NaN;
                
                % Bad sonic temperature (fluxes bad during this time too)
                Tdry( DOYidx( 295 ) : DOYidx( 319.6 ) ) = NaN;
                vpd( DOYidx( 295 ) : DOYidx( 319.6 ) ) = NaN;
                
            case 2011
                
                % IRGA problems
                idx = DOYidx( 96 ) : DOYidx( 104 );
                fc_raw_massman_wpl( idx ) = NaN;
                E_wpl_massman( idx ) = NaN;
                E_raw_massman( idx ) = NaN;
                E_heat_term_massman( idx ) = NaN;
                HL_wpl_massman( idx ) = NaN;
                CO2_mean( idx ) = NaN;
                H2O_mean( idx ) = NaN;
                
                idx = DOYidx( 342 ) : DOYidx( 348 );
                fc_raw_massman_wpl( idx ) = NaN;
                E_wpl_massman( idx ) = NaN;
                E_raw_massman( idx ) = NaN;
                E_heat_term_massman( idx ) = NaN;
                HL_wpl_massman( idx ) = NaN;
                CO2_mean( idx ) = NaN;
                H2O_mean( idx ) = NaN;
                
                % [CO2] concentration calibration problem
                % WTF? - GEM
                idx = DOYidx( 131.6 ) : DOYidx( 164.6 );
                CO2_mean( idx ) = CO2_mean( idx ) + 10.0;
        end
        
    case UNM_sites.SLand
        switch year
            case 2007
                % Precip gauge seems to be stuck up till late Nov 
                precip( 1:DOYidx(331) ) = NaN;
                %NR_tot( DOYidx( 143 ) : DOYidx( 151 ) ) = NaN;
                %sw_outgoing( DOYidx( 150 ) : DOYidx( 162 ) ) = NaN;
            case 2009
                % Not sure why these are needed - they seem to be hiding
                % some small calibration blips, but I don't see the point
                % of doing this
%                 CO2_mean( DOYidx( 139 ) : DOYidx( 142 ) ) = NaN;
%                 CO2_mean( DOYidx( 287.5 ) : DOYidx( 290.8 ) ) = NaN;
            case 2011
                % Not sure what the explanation is here, but the fluxes
                % look quite funky at this time period. Nothing in log
                % really except a calibration about a month prior.
                idx = DOYidx( 342 ) : DOYidx( 348 );
                fc_raw_massman_wpl( idx ) = NaN;
                E_wpl_massman( idx ) = NaN;
                E_raw_massman( idx ) = NaN;
                E_heat_term_massman( idx ) = NaN;
                CO2_mean( idx ) = NaN;
                H2O_mean( idx ) = NaN;
                HL_wpl_massman( idx ) = NaN;
        end
        
    case UNM_sites.JSav
        switch year
            case 2010
                % FIXME - Explanation?
                lw_outgoing( DOYidx( 130.3 ) : DOYidx( 131.5 ) ) = NaN;
                lw_outgoing( DOYidx( 331.4 ) : DOYidx( 332.7 ) ) = NaN;
                H2O_mean( DOYidx( 221 ) : DOYidx( 229 ) ) = NaN;
            case 2012
                % FIXME - Explanation?
                E_wpl_massman( E_wpl_massman > ( 200 / 18 ) ) = NaN;
                
                % there are a smattering of really cold ( < -8 C ) Tdry observations
                % on day 38, 94 & 95, and 138 that are not recorded at PJ.  Remove
                % these here.
                C_to_K = @( T ) T + 273.15;
                tstamps_per_day = 48;  %there are 48 30-minute observations per day
                doy = ( 1:numel( Tdry ) ) ./ tstamps_per_day;
                doy = reshape( doy, size( Tdry ) );
                Tdry( ( Tdry < C_to_K( -10 ) ) & ( doy > 75 ) & ( doy < 150 ) ) = NaN;
                Tdry( ( Tdry < C_to_K( -8 ) ) & ( doy > 37 ) & ( doy < 38 ) ) = NaN;
                vpd( ( Tdry < C_to_K( -10 ) ) & ( doy > 75 ) & ( doy < 150 ) ) = NaN;
                vpd( ( Tdry < C_to_K( -8 ) ) & ( doy > 37 ) & ( doy < 38 ) ) = NaN;
        end
        
    case UNM_sites.PJ
        switch year
            case 2008
                % Until June 19 sw sensors reported all zeros and lw
                % sensors reported NaNs
                idx = DOYidx( 171.5 );
                %sw_incoming( 1:idx ) = NaN; % This gets calulated from PAR
                sw_outgoing( 1:idx ) = NaN; 
                lw_incoming( 1:idx ) = NaN;
                lw_outgoing( 1:idx ) = NaN;
                NR_tot( 1:idx ) = NaN;
            case 2011
                % Maybe some IRGA problem, screen [CO2] but it
                % didn't look like it affects fluxes.
                CO2_mean( DOYidx( 357.5  ) : end ) = NaN;
            case 2012
                % Maybe some IRGA problem, screen [CO2] but it
                % didn't look like it affects fluxes.
                CO2_mean( 1: DOYidx( 19.45 ) ) = NaN;
                CO2_mean( DOYidx( 78 ) : DOYidx( 175 ) ) = NaN;

            case 2014
                % Maybe some IRGA problem, screen [CO2] but it
                % didn't look like it affects fluxes.
                CO2_mean( DOYidx( 105 ) : DOYidx( 122.5 ) ) = NaN;
                % The bad H2O IRGA was here (0922) from 5/2 to 10/31
                % Do something!?!?
        end
                
    case UNM_sites.PJ_girdle
        switch year
            case 2009
                % FIXME - Explanation? Maybe some IRGA problem, but it
                % didn't look like it affects fluxes.
%                 CO2_mean( DOYidx( 131.4 ) : DOYidx( 141.5 ) ) = NaN;
%                 CO2_mean( DOYidx( 284 ) : DOYidx( 293.65 ) ) = NaN;
            case 2013
                % Bad sonic temperature (fluxes bad during this time too)
                Tdry( DOYidx( 114.7 ) : DOYidx( 120.5 ) ) = NaN;
                vpd( DOYidx( 114.7 ) : DOYidx( 120.5 ) ) = NaN;

            case 2014
                % There looks to be an IRGA problem on these dates - 
                % [CO2] drops then shows a steep declining pattern.
                % It appears that this leads to false NEE (negative FC)
                % Logs show an IRGA swap between these dates and concerns
                % are expressed.
                idx = DOYidx( 112.3 ) : DOYidx( 129 );
                fc_raw_massman_wpl( idx ) = NaN;
                E_wpl_massman( idx ) = NaN;
                E_raw_massman( idx ) = NaN;
                E_heat_term_massman( idx ) = NaN;
                HL_wpl_massman( idx ) = NaN;
                CO2_mean( idx ) = NaN;
                H2O_mean( idx ) = NaN;
            case 2015
                % There looks to be an IRGA problem on these dates - 
                % [CO2] values are way off, so FC is removed. LE still
                % looks bad, so I am removing it - GEM
                idx = DOYidx( 349.71 ) : DOYidx( 359.38 );
                E_wpl_massman( idx ) = NaN;
                E_raw_massman( idx ) = NaN;
                E_heat_term_massman( idx ) = NaN;
                HL_wpl_massman( idx ) = NaN;
                H2O_mean( idx ) = NaN;
        end
        
    case UNM_sites.PPine
        switch year
            case 2007
                % There were some IRGA calibration problems during this
                % time (see logs) and the IRGA was briefly returned to
                % the lab. This is being adjusted so that Values are in the
                % "pocket". Noticed by Bai Yang at ORNL
                idx = DOYidx( 177 ) : DOYidx( 204.98 );
                CO2_mean( idx ) = CO2_mean( idx ) - 16;
                idx = DOYidx( 205 ) : 17520;
                CO2_mean( idx ) = CO2_mean( idx ) + 16;
            case 2008
                % There were some IRGA calibration problems during this
                % time (see logs) and the IRGA was briefly returned to
                % the lab.
                idx = DOYidx( 1 ) : DOYidx( 25.8 );
                CO2_mean( idx ) = CO2_mean( idx ) + 16;
                idx = DOYidx( 264 ) : DOYidx( 311 );
                fc_raw_massman_wpl( idx ) = NaN;
                HL_wpl_massman( idx ) = NaN;
                E_wpl_massman( idx ) = NaN;
                E_wpl_massman( E_wpl_massman > 200 ) = NaN;
                E_raw_massman( idx ) = NaN;
                E_heat_term_massman( idx ) = NaN;
                % RH sensor reads far too low for a long period in 2008
                rH( DOYidx( 99.58 ) : DOYidx( 187 ) ) = NaN;
                vpd( DOYidx( 99.58 ) : DOYidx( 187 ) ) = NaN;
                
                % ???
                %E_wpl_massman( E_wpl_massman > 200 ) = NaN;
                
                %^This is done in apply_radiation_cal script for now.
                %Par_Avg( DOYidx( 99.5 ) : DOYidx( 190.5 ) ) = NaN;
                %Par_Avg( DOYidx( 210 ) : DOYidx( 223 ) ) = NaN;
            case 2009
                % There is a period of bad flux data here that looks
                % like it should be removed - probably an IRGA issue
                % There were some IRGA calibration events here (see log)
                idx = [ DOYidx( 144.5 ) : DOYidx( 162.2 ),...
                    DOYidx( 163.76 ) :  DOYidx( 182.0 ) ];
                fc_raw_massman_wpl( idx ) = NaN;
                HL_wpl_massman( idx ) = NaN;
                E_wpl_massman( idx ) = NaN;
                E_wpl_massman( E_wpl_massman > 200 ) = NaN;
                E_raw_massman( idx ) = NaN;
                E_heat_term_massman( idx ) = NaN;
                HSdry( idx ) = NaN;
                HSdry_massman( idx ) = NaN;
            case 2011
                % FIXME - Explanation?
                idx = DOYidx( 186 ) : DOYidx( 200 );
                fc_raw_massman_wpl( idx ) = NaN;
                HL_wpl_massman( idx ) = NaN;
                E_wpl_massman( idx ) = NaN;
                E_raw_massman( idx ) = NaN;
                E_heat_term_massman( idx ) = NaN;
            case 2012
                idx = DOYidx( 319.5 );
                % beginning here sw sensor reported all zeros and lw sensor
                % reported NaNs
                sw_incoming( idx:end ) = NaN;
                sw_outgoing( idx:end ) = NaN;
                lw_incoming( idx:end ) = NaN;
                lw_outgoing( idx:end ) = NaN;
            case 2013
                idx = DOYidx( 122.5 );
                % Radiation was still down in early 2013
                sw_incoming( 1:idx ) = NaN;
                sw_outgoing( 1:idx ) = NaN;
                lw_incoming( 1:idx ) = NaN;
                lw_outgoing( 1:idx ) = NaN;
        end
        
    case UNM_sites.MCon
        switch year
            case 2009
                % FIXME - Explanation?
                % I think this is unnecessary - GEM
                % sw_incoming( DOYidx( 342 ) : end ) = NaN;
            case 2010
                % FIXME - Explanation?
                idx = DOYidx( 134.4 ) : DOYidx( 146.5 );
                CO2_mean( idx ) = CO2_mean( idx ) + 10;
                
                idx = DOYidx( 301.6 ) : DOYidx( 344.7 );
                CO2_mean( idx ) = CO2_mean( idx ) - 17;
            case 2011
                % FIXME - Explanation?
                idx = DOYidx( 225.4 ) : DOYidx( 237.8 );
                lw_incoming( idx ) = NaN;
                lw_outgoing( idx ) = NaN;
                E_wpl_massman( idx ) = NaN;
                E_raw_massman( idx ) = NaN;
                E_heat_term_massman( idx ) = NaN;
                HL_wpl_massman( idx ) = NaN;
                HSdry( idx ) = NaN;
                HSdry_massman( idx ) = NaN;
                Tdry( idx ) = NaN;
                vpd( idx ) = NaN;
                % Our pcp gauge shows huge pcp on DOY 80 and 309, while the nearby
                % met station (Redondo-Redonito) shows none.
                precip( DOYidx( 80 ):DOYidx( 81 ) ) = 0.0;
                precip( DOYidx( 309 ):DOYidx( 310 ) ) = 0.0;
            case 2012
                % FIXME - Explanation?
                idx = DOYidx( 254.5 ) : min( DOYidx( 263.7 ), numel( NR_tot ) );
                NR_tot( idx ) = NaN;
                sw_incoming( idx ) = NaN;
                sw_outgoing( idx ) = NaN;
                Par_Avg( DOYidx( 101 ) : DOYidx( 160 ) ) = NaN;
                Par_Avg( DOYidx( 286 ) : DOYidx( 300 ) ) = NaN;
                sw_incoming( DOYidx( 132 ) : DOYidx( 133 ) ) = NaN;
                Par_Avg( DOYidx( 132 ) : DOYidx( 133 ) ) = NaN;
                sw_incoming( DOYidx( 224 ) : DOYidx( 225 ) ) = NaN;
                Par_Avg( DOYidx( 224 ) : DOYidx( 225 ) ) = NaN;
        end
        
    case UNM_sites.TX
        switch year
            case { 2011, 2012 }
                % fill 2011, 2012 gaps at US-FR2 from US-FR3 (certain fields only, as per
                % Marcy's email of 25 Apr 2013: "This site is super close to our site.
                % Can you grab the variables we need from there please.  I would take
                % PAR, Rg, ppt, pressure, AirT, RH at least.  Incoming longwave is
                % probably fine.  Would not get outgoing.")
                fname = fullfile( get_site_directory( UNM_sites.TX_forest ), ...
                    'TAMU_Ameriflux_Files', ...
                    sprintf( 'HeilmanKamps_%dFR3WithGaps.csv', year ) );
                TAMU_data = parse_TAMU_ameriflux_file( fname );
                TAMU_data_shifted = shift_data( double( TAMU_data ), ...
                    1.0, ...
                    'cols_to_shift', ...
                    1:size( TAMU_data, 2 ) );
                
                TAMU_data = replacedata( TAMU_data, TAMU_data_shifted );
                
                TX_draw_plots = false;
                TAMU_data.PAR = normalize_PAR( UNM_sites.TX_forest, ...
                    TAMU_data.PAR, ...
                    TAMU_data.DTIME, ...
                    TX_draw_plots, ...
                    2500 );
                
                TAMU_data.Rg = normalize_PAR( UNM_sites.TX_forest, ...
                    TAMU_data.Rg, ...
                    TAMU_data.DTIME, ...
                    TX_draw_plots, ...
                    1200 );
                
                Par_Avg( isnan( Par_Avg ) ) = TAMU_data.PAR( isnan( Par_Avg ) );
                sw_incoming( isnan( sw_incoming ) ) = ...
                    TAMU_data.Rg( isnan( sw_incoming ) );
                precip( isnan( precip ) ) = TAMU_data.PRECIP( isnan( precip ) );
                atm_press( isnan( atm_press ) ) = TAMU_data.PA( isnan( atm_press ) );
                C_to_K = @(T) T + 273.15;
                Tdry( isnan( Tdry ) ) = ...
                    C_to_K( TAMU_data.TA( isnan( Tdry ) ) );
                rH( isnan( rH ) ) = TAMU_data.RH( isnan( rH ) );
                lw_incoming( isnan( lw_incoming ) ) = ...
                    TAMU_data.Rlong_in( isnan( lw_incoming ) );
                
                E_wpl_massman( E_wpl_massman > 200 ) = NaN;
        end
        
    case UNM_sites.New_GLand
        switch year
            % This doesn't seem necessary at all - GEM
%             case 2010
%                 sw_incoming( DOYidx( 355 ) : end ) = NaN;
            case 2014
                % The precip gauge was miswired from Jan 17 to April 2 2014
                precip( DOYidx( 17 ) : DOYidx( 92 ) ) = NaN;
        end
end