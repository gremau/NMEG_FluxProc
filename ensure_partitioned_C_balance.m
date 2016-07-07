function out_tbl = ensure_partitioned_C_balance( sitecode, ...
    in_tbl, RE_str, NEE_str, Rg_str, include_old_ecb )

% FIXME - documentation and cleanup

% To ensure carbon balance, calculate GPP as remainder when NEE is
% subtracted from RE. This will give negative GPP when NEE exceeds
% modelled RE. So set GPP to zero and add difference to RE.

fix_night = false;

RE = in_tbl.( RE_str );
NEE = in_tbl.( NEE_str );
Rg = in_tbl.( Rg_str );
tstamp = in_tbl.timestamp;

% Make new header cellarrays
RE_str_new = [ RE_str, '_ecb' ];
GPP_str_new = regexprep( RE_str_new, 'RECO', 'GPP' );
NEE_str_new = regexprep( RE_str_new, 'RECO', 'NEE' );
new_headers = { GPP_str_new, RE_str_new, NEE_str_new };
unit_headers = { 'mumol/m2/s', 'mumol/m2/s', 'mumol/m2/s' };

% Retrieve the carbon-balanced outputs and put in table
ecb_mat = ensure_carbon_balance( sitecode, tstamp, RE, NEE, Rg, ...
                                 fix_night );
ecb_tbl = array2table( ecb_mat, 'VariableNames', new_headers );
ecb_tbl.Properties.VariableUnits = unit_headers;

% If desired, outputs with nighttime GPP removed can be included
old_ecb_tbl = table(); % Initialize empty table
if include_old_ecb
    fix_night = true;
    % Change the headers a bit
    new_headers = strrep( new_headers, '_ecb', '_oldecb');
    % Retrieve carbon-balanced outputs and put in table
    old_ecb_mat = ensure_carbon_balance( sitecode, tstamp, RE, NEE, Rg, ...
                                         fix_night );
    old_ecb_tbl = array2table( old_ecb_mat, 'VariableNames', new_headers );
    old_ecb_tbl.Properties.VariableUnits = unit_headers;
end

% Join tables into the output table
out_tbl = [ ecb_tbl, old_ecb_tbl ];

% % _ecb fluxes are what were in AF files before the change
% fix_night = true;
% % Lasslop
% [ GPP_f_GL2010_ecb, RE_f_GL2010_ecb, NEE_f_GL2010_ecb ] = ...
%     ensure_carbon_balance( sitecode, qc_tbl.timestamp, ...
%     RE_f_GL2010, NEE_f, ...
%     Rg_f, fix_night );
% % Reichstein
% [ GPP_f_MR2005_ecb, RE_f_MR2005_ecb, NEE_f_MR2005_ecb ] = ...
%     ensure_carbon_balance( sitecode, qc_tbl.timestamp, ...
%     RE_f_MR2005, NEE_f, ...
%     Rg_f, fix_night );
% % Keenan
% if keenan
%     [ GPP_f_TK201X_ecb, RE_f_TK201X_ecb, NEE_f_TK201X_ecb ] = ...
%         ensure_carbon_balance( sitecode, qc_tbl.timestamp, ...
%         RE_f_TK201X, NEE_f, ...
%         Rg_f, fix_night );
% end
% % This is without nighttime GPP correction (?)
% fix_night = false;
% [ GPP_f_GL2010_oldecb, RE_f_GL2010_oldecb, NEE_f_GL2010_oldecb ] = ...
%     ensure_carbon_balance( sitecode, qc_tbl.timestamp, ...
%     RE_f_GL2010, NEE_f, ...
%     Rg_f, fix_night );
% % Reichstein
% [ GPP_f_MR2005_oldecb, RE_f_MR2005_oldecb, NEE_f_MR2005_oldecb ] = ...
%     ensure_carbon_balance( sitecode, qc_tbl.timestamp, ...
%     RE_f_MR2005, NEE_f, ...
%     Rg_f, fix_night );
% % Keenan
% if keenan
%     [ GPP_f_TK201X_oldecb, RE_f_TK201X_oldecb, NEE_f_TK201X_oldecb ] = ...
%         ensure_carbon_balance( sitecode, qc_tbl.timestamp, ...
%         RE_f_TK201X, NEE_f, ...
%         Rg_f, fix_night );
% end

% Make GPP and RE "obs" for output to file with gaps using modeled RE
% and GPP as remainder
% Commenting out - GEM - will add GPP/RE columns above to with_gaps and
% then remove modeled periods with NEE_flag
% GPP_obs = dummy;
% idx = ~isnan( qc_tbl.fc_raw_massman_wpl );
% GPP_obs( idx ) = GPP_2( idx );
% RE_obs = dummy;
% RE_obs( idx ) = RE_2( idx );

        
    function mat_out = ensure_carbon_balance( ...
            sitecode, tstamp, REin, NEEin, Rg_in, fix_night_GPP )
        % ENSURE_CARBON_BALANCE - To ensure carbon balance, calculate GPP as remainder
        % when NEE is subtracted from RE. This will give negative GPP when NEE exceeds
        % modelled RE. So set GPP to zero and add difference to RE.  Beause it is not
        % physically realistic to report positive GPP at night, also make sure that
        % nighttime GPP is < 0.1.
        
        GPPout = REin - NEEin;
        REout = REin;
        NEEout = NEEin;
        
        sitecode = UNM_sites( sitecode );
        % define an observed Rg threshold, below which we will consider
        % it to be night.
        switch sitecode
            case { UNM_sites.GLand, UNM_sites.SLand, UNM_sites.New_GLand }
                Rg_threshold = 1.0;
            case UNM_sites.JSav
                Rg_threshold = -1.0;
            case { UNM_sites.PJ, UNM_sites.TestSite }
                Rg_threshold = 0.6;
            case UNM_sites.MCon
                Rg_threshold = 0.0;
            case UNM_sites.PPine
                Rg_threshold = 0.1;
            case UNM_sites.TX
                Rg_threshold = 4.0;
            case UNM_sites.PJ_girdle
                Rg_threshold = 5.0;
            otherwise
                error( sprintf( 'Rg threshold not implemented for site %s', ...
                    char( sitecode ) ) );
        end
        Rg_threshold = Rg_threshold + 1e-6;  %% compare to threshold plus
        % epsilon to allow for floating point error
        
        if fix_night_GPP
            % fix positive GPP at night -- define night as 
            % radiation < 20 umol/m2/s set positive nighttime GPP to 
            % zero and reduce corresponding respiration accordingly
            conf = parse_yaml_config(UNM_sites(sitecode), 'SiteVars');
            solCalcs = noaa_solar_calcs(conf.latitude, conf.longitude, ...
                tstamp);
            sol = 90 - solCalcs.solarZenithAngleDeg;
            % Next line is old way to do this - can delete once new way (above)
            % checks out
            %sol = get_solar_elevation( UNM_sites( sitecode ), tstamp );
            idx = ( sol < -10 ) & ( Rg_in < Rg_threshold ) & ( GPPout > 0.1 );
            fprintf( '# of positive nighttime GPP: %d\n', numel( find( idx ) ) );
            % take nighttime positive GPP out of RE
            REout( idx ) = REout( idx ) - GPPout( idx );
            GPPout( idx ) = 0.0;
            
            idx_RE_negative = REout < 0.0;
            REout( idx_RE_negative ) = 0.0;
            NEEout( idx_RE_negative ) = 0.0;
        end
        
        % fix negative GPP
        idx_neg_GPP = find( GPPout < 0 );
        REout( idx_neg_GPP ) = REin( idx_neg_GPP ) - GPPout( idx_neg_GPP );
        GPPout( idx_neg_GPP ) = 0;
        
        mat_out = [ GPPout, REout, NEEout ];
        
    end
end
