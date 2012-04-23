function ds_out =  UNM_Ameriflux_prepare_soil_met( sitecode, year, ...
                                                   data, ds_qc )
% UNM_AMERIFLUX_PREPARE_SOIL_MET - 
%   
% contains the section of UNM_Ameriflux_file_maker.m as of 15 Aug 2011 that
% gathers/calculates all the soil met properties.  By modularizing it here it
% should make it easier to streamline this going into the future.  I have gone
% through and replaced QC columns with ds_qc -- the dataset created by
% fluxallqc_2_dataset.m
%   
%
    t0 = now();
    fprintf( 1, 'Begin soil met properties...' );
    
    %% create a column of -9999s to place in the dataset where a site does not record
    %% a particular variable
    dummy = repmat( -9999, size( data, 1 ), 1 );

    % find any soil heat flux columns within QC data
    shf_vars = regexp_ds_vars( ds_qc, 'soil_heat_flux.*' );
    n_shf_vars = size( shf_vars, 2 );  % how many SHF columns are there?    
    %% data is now a dataset -- convert it to a matrix of doubles for
    %% back-compatibilty
    data_timestamp = data.timestamp;
    data = double( data( :, 2:end ) );
    
    if sitecode == 1 % Grassland
 
        % parameter values for soil heat flux
        bulk = 1398; 
        scap = 837; 
        wcap = 4.19e6; 
        depth = 0.05;
        
        % column locations for cover types within SWC, soil T, etc.
        cover_indices = { [ 1, 4, 7, 10, 13, 18 ], ...
                          [ 3, 6, 9, 12, 15, 20 ], ...
                          [ 17, 22 ] };
        % N by 21 matrix of all 21 SWC sensor measurements
        T_soil_all = data( :, 107:128 );
        
       if ismember( year, [ 2007, 2008 ] )
           swc_raw  =  (data(:,165:187));            
       elseif year >= 2009
           swc_raw  =  (data(:,155:177));                        
       end
       
       [ vwc, ...
         vwc_Tc, ...
         mean_vwc ...
         mean_vwc_Tc ] = process_site_year_SWC( swc_raw, ...
                                                T_soil, ...
                                                cover_indices )

        if year == 2007
            % not sure what this is - different VWC measurement?  --TWH
            DL_vwc = data( :, 188:210 );
            DL_vwc( DL_vwc > 1.0 ) = NaN; 
            DL_vwc( DL_vwc < 0.0 ) = NaN;
            for i = 1:numel( cover_indices )
                this_DL_vwc = nanmean( DL_vwc( :, cover_indices{ 1 } ), 2 );
                this_vwc = mean_vwc{ i };
                this_vwc( 1:8000 ) = this_DL_vwc( 1:8000 );
                mean_vwc{ 1 } = this_vwc;
        end
        
        % ------------------------------
        % calculate GLand soil heat flux, with storage
        init_vals = repmat( NaN, size( ds_qc, 1 ), n_shf_vars );
        shf_names = arrayfun( @(x) sprintf('SHF_%d', x), 1:n_shf_vars, ...
                              'UniformOutput', false);
        ds_shf = dataset( {init_vals, shf_names{:} } );
        
        % need to get the correct conversion factor
        shf_conv_factor = 1.0;
        Tsoil_1 = nanmean( T_soil_all( :, cover_indices{ 1 } ), 2 );
        Tsoil_2 = nanmean( T_soil_all( :, cover_indices{ 1 } ), 2 );
        ds_shf.SHF_1 = calculate_heat_flux( Tsoil_1,  SWC_1, ...
                                            bulk, scap, wcap, depth, ...
                                            ds_qc.soil_heat_flux_1, ...
                                            shf_conv_factor );
        ds_shf.SHF_2 = calculate_heat_flux( Tsoil_2,  SWC_2, ...
                                            bulk, scap, wcap, depth, ...
                                            ds_qc.soil_heat_flux_2, ...
                                            shf_conv_factor );
        
    elseif sitecode  ==  2 % Shrubland
        cover_indices = { [ 1, 6, 11, 16 ], ...
                          [ 3, 8, 13, 18 ], ...
                          [ 5, 10, 15, 20 ] };
        if year < 2009
            swc_raw  =  (data(:,165:186));
            error( 'need to find T_soil columns' );
            
            % Calculate ground heat flux
            bulk = 1327; scap = 837; wcap = 4.19e6; depth = 0.05; 
            shf_conv_factor = 1.0;
            ds_shf.SHF_1 = calculate_heat_flux( Tsoil_1,  mean_vwc{ 1 }, ...
                                                bulk, scap, wcap, depth, ...
                                                ds_qc.soil_heat_flux_1, ...
                                                shf_conv_factor );
            
        elseif year >= 2009
            T_soil_all = data( 107:128 );
            swc_raw = ( data( :, 155:176 ) );
            
            %%
            % Calculate ground heat flux
            soil_heat_flux_1 = data(:,209);
            soil_heat_flux_2 = data(:,210);
            soil_heat_flux_3 = data(:,211);
            soil_heat_flux_4 = data(:,212);
            soil_heat_flux_5 = data(:,213);
            soil_heat_flux_6 = data(:,214);
            % %set parameter values
            bulk = 1327; scap = 837; wcap = 4.19e6; depth = 0.05; 
            
            % why is this here and not in RemoveBadData?  --TWH
            par_down_Avg  =  data(:,143);
            par_down_Avg  =  par_down_Avg .* 1000 ./ ( 6.94 * 0.604 );
            
        end

        [ vwc, ...
          vwc_Tc, ...
          mean_vwc ...
          mean_vwc_Tc ] = process_site_year_SWC( swc_raw, ...
                                                 T_soil_all, ...
                                                 cover_indices )

        % calculate SLand soil heat flux, with storage
        error( 'which vwc to use?  T-corrected or non-corrected?' );
        init_vals = repmat( NaN, size( ds_qc, 1 ), n_shf_vars );
        shf_names = cell( arrayfun( @(n) sprintf('SHF_%d', n), ...
                                    1:n_shf_vars, ...
                                    'UniformOutput', false ) );
        ds_shf = dataset( {init_vals, shf_names{:} } );
        
        % need to get the correct conversion factor
        shf_conv_factor = 1.0;
        ds_shf.SHF_1 = calculate_heat_flux( Tsoil_1,  mean_vwc{ 1 }, ...
                                            bulk, scap, wcap, depth, ...
                                            soil_heat_flux_1, ...
                                            shf_conv_factor );
        ds_shf.SHF_2 = calculate_heat_flux( Tsoil_2,  mean_vwc{ 2 }, ...
                                            bulk, scap, wcap, depth, ...
                                            soil_heat_flux_2, ...
                                            shf_conv_factor );
        ds_shf.SHF_3 = calculate_heat_flux( Tsoil_3,  mean_vwc{ 3 }, ...
                                            bulk, scap, wcap, depth, ...
                                            soil_heat_flux_3, ...
                                            shf_conv_factor );

    elseif sitecode  ==  3 % Juniper savannah
        if year == 2007
            vwc = data(:,175:190);
            vwc(vwc>1) = NaN; vwc(vwc<0) = NaN;
            SWC_1 = nanmean(cat(2,vwc(:,1),vwc(:,5),vwc(:,9),vwc(:,13))'); 
            SWC_1 = SWC_1';
            SWC_2 = nanmean(cat(2,vwc(:,3),vwc(:,7),vwc(:,11),vwc(:,15))'); 
            SWC_2 = SWC_2';
            SWC_3 = nanmean(cat(2,vwc(:,4),vwc(:,8),vwc(:,12),vwc(:,16))'); 
            SWC_3 = SWC_3';
            
            tt = data(:,191:210);
            Tsoil_1 = nanmean(cat(2,tt(:,1),tt(:,6),tt(:,11),tt(:,16))'); 
            Tsoil_1 = Tsoil_1';
            Tsoil_2 = nanmean(cat(2,tt(:,3),tt(:,8),tt(:,13),tt(:,18))'); 
            Tsoil_2 = Tsoil_2';
            Tsoil_3 = nanmean(cat(2,tt(:,4),tt(:,9),tt(:,14),tt(:,19))'); 
            Tsoil_3 = Tsoil_3';
            
            % grab ground heat flux data -- 2 set ups at JSav
            ds_qc.Tsoil_hfp = data(:,219);            
            % new_shf_var =  sprintf( 'soil_heat_flux_%d', n_shf_vars + 1 );
            % shf_vars.( new_shf_var ) = data(:,221).*32.27;
            % new_shf_var =  sprintf( 'soil_heat_flux_%d', n_shf_vars + 2 );
            % shf_vars.( new_shf_var ) = data(:,222).*33.00;
            
            

            
        elseif year == 2008
            vwc = data(:,175:190);
            vwc(vwc>1) = NaN; vwc(vwc<0) = NaN;
            SWC_1 = nanmean(cat(2,vwc(:,1),vwc(:,5),vwc(:,9),vwc(:,13))'); 
            SWC_1 = SWC_1';
            SWC_2 = nanmean(cat(2,vwc(:,3),vwc(:,7),vwc(:,11),vwc(:,15))'); 
            SWC_2 = SWC_2';
            SWC_3 = nanmean(cat(2,vwc(:,4),vwc(:,8),vwc(:,12),vwc(:,16))'); 
            SWC_3 = SWC_3';
            
            tt = data(:,191:210);
            Tsoil_1 = nanmean(cat(2,tt(:,1),tt(:,6),tt(:,11),tt(:,16))'); 
            Tsoil_1 = Tsoil_1';
            Tsoil_2 = nanmean(cat(2,tt(:,3),tt(:,8),tt(:,13),tt(:,18))'); 
            Tsoil_2 = Tsoil_2';
            Tsoil_3 = nanmean(cat(2,tt(:,4),tt(:,9),tt(:,14),tt(:,19))'); 
            Tsoil_3 = Tsoil_3';
            
            % Calculate ground heat flux 2 set ups at JSav
            ds_qc.Tsoil_hfp = data(:,211);
            % new_shf_var =  sprintf( 'soil_heat_flux_%d', n_shf_vars + 1 );
            % shf_vars.( new_shf_var ) = data(:,213).*32.27;
            % new_shf_var =  sprintf( 'soil_heat_flux_%d', n_shf_vars + 1 );
            % shf_vars.( new_shf_var ) = data(:,214).*33.00;
            
        elseif year == 2009 || year == 2010 || year  ==  2011
            vwc = data(:,178:195);
            vwc(vwc>1) = NaN; vwc(vwc<0) = NaN;
            %% gap fill and smooth SWC using filter
            
            aa  =  1;
            nobs  =  12; % 6 hr filter
            bb  =  (ones(nobs,1)/nobs);
            vwc2 = vwc;
            vwc3 = vwc2;
            vwc4 = vwc2;
            [l w] = size(vwc2);
            for n  =  1:w
                for m  =  11:l-11
                    average = nanmean(vwc2((m-10:m+10),n));
                    standev = nanstd(vwc2((m-10:m+10),n));
                    if(vwc2(m,n)>average+standev*3 || vwc2(m,n)<average-standev*3)
                        vwc2(m,n) = nan;
                    end
                    if isnan(vwc2(m,n))
                        vwc3(m,n) = average;
                    end
                end
                vwc4(:,n) = filter(bb,aa,vwc3(:,n));
                vwc4(1:(l-(nobs/2))+1,n) = vwc4(nobs/2:l,n);
            end
            
            SWC_1 = nanmean(cat(2,vwc2(:,1),vwc2(:,5),vwc2(:,9),vwc2(:,13))'); 
            SWC_1 = SWC_1';
            SWC_2 = nanmean(cat(2,vwc2(:,3),vwc2(:,7),vwc2(:,11),vwc2(:,15))');
            SWC_2 = SWC_2';
            SWC_3 = nanmean(cat(2,vwc2(:,4),vwc2(:,8),vwc2(:,12),vwc2(:,16))');
            SWC_3 = SWC_3';
            
            SWC_1 = nanmean(cat(2,vwc4(:,1),vwc4(:,5),vwc4(:,9),vwc(:,13))'); 
            SWC_1 = SWC_1';
            SWC_2 = nanmean(cat(2,vwc4(:,3),vwc4(:,7),vwc4(:,11),vwc(:,15))');
            SWC_2 = SWC_2';
            SWC_3 = nanmean(cat(2,vwc4(:,4),vwc4(:,8),vwc4(:,12),vwc(:,16))');
            SWC_3 = SWC_3';


            
            tt = data(:,196:213);
            Tsoil_1 = nanmean(cat(2,tt(:,1),tt(:,4),tt(:,7),...
                                tt(:,10),tt(:,13),tt(:,16))'); 
            Tsoil_1 = Tsoil_1';
            Tsoil_2 = nanmean(cat(2,tt(:,2),tt(:,5),tt(:,8),...
                                tt(:,11),tt(:,14),tt(:,17))'); 
            Tsoil_2 = Tsoil_2';
            Tsoil_3 = nanmean(cat(2,tt(:,3),tt(:,6),tt(:,9),...
                                tt(:,12),tt(:,15),tt(:,18))'); 
            Tsoil_3 = Tsoil_3';
            
            % Calculate ground heat flux 2 set ups at JSav
            ds_qc.Tsoil_hfp = data(:,214);
            new_shf_var =  sprintf( 'soil_heat_flux_%d', n_shf_vars + 1 );
            shf_vars.( new_shf_var ) = data(:,216).*32.27;
            new_shf_var =  sprintf( 'soil_heat_flux_%d', n_shf_vars + 1 );
            shf_vars.( new_shf_var ) = data(:,217).*33.00;

        end
        
        % SHF parameter values
        bulk=1720; 
        scap=837; 
        wcap=4.19e6; 
        depth=0.05; 
        shf_conv_factor = 1.0;

        init_vals = repmat( NaN, size( ds_qc, 1 ), n_shf_vars );
        shf_names = arrayfun( @(x) sprintf('SHF_%d', x), 1:n_shf_vars, ...
                              'UniformOutput', false);
        ds_shf = dataset( {init_vals, shf_names{:} } );


        ds_shf.SHF_1 = calculate_heat_flux( Tsoil_1,  SWC_1, ...
                                            bulk, scap, wcap, depth, ...
                                            ds_qc.soil_heat_flux_1, ...
                                            shf_conv_factor );
        ds_shf.SHF_2 = calculate_heat_flux( Tsoil_2,  SWC_2, ...
                                            bulk, scap, wcap, depth, ...
                                            ds_qc.soil_heat_flux_2, ...
                                            shf_conv_factor );


    elseif sitecode  ==  4 % Pinon-juniper
        
        if year  ==  2008
            % replace -9999 w/ NaN w/in a floating point tolerance of 0.0001
            data = replace_badvals( data, -9999, 0.0001 );
            tcav_p = data(:,213);
            tcav_j = data(:,214);
            shf_p = data(:,215).*35.2;
            shf_j = data(:,216).*32.1;
            vwc_p = data(:,218);
            vwc_j = data(:,219);
            Tsoil_1 = tcav_j;
            Tsoil_2 = tcav_p;
            soil_heat_flux_1 = shf_j;
            soil_heat_flux_2 = shf_p;
            SWC_1 = vwc_j;
            SWC_2 = vwc_p;
            
            % Calculate ground heat flux for pinon
            ds_qc.Tsoil_hfp = tcav_j;

        elseif year  ==  2009
            
            Tsoil_1 = dummy;
            Tsoil_2 = dummy;
            Tsoil_3 = dummy;
            SWC_1 = dummy;
            SWC_2 = dummy;
            SWC_3 = dummy;
            soil_heat_flux_1 = dummy;
            soil_heat_flux_2 = dummy;
            
        elseif year  ==  2010 || year  ==  2011
            
            Tsoil_1 = dummy;
            Tsoil_2 = dummy;
            Tsoil_3 = dummy;
            SWC_1 = dummy;
            SWC_2 = dummy;
            SWC_3 = dummy;
            soil_heat_flux_1 = dummy;
            soil_heat_flux_2 = dummy;
            
        end

        % ------------------------------
        % calculate PJ soil heat flux, with storage

        % parameter values for soil heat flux
        bulk_j = 1437; 
        bulk_p = 1114; 
        scap = 837; 
        wcap = 4.19e6; 
        depth = 0.05;

        init_vals = repmat( NaN, size( ds_qc, 1 ), n_shf_vars );
        shf_names = { 'SHF_j', 'SHF_p' };
        ds_shf = dataset( {init_vals, shf_names{:} } );
        
        % need to get the correct conversion factor
        shf_conv_factor = 1.0;
        ds_shf.SHF_j = calculate_heat_flux( Tsoil_1,  SWC_1, ...
                                            bulk_j, scap, wcap, depth, ...
                                            soil_heat_flux_1, ...
                                            shf_conv_factor );
        ds_shf.SHF_p = calculate_heat_flux( Tsoil_2,  SWC_2, ...
                                            bulk_p, scap, wcap, depth, ...
                                            soil_heat_flux_2, ...
                                            shf_conv_factor );

    elseif sitecode  ==  5
        if year == 2007
            tsoil_2cm = ds_qc.Tsoil_hfp;
            tsoil_6cm = soil_heat_flux_1;
            vwc = soil_heat_flux_2;
            
            Tsoil_1 = tsoil_2cm;
            Tsoil_2 = tsoil_6cm;
            Tsoil_3 = dummy;
            SWC_1 = vwc;
            SWC_2 = dummy;
            SWC_3 = dummy;
            
            deltaT = cat(1,Tsoil_1,1)-cat(1,1,Tsoil_1); 
            deltaT = deltaT(2:length(deltaT));
            theta = SWC_1; theta(isnan(theta)) =  0.05; % Gapfill soil moisture with other
                                                    % shallow measurements; big
                                                    % gap in soil moisture
                                                    % firstpart of 2007 fill
                                                    % with 0.05
            bulk = 1071; scap = 837; wcap = 4.19e6; depth = 0.05; % parameter values
            bulk = bulk.*ones(size(dummy,1),1);
            scap = scap.*ones(size(dummy,1),1);
            wcap = wcap.*ones(size(dummy,1),1);
            depth = depth.*ones(size(dummy,1),1);
            cv = (bulk.*scap)+(wcap.*theta);
            storage = cv.*deltaT.*depth; % in Joules
            storage1 = storage/(60*30); % in Wm-2
            
            deltaT = cat(1,Tsoil_2,1)-cat(1,1,Tsoil_2); 
            deltaT = deltaT(2:length(deltaT));
            theta = SWC_1; theta(isnan(theta)) =  0.05; % Gapfill soil moisture with other
                                                    % shallow measurements; big
                                                    % gap in soil moisture
                                                    % firstpart of 2007 fill
                                                    % with 0.05
            bulk = 1071; scap = 837; wcap = 4.19e6; depth = 0.05; % parameter values
            bulk = bulk.*ones(size(dummy,1),1);
            scap = scap.*ones(size(dummy,1),1);
            wcap = wcap.*ones(size(dummy,1),1);
            depth = depth.*ones(size(dummy,1),1);
            cv = (bulk.*scap)+(wcap.*theta);
            storage = cv.*deltaT.*depth; % in Joules
            storage2 = storage/(60*30); % in Wm-2
            
            ground = (storage1+storage2);
            
        elseif year == 2008
            tsoil_2cm = ds_qc.Tsoil_hfp;
            tsoil_6cm = soil_heat_flux_1; %Different order than elsewhere
            vwc = soil_heat_flux_2; % Different order than elsewhere
            
            data(data == -9999) = nan;
            
            % Big gap in hmp temp record, so patch in with TDry
            TDry = data(:,14);
            Tdry  =  TDry-273.15;
            air_temp_hmp(isnan(air_temp_hmp)) = Tdry(isnan(air_temp_hmp));
            
            Tsoil_1 = tsoil_2cm;
            Tsoil_2 = tsoil_6cm;
            Tsoil_3 = dummy;
            SWC_1 = vwc;
            SWC_2 = dummy;
            SWC_3 = dummy;
            
            % calculate heat storage at 4 depths, 2, 5, 20 and 50 cm

            % calculate for volumes 1-3cm, 4-10cm, 11-33cm, 34-62cm (3, 7, 23, 30cm depths)
            
            deltaT = cat(1,tsoil_2cm,1)-cat(1,1,tsoil_2cm); deltaT = deltaT(2:length(deltaT));
            theta = vwc; theta(isnan(theta)) =  0.05; % Gapfill soil moisture with other shallow measurements; big gap in soil moisture firstpart of 2007 fill with 0.05
            bulk = 1070; scap = 837; wcap = 4.19e6; depth = 0.03; % parameter values
            bulk = bulk.*ones(size(dummy,1),1);
            scap = scap.*ones(size(dummy,1),1);
            wcap = wcap.*ones(size(dummy,1),1);
            depth = depth.*ones(size(dummy,1),1);
            cv = (bulk.*scap)+(wcap.*theta);
            storage = cv.*deltaT.*depth; % in Joules
            storage1 = storage/(60*30); % in Wm-2
            
            deltaT = cat(1,Tsoil_1,1)-cat(1,1,Tsoil_1); deltaT = deltaT(2:length(deltaT));
            theta = SWC_1; theta(isnan(theta)) =  0.05; % Gapfill soil moisture with other shallow measurements; big gap in soil moisture firstpart of 2007 fill with 0.05
            bulk = 1070; scap = 837; wcap = 4.19e6; depth = 0.07; % parameter values
            bulk = bulk.*ones(size(dummy,1),1);
            scap = scap.*ones(size(dummy,1),1);
            wcap = wcap.*ones(size(dummy,1),1);
            depth = depth.*ones(size(dummy,1),1);
            cv = (bulk.*scap)+(wcap.*theta);
            storage = cv.*deltaT.*depth; % in Joules
            storage2 = storage/(60*30); % in Wm-2
            
            deltaT = cat(1,Tsoil_2,1)-cat(1,1,Tsoil_2); deltaT = deltaT(2:length(deltaT));
            theta = SWC_2; theta(isnan(theta)) =  0.05; % Gapfill soil moisture with other shallow measurements; big gap in soil moisture firstpart of 2007 fill with 0.05
            bulk = 1479; scap = 837; wcap = 4.19e6; depth = 0.23; % parameter values
            bulk = bulk.*ones(size(dummy,1),1);
            scap = scap.*ones(size(dummy,1),1);
            wcap = wcap.*ones(size(dummy,1),1);
            depth = depth.*ones(size(dummy,1),1);
            cv = (bulk.*scap)+(wcap.*theta);
            storage = cv.*deltaT.*depth; % in Joules
            storage3 = storage/(60*30); % in Wm-2
            
            deltaT = cat(1,Tsoil_3,1)-cat(1,1,Tsoil_3); deltaT = deltaT(2:length(deltaT));
            theta = SWC_3; theta(isnan(theta)) =  0.05; % Gapfill soil moisture with other shallow measurements; big gap in soil moisture firstpart of 2007 fill with 0.05
            bulk = 1405; scap = 837; wcap = 4.19e6; depth = 0.30; % parameter values
            bulk = bulk.*ones(size(dummy,1),1);
            scap = scap.*ones(size(dummy,1),1);
            wcap = wcap.*ones(size(dummy,1),1);
            depth = depth.*ones(size(dummy,1),1);
            cv = (bulk.*scap)+(wcap.*theta);
            storage = cv.*deltaT.*depth; % in Joules
            storage4 = storage/(60*30); % in Wm-2
            
            ground = (storage1+storage2+storage3+storage4);
            
        elseif ismember( year, [ 2009, 2010, 2011 ] )
            tsoil_2cm = ds_qc.Tsoil_hfp;
            % % these next two lines look suspect...  -TWH, 31 Jan 2012
            % does this mean that SHF1 and SHF2 in QC actually contain tsoil
            % and water content?
            tsoil_6cm = ds_qc.soil_heat_flux_1; %Different order than elsewhere
            vwc = ds_qc.soil_heat_flux_2; % Different order than elsewhere
            
            Tsoil_1 = ds_qc.Tsoil_hfp;
            Tsoil_2 = dummy; % TWH added 31 Jan 2012
            Tsoil_3 = dummy; % TWH added 31 Jan 2012
            SWC_1 = vwc;
            SWC_2 =  dummy;  %ML added 2/26 to get Ameriflux file made
            SWC_3 =  dummy;   %ML added 2/26 to get Ameriflux file made
        end
        
        if ismember( year, [ 2007:2011 ] )
            ground = dummy;
        end

        % calculate soil heat flux
        % parameter values
        bulk = 1405; scap = 837; wcap = 4.19e6; depth = 0.30; 
        shf_conv_factor = 1.0;

        init_vals = repmat( NaN, size( ds_qc, 1 ), n_shf_vars );
        shf_names = arrayfun( @(x) sprintf('SHF_%d', x), 1:n_shf_vars, ...
                              'UniformOutput', false);
        ds_shf = dataset( {init_vals, shf_names{:} } );

        % ------------
        % leave SHF as NaNs until the columns are sorted out
        % ------------
        % % loop through soil heat flux meaurement pits, calculating SHF with
        % % storage for each one
        % for i = 1:n_shf_vars
        %     % parameter values - pits 1 & 2
        %     bulk = 1070; 
        %     scap = 837; 
        %     wcap = 4.19e6;
        %     switch i
        %       case 1
        %         depth = 0.03; 
        %       case 2
        %         depth = 0.07;
        %     end
                  
        %     this_ds_shf = sprintf( 'SHF_%d', i );
        %     this_T_soil = evalin( 'caller', sprintf( 'Tsoil%d', i ) );
        %     this_soil_heat_flux = ds_qc.( sprintf( 'soil_heat_flux_%d', i ) );
        %     this_SWC = evalin( 'caller', sprintf( 'SWC_%d', i ) );
            
        %     ds_shf.this_ds_shf = calculate_heat_flux( this_Tsoil, ...
        %                                               this_SWC, ...
        %                                               bulk, ...
        %                                               scap, ...
        %                                               wcap, ...
        %                                               depth, ...
        %                                               this_soil_heat_flux, ...
        %                                               shf_conv_factor );
        % end

        
    elseif sitecode  ==  6
        %        if year == 2007
        tsoil_2cm = ds_qc.Tsoil_hfp;
        tsoil_6cm = ds_qc.soil_heat_flux_1; %Different order than elsewhere
        vwc = ds_qc.soil_heat_flux_2; % Different order than elsewhere
        
        data(data == -9999) = nan;
        
        Tsoil_1 = tsoil_2cm; %5cm
        Tsoil_2 = tsoil_6cm; %20cm
        Tsoil_3 = dummy; %50cm
        SWC_1 = vwc;
        SWC_2 = dummy;
        SWC_3 = dummy;
        
        % calculate heat storage at 4 depths, 2, 5, 20 and 50 cm
        % calculate for volumes 1-3cm, 4-10cm, 11-33cm, 34-62cm (3, 7, 23, 30cm depths)
        
        deltaT = cat(1,tsoil_2cm,1)-cat(1,1,tsoil_2cm); deltaT = deltaT(2:length(deltaT));
        theta = vwc; theta(isnan(theta)) =  0.05; % Gapfill soil moisture with other shallow measurements; big gap in soil moisture firstpart of 2007 fill with 0.05
        bulk = 1354; scap = 837; wcap = 4.19e6; depth = 0.03; % parameter values
        bulk = bulk.*ones(size(dummy,1),1);
        scap = scap.*ones(size(dummy,1),1);
        wcap = wcap.*ones(size(dummy,1),1);
        depth = depth.*ones(size(dummy,1),1);
        cv = (bulk.*scap)+(wcap.*theta);
        storage = cv.*deltaT.*depth; % in Joules
        storage1 = storage/(60*30); % in Wm-2
        
        deltaT = cat(1,Tsoil_1,1)-cat(1,1,Tsoil_1); deltaT = deltaT(2:length(deltaT));
        theta = SWC_1; theta(isnan(theta)) =  0.05; % Gapfill soil moisture with other shallow measurements; big gap in soil moisture firstpart of 2007 fill with 0.05
        bulk = 1354; scap = 837; wcap = 4.19e6; depth = 0.07; % parameter values
        bulk = bulk.*ones(size(dummy,1),1);
        scap = scap.*ones(size(dummy,1),1);
        wcap = wcap.*ones(size(dummy,1),1);
        depth = depth.*ones(size(dummy,1),1);
        cv = (bulk.*scap)+(wcap.*theta);
        storage = cv.*deltaT.*depth; % in Joules
        storage2 = storage/(60*30); % in Wm-2

        deltaT = cat(1,Tsoil_2,1)-cat(1,1,Tsoil_2); deltaT = deltaT(2:length(deltaT));
        theta = SWC_2; theta(isnan(theta)) =  0.05; % Gapfill soil moisture with other shallow measurements; big gap in soil moisture firstpart of 2007 fill with 0.05
        bulk = 1343; scap = 837; wcap = 4.19e6; depth = 0.23; % parameter values
        bulk = bulk.*ones(size(dummy,1),1);
        scap = scap.*ones(size(dummy,1),1);
        wcap = wcap.*ones(size(dummy,1),1);
        depth = depth.*ones(size(dummy,1),1);
        cv = (bulk.*scap)+(wcap.*theta);
        storage = cv.*deltaT.*depth; % in Joules
        storage3 = storage/(60*30); % in Wm-2
        
        deltaT = cat(1,Tsoil_3,1)-cat(1,1,Tsoil_3); deltaT = deltaT(2:length(deltaT));
        theta = SWC_3; theta(isnan(theta)) =  0.05; % Gapfill soil moisture with other shallow measurements; big gap in soil moisture firstpart of 2007 fill with 0.05
        bulk = 1549; scap = 837; wcap = 4.19e6; depth = 0.30; % parameter values
        bulk = bulk.*ones(size(dummy,1),1);
        scap = scap.*ones(size(dummy,1),1);
        wcap = wcap.*ones(size(dummy,1),1);
        depth = depth.*ones(size(dummy,1),1);
        cv = (bulk.*scap)+(wcap.*theta);
        storage = cv.*deltaT.*depth; % in Joules
        storage4 = storage/(60*30); % in Wm-2
        
        ground = (storage1+storage2+storage3+storage4);
        
        if ismember( year, 2007:2011 )
            ground = dummy;
        end
        
        % calculate soil heat flux
        init_vals = repmat( NaN, size( ds_qc, 1 ), n_shf_vars );
        shf_names = arrayfun( @(x) sprintf('SHF_%d', x), 1:n_shf_vars, ...
                              'UniformOutput', false);
        ds_shf = dataset( {init_vals, shf_names{:} } );

        % ------------
        % leave SHF as NaNs until the columns are sorted out
        % ------------
        
    elseif sitecode  ==  7
        
        if year == 2005
            tsoil = data(:,165:173);
            swcsoil = data(:,178:186);
            % filter these
            tsoil(tsoil<-5) = nan;
            tsoil(tsoil>45) = nan;
            tsoil(15400:16200,9) = nan;
            swcsoil(swcsoil<0) = nan;
            swcsoil(swcsoil>1) = nan;
            swcsoil(3000:4500,3) = nan;
                        
            Tsoil_1 = nanmean(cat(2,tsoil(:,[1 4 7]))')'; %2cm
            Tsoil_2 = nanmean(cat(2,tsoil(:,[2 5 8]))')'; %5cm
            Tsoil_3 = nanmean(cat(2,tsoil(:,[3 6 9]))')'; %10cm
            SWC_1 = nanmean(cat(2,swcsoil(:,[1 4 7]))')'; %2cm
            SWC_2 = nanmean(cat(2,swcsoil(:,[ 5 8]))')'; %5cm
            SWC_3 = nanmean(cat(2,swcsoil(:,[3 6 9]))')'; %10cm

            % Calculate heat flux
            % Use site specific temperatures, but mean SWC as this is very gappy
            % for individual sites
            ot = tsoil(:,1); ot(isnan(ot)) = Tsoil_1(isnan(ot));
            mt = tsoil(:,4); mt(isnan(mt)) = Tsoil_1(isnan(mt));
            jt = tsoil(:,7); jt(isnan(jt)) = Tsoil_1(isnan(jt));
            
            deltaT = cat(1,ot,1)-cat(1,1,ot); deltaT = deltaT(2:length(deltaT));
            theta = SWC_1; theta(isnan(theta)) =  0.15; % Gapfill soil moisture with other shallow measurements;
            bulk = 1114; scap = 837; wcap = 4.19e6; depth = 0.05; % parameter values
            bulk = bulk.*ones(size(dummy,1),1);
            scap = scap.*ones(size(dummy,1),1);
            wcap = wcap.*ones(size(dummy,1),1);
            depth = depth.*ones(size(dummy,1),1);
            cv = (bulk.*scap)+(wcap.*theta);
            storage = cv.*deltaT.*depth; % in Joules
            storage1 = storage/(60*30); % in Wm-2
            
            deltaT = cat(1,mt,1)-cat(1,1,mt); deltaT = deltaT(2:length(deltaT));
            theta = SWC_1; theta(isnan(theta)) =  0.15; % Gapfill soil moisture with other shallow measurements;
            bulk = 1114; scap = 837; wcap = 4.19e6; depth = 0.05; % parameter values
            bulk = bulk.*ones(size(dummy,1),1);
            scap = scap.*ones(size(dummy,1),1);
            wcap = wcap.*ones(size(dummy,1),1);
            depth = depth.*ones(size(dummy,1),1);
            cv = (bulk.*scap)+(wcap.*theta);
            storage = cv.*deltaT.*depth; % in Joules
            storage2 = storage/(60*30); % in Wm-2
            
            deltaT = cat(1,jt,1)-cat(1,1,jt); deltaT = deltaT(2:length(deltaT));
            theta = SWC_1; theta(isnan(theta)) =  0.15; % Gapfill soil moisture with other shallow measurements;
            bulk = 1114; scap = 837; wcap = 4.19e6; depth = 0.05; % parameter values
            bulk = bulk.*ones(size(dummy,1),1);
            scap = scap.*ones(size(dummy,1),1);
            wcap = wcap.*ones(size(dummy,1),1);
            depth = depth.*ones(size(dummy,1),1);
            cv = (bulk.*scap)+(wcap.*theta);
            storage = cv.*deltaT.*depth; % in Joules
            storage3 = storage/(60*30); % in Wm-2
            
            
            soil_heat_flux_1 = (soil_heat_flux_1./40).*34.7; % Apply correct calibration
                                                             % factors to hfps,
                                                             % 40 had been used
                                                             % previously
            soil_heat_flux_2 = (soil_heat_flux_2./40).*35.5;
            soil_heat_flux_3 = (soil_heat_flux_3./40).*38;
            
            groundo = storage1+soil_heat_flux_1;
            groundm = storage2+soil_heat_flux_2;
            groundj = storage3+soil_heat_flux_3;
            ground = cat(2,groundo,groundm,groundj);
            ground = nanmean(ground');
            ground  =  ground';
            
        elseif year == 2006
            tsoil = data(:,165:173);
            swcsoil = data(:,178:186);
            % filter these
            tsoil(tsoil<-5) = nan;
            tsoil(tsoil>45) = nan;
            tsoil(15400:16200,9) = nan;
            swcsoil(swcsoil<0) = nan;
            swcsoil(swcsoil>1) = nan;
            swcsoil(3000:4500,3) = nan;
            
            Tsoil_1 = nanmean(cat(2,tsoil(:,[1 4 7]))')'; %2cm
            Tsoil_2 = nanmean(cat(2,tsoil(:,[2 5 8]))')'; %5cm
            Tsoil_3 = nanmean(cat(2,tsoil(:,[3 6 9]))')'; %10cm
            SWC_1 = nanmean(cat(2,swcsoil(:,[1 4 7]))')'; %2cm
            SWC_1 = swcsoil(:,7); %2cm
            SWC_2 = nanmean(cat(2,swcsoil(:,[2 5 8]))')'; %5cm
            SWC_3 = nanmean(cat(2,swcsoil(:,[3 6 9]))')'; %10cm
            
            % Calculate heat flux
            % Use site specific temperatures, but mean SWC as this is very gappy
            % for individual sites
            ot = tsoil(:,1); ot(isnan(ot)) = Tsoil_1(isnan(ot));
            mt = tsoil(:,4); mt(isnan(mt)) = Tsoil_1(isnan(mt));
            jt = tsoil(:,7); jt(isnan(jt)) = Tsoil_1(isnan(jt));
            
            deltaT = cat(1,ot,1)-cat(1,1,ot); deltaT = deltaT(2:length(deltaT));
            theta = SWC_1; theta(isnan(theta)) =  0.1; % Gapfill soil moisture with other shallow measurements;
            bulk = 1114; scap = 837; wcap = 4.19e6; depth = 0.05; % parameter values
            bulk = bulk.*ones(size(dummy,1),1);
            scap = scap.*ones(size(dummy,1),1);
            wcap = wcap.*ones(size(dummy,1),1);
            depth = depth.*ones(size(dummy,1),1);
            cv = (bulk.*scap)+(wcap.*theta);
            storage = cv.*deltaT.*depth; % in Joules
            storage1 = storage/(60*30); % in Wm-2
            
            deltaT = cat(1,mt,1)-cat(1,1,mt); deltaT = deltaT(2:length(deltaT));
            theta = SWC_1; theta(isnan(theta)) =  0.1; % Gapfill soil moisture with other shallow measurements;
            bulk = 1114; scap = 837; wcap = 4.19e6; depth = 0.05; % parameter values
            bulk = bulk.*ones(size(dummy,1),1);
            scap = scap.*ones(size(dummy,1),1);
            wcap = wcap.*ones(size(dummy,1),1);
            depth = depth.*ones(size(dummy,1),1);
            cv = (bulk.*scap)+(wcap.*theta);
            storage = cv.*deltaT.*depth; % in Joules
            storage2 = storage/(60*30); % in Wm-2
            
            deltaT = cat(1,jt,1)-cat(1,1,jt); deltaT = deltaT(2:length(deltaT));
            theta = SWC_1; theta(isnan(theta)) =  0.1; % Gapfill soil moisture with other shallow measurements;
            bulk = 1114; scap = 837; wcap = 4.19e6; depth = 0.05; % parameter values
            bulk = bulk.*ones(size(dummy,1),1);
            scap = scap.*ones(size(dummy,1),1);
            wcap = wcap.*ones(size(dummy,1),1);
            depth = depth.*ones(size(dummy,1),1);
            cv = (bulk.*scap)+(wcap.*theta);
            storage = cv.*deltaT.*depth; % in Joules
            storage3 = storage/(60*30); % in Wm-2
            
            
            soil_heat_flux_1 = (soil_heat_flux_1./40).*34.7; % Apply correct calibration factors to hfps, 40 had been used previously
            soil_heat_flux_2 = (soil_heat_flux_2./40).*35.5;
            soil_heat_flux_3 = (soil_heat_flux_3./40).*38;
            
            groundo = storage1+soil_heat_flux_1;
            groundm = storage2+soil_heat_flux_2;
            groundj = storage3+soil_heat_flux_3;
            ground = cat(2,groundo,groundm,groundj);
            ground = nanmean(ground');
            ground  =  ground';
            
        elseif year == 2007
            tsoil = data( :, 165:173 );
            swcsoil = data( :, 178:186 );
            % filter these
            tsoil( tsoil < -5 ) = nan;
            tsoil( tsoil > 32 ) = nan;
            tsoil( 2400:2700,1 ) = nan;
            swcsoil( swcsoil < 0 ) = nan;
            swcsoil( swcsoil > 1 ) = nan;
            
            Tsoil_1 = nanmean(cat(2,tsoil(:,[1 4 7]))')'; %2cm
            Tsoil_2 = nanmean(cat(2,tsoil(:,[2 5 8]))')'; %5cm
            Tsoil_3 = nanmean(cat(2,tsoil(:,[3 6 9]))')'; %10cm
            SWC_1 = nanmean(cat(2,swcsoil(:,[1 4 7]))')'; %2cm
            SWC_1 = swcsoil(:,7); %2cm
            SWC_2 = nanmean(cat(2,swcsoil(:,[2 5 8]))')'; %5cm
            SWC_3 = nanmean(cat(2,swcsoil(:,[3 6 9]))')'; %10cm
            
            % Calculate heat flux
            % Use site specific temperatures, but mean SWC as this is very gappy
            % for individual sites
            ot = tsoil(:,1); ot(isnan(ot)) = Tsoil_1(isnan(ot));
            mt = tsoil(:,4); mt(isnan(mt)) = Tsoil_1(isnan(mt));
            jt = tsoil(:,7); jt(isnan(jt)) = Tsoil_1(isnan(jt));
            
            deltaT = cat(1,ot,1)-cat(1,1,ot); deltaT = deltaT(2:length(deltaT));
            theta = SWC_1; theta(isnan(theta)) =  0.1; % Gapfill soil moisture with other
                                                   % shallow measurements;
            bulk = 1114; scap = 837; wcap = 4.19e6; depth = 0.05; % parameter values
            bulk = bulk.*ones(size(dummy,1),1);
            scap = scap.*ones(size(dummy,1),1);
            wcap = wcap.*ones(size(dummy,1),1);
            depth = depth.*ones(size(dummy,1),1);
            cv = (bulk.*scap)+(wcap.*theta);
            storage = cv.*deltaT.*depth; % in Joules
            storage1 = storage/(60*30); % in Wm-2
            
            deltaT = cat(1,mt,1)-cat(1,1,mt); deltaT = deltaT(2:length(deltaT));
            theta = SWC_1; theta(isnan(theta)) =  0.1; % Gapfill soil moisture with other
                                                   % shallow measurements;
            bulk = 1114; scap = 837; wcap = 4.19e6; depth = 0.05; % parameter values
            bulk = bulk.*ones(size(dummy,1),1);
            scap = scap.*ones(size(dummy,1),1);
            wcap = wcap.*ones(size(dummy,1),1);
            depth = depth.*ones(size(dummy,1),1);
            cv = (bulk.*scap)+(wcap.*theta);
            storage = cv.*deltaT.*depth; % in Joules
            storage2 = storage/(60*30); % in Wm-2
            
            deltaT = cat(1,jt,1)-cat(1,1,jt); deltaT = deltaT(2:length(deltaT));
            theta = SWC_1; theta(isnan(theta)) =  0.1; % Gapfill soil moisture with other
                                                   % shallow measurements;
            bulk = 1114; scap = 837; wcap = 4.19e6; depth = 0.05; % parameter values
            bulk = bulk.*ones(size(dummy,1),1);
            scap = scap.*ones(size(dummy,1),1);
            wcap = wcap.*ones(size(dummy,1),1);
            depth = depth.*ones(size(dummy,1),1);
            cv = (bulk.*scap)+(wcap.*theta);
            storage = cv.*deltaT.*depth; % in Joules
            storage3 = storage/(60*30); % in Wm-2
            
            
            soil_heat_flux_1 = (soil_heat_flux_1./40).*34.7; % Apply correct calibration factors to hfps, 40 had been used previously
            soil_heat_flux_2 = (soil_heat_flux_2./40).*35.5;
            soil_heat_flux_3 = (soil_heat_flux_3./40).*38;
            
            groundo = storage1+soil_heat_flux_1;
            groundm = storage2+soil_heat_flux_2;
            groundj = storage3+soil_heat_flux_3;
            ground = cat(2,groundo,groundm,groundj);
            ground = nanmean(ground');
            ground  =  ground';
                        
            SWC_1(10000:(length(SWC_1))) = nan;
            
        elseif year >=  2008
            Tsoil_1 = dummy;
            Tsoil_2 = dummy;
            Tsoil_3 = dummy;
            SWC_1 = dummy;
            SWC_2 = dummy;
            SWC_3 = dummy;
            ground = dummy;
            
        end

        % calculate soil heat flux
        init_vals = repmat( NaN, size( ds_qc, 1 ), n_shf_vars );
        shf_names = arrayfun( @(x) sprintf('SHF_%d', x), 1:n_shf_vars, ...
                              'UniformOutput', false);
        ds_shf = dataset( {init_vals, shf_names{:} } );

    elseif ismember( sitecode, [ 8, 9 ] ) 
        Tsoil_1 = dummy;
        Tsoil_2 = dummy;
        Tsoil_3 = dummy;
        SWC_1 = dummy;
        SWC_2 = dummy;
        SWC_3 = dummy;
        ground = dummy;
        soil_heat_flux_1 = dummy;
        soil_heat_flux_2 = dummy;
        soil_heat_flux_3 = dummy;
        ds_qc.Tsoil_hfp = dummy;
        Tsoil_5c = dummy;
        Tsoil_10c = dummy;
        Tsoil_5o = dummy;
        Tsoil_10o = dummy;
        NR_tot = dummy;
        Par_Avg = dummy;
        sw_incoming = dummy;
        sw_outgoing = dummy;
        lw_incoming = dummy;
        lw_outgoing = dummy;

    elseif sitecode  ==  10
        
        if year  ==  2009
            
            Tsoil_1 = dummy;
            Tsoil_2 = dummy;
            Tsoil_3 = dummy;
            SWC_1 = dummy;
            SWC_2 = dummy;
            SWC_3 = dummy;
            soil_heat_flux_1 = dummy;
            soil_heat_flux_2 = dummy;
            
        elseif year  ==  2010 || year  ==  2011
            
            Tsoil_1 = dummy;
            Tsoil_2 = dummy;
            Tsoil_3 = dummy;
            SWC_1 = dummy;
            SWC_2 = dummy;
            SWC_3 = dummy;
            
        end

        % ------------------------------
        % calculate PJg soil heat flux, with storage

        init_vals = repmat( NaN, size( ds_qc, 1 ), n_shf_vars );
        shf_names = { 'SHF_1', 'SHF_2' };
        ds_shf = dataset( {init_vals, shf_names{:} } );
        
        % no valid inputs for right now, so leave SHF as NaN

        
    elseif sitecode  ==  11
        if year  ==  2010 || year  ==  2011
            
            tsoil = data(:,177:196);
            tsoil(tsoil == 0) = nan; % some suspicous looking zero values here
            Tsoil_1 = nanmean(cat(2,tsoil(:,1),tsoil(:,6),tsoil(:,11),...
                                tsoil(:,16))'); Tsoil_1 = Tsoil_1';
            Tsoil_2 = nanmean(cat(2,tsoil(:,3),tsoil(:,8),tsoil(:,13),...
                                tsoil(:,18))'); Tsoil_2 = Tsoil_2';
            Tsoil_3 = nanmean(cat(2,tsoil(:,5),tsoil(:,10),tsoil(:,15),...
                                tsoil(:,20))'); Tsoil_3 = Tsoil_3';
            
            %% Soil water content calculations from microsecond period
            x  =  (data(:,157:176));
            x(x == 0) = nan; % some suspicous looking zero values here
            
            %% x_tc_2nd is same size as x
            x_tc_2nd  =  (0.526 - 0.052.* x + 0.00136.* (x.* x) ); 
            
            TS = (20-ds_qc.Tsoil_hfp); 
            
            TS  =  repmat(TS, 1, size(x_tc_2nd, 2) );
            
            x_tc  =  x + TS.* x_tc_2nd;
            
            %% temperature corrected
            vwc = repmat(-0.0663,(size(x_tc)))-0.00636.*x_tc+0.0007.*(x_tc.*x_tc); 
            %% not temperature corrected
            vwc2 = repmat(-0.0663,(size(x)))-0.00636.*x+0.0007.*(x.*x); 
            
            % gap fill and smooth SWC using filter 
            % (copied from GLand and edited with existing SWC data)
            
            %         aa  =  1;
            %         nobs  =  12; % 6 hr filter
            %         bb  =  (ones(nobs,1)/nobs);
            %         vwc3 = vwc2;
            %         vwc4 = vwc2;
            %         [l w] = size(vwc2);
            %         for n  =  1:w
            %             for m  =  11:l-11
            %                 average = nanmean(vwc2((m-10:m+10),n));
            %                 standev = nanstd(vwc2((m-10:m+10),n));
            %                 if(vwc2(m,n)>average+standev*3 || vwc2(m,n)<average-standev*3)
            %                     vwc2(m,n) = nan;
            %                 end
            %                 if isnan(vwc2(m,n))
            %                     vwc3(m,n) = average;
            %                 end
            %             end
            %             vwc4(:,n) = filter(bb,aa,vwc3(:,n));
            %             vwc4(1:(l-(nobs/2))+1,n) = vwc4(nobs/2:l,n);
            %         end
            %               
            %         SWC_1 = nanmean(cat(2,vwc4(:,1),vwc4(:,6),vwc4(:,11),vwc4(:,16))'); SWC_1 = SWC_1';
            %         SWC_2 = nanmean(cat(2,vwc4(:,3),vwc4(:,8),vwc(:,13),vwc4(:,18))'); SWC_2 = SWC_2';
            %         SWC_3 = nanmean(cat(2,vwc4(:,5),vwc4(:,10),vwc(:,15),vwc4(:,20))'); SWC_3 = SWC_3';
            %         
            %         datamatrix22  =  [SWC_1,SWC_2,SWC_3];
            %         datamatrix22(isnan(datamatrix22)) = -9999;
            %         dlmwrite('New_GLand_SWC_10.txt',datamatrix22)      
            
            % end of block for gap fill and smooth SWC using filter
            
            %
            SWC_1 = nanmean(cat(2,vwc2(:,1),vwc2(:,6),vwc2(:,11),vwc2(:,16))'); SWC_1 = SWC_1';
            SWC_2 = nanmean(cat(2,vwc2(:,3),vwc2(:,8),vwc(:,13),vwc2(:,18))'); SWC_2 = SWC_2';
            SWC_3 = nanmean(cat(2,vwc2(:,5),vwc2(:,10),vwc(:,15),vwc2(:,20))'); SWC_3 = SWC_3';
            
            % Calculate ground heat flux
            soil_heat_flux_1 = data(:,198); soil_heat_flux_1 = soil_heat_flux_1.*34.6;
            soil_heat_flux_2 = data(:,199); soil_heat_flux_2 = soil_heat_flux_2.*34.6;
            soil_heat_flux_3 = data(:,200); soil_heat_flux_3 = soil_heat_flux_3.*34.2;
            soil_heat_flux_4 = data(:,201); soil_heat_flux_4 = soil_heat_flux_4.*34.4;
            
            deltaT = cat(1,Tsoil_1,1)-cat(1,1,Tsoil_1); deltaT = deltaT(2:length(deltaT));
            theta = SWC_1; theta(isnan(theta)) = SWC_1(isnan(theta)); theta(isnan(theta)) =  0.05; % Gapfill soil moisture with other shallow measurements; big gap in soil moisture firstpart of 2007 fill with 0.05
            bulk = 1398; scap = 837; wcap = 4.19e6; depth = 0.05; % parameter values taken from original grass site
            bulk = bulk.*ones(size(dummy,1),1);
            scap = scap.*ones(size(dummy,1),1);
            wcap = wcap.*ones(size(dummy,1),1);
            depth = depth.*ones(size(dummy,1),1);
            cv = (bulk.*scap)+(wcap.*theta);
            storage = cv.*deltaT.*depth; % in Joules
            storage = storage/(60*30); % in Wm-2
            shf = nanmean(cat(2,soil_heat_flux_1,soil_heat_flux_2,...
                              soil_heat_flux_3,soil_heat_flux_4)'); shf = shf';
            ground = shf+storage;
            
        end

        % fill in NaN for soil heat flux
        init_vals = repmat( NaN, size( ds_qc, 1 ), n_shf_vars );
        shf_names = arrayfun( @(x) sprintf('SHF_%d', x), 1:n_shf_vars, ...
                              'UniformOutput', false);
        ds_shf = dataset( {init_vals, shf_names{:} } );
        
    end

    %%======================================================================
    %% assign all the variables created above to a dataset to be returned to
    %% the caller
    %%======================================================================
    
    var_names = { 'Tsoil_1', 'Tsoil_2', 'Tsoil_3', ...
                  'SWC_1', 'SWC_2', 'SWC_3', ...
                  'SWC_21', 'SWC_22', 'SWC_23', ...
                  'par_down_Avg', ...
                  'bulk', 'scap', 'wcap', 'depth' };
    
    %% initialize the datset to NaNs
    ds_vals = repmat( NaN, size( data, 1 ), numel( var_names ) );
    ds_out = dataset( { ds_vals, var_names{:} } );
                  
    %% assign values to the dataset
    %% soil temperature
    ds_out.Tsoil_1 = Tsoil_1;
    ds_out.Tsoil_2 = Tsoil_2;
    ds_out.Tsoil_3 = Tsoil_3;
    
    %% soil water content
    ds_out.SWC_1 = SWC_1;
    ds_out.SWC_2 = SWC_2;
    ds_out.SWC_3 = SWC_3;
    
    %% the following variables only exist at some sites, so check before
    %% assigning them
    vars = who();
    if exist( 'SWC_21' ) == 1
        ds_out.SWC_21 = SWC_21;
    end
    if exist( 'SWC_22' ) == 1
        ds_out.out.SWC_22 = SWC_22;
    end
    if exist( 'SWC_23' ) == 1
        ds_outout.SWC_23 = SWC_23;
    end
        
    save hf_restart.mat
    
    ds_out = [ ds_out, ds_shf ];
    
    %% add timestamp
    
    ds_out.timestamp = data_timestamp;
    
    %% calculate execution time and write status message
    t_tot = ( now() - t0 ) * 24 * 60 * 60;
    fprintf( 1, ' Done (%.0f secs)\n', t_tot );
    
----------------------------------------------------------------------    
    
function [ vwc, ...
           vwc_Tc, ...
           mean_vwc ...
           mean_vwc_Tc ] = process_site_year_SWC( swc_raw, ...
                                                  T_soil, ...
                                                  cover_indices )
% PROCESS_SITE_YEAR_SWC - process SWC from raw period measurements (in microseconds)
% reported by CS616 to smoothed volumetric water content.  Returns both
% temperature-corrected and non-temperature-corrected values as well as mean
% values by cover type.  Helper function for UNM_Ameriflux_prepare_soil_met.

           % convert cs616 period to volumetric water content
           [ vwc, vwc_Tc ] = cs616_period2vwc( swc_raw, T_soil_all );
           % smooth non-T-corrected vwc
           [ vwc_bad_removed, ...
             vwc_bad_replaced, ...
             vwc_run_mean ] = UNM_soil_data_smoother( vwc );
           % smooth T-corrected vwc
           [ vwc_bad_removed_Tc, ...
             vwc_bad_replaced_Tc, ...
             vwc_run_mean_Tc ] = UNM_soil_data_smoother( vwc_Tc );
           
           mean_vwc = cell( 1, numel( cover_indices ) );
           mean_vwc_Tc = cell( 1, numel( cover_indices ) );

           for i = 1:numel( cover_indices )
               % calculate the mean from each cover type along each row
               % ( each row is a timestamp )
               mean_vwc{ i } = nanmean( vwc( :, cover_indices{ i } ), 2 ); 
               mean_vwc_Tc{ i } = nanmean( vwc_Tc( :, cover_indices{ i } ), 2 );
           end


