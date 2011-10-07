%1-reads in raw ts data, separates into half-hour periods
%2-sends to other programs for processing/ averaging into half-hour values. 
%3-outputs half-hour values with timestamps corresponding to the end of the
%half-hour period
%
%modified by Krista Anderson-Teixeira 1/08
%substantially rewritten by Timothy W. Hilton, Sep 2011

function [date, hr, fco2out, tdryout, hsout, hlout, iokout] = ...
        UNM_data_processor(filename, date_start, site, figures_on, rotation, ...
                           lag, writefluxall);

    % preliminaries -- calculate day of year, get sitecode, set up input &
    % output directories
    sitecode = get_site_code(site);
    outfolder = get_out_directory(sitecode);
    sitefolder = get_site_directory(sitecode);
    
    tob1 = read_TOB1_file(filename);
    
    % campbell datalogger records time as seconds since 1 Jan 1990 00:00:00.
    % convert campbell timestamp to Matlab datenum (mdn)
    secs_per_day = 60 * 60 * 24;
    mdn = datenum(1990, 1, 1) + (tob1.SECONDS / secs_per_day);

    %decide whether to make plots
    plots = 0;
    plots2 = figures_on;
    plots3 = figures_on;

    % Moved call to figure(1); clf; to inside if statement; MF Feb 17, 2011
    % MAKE PLOTS OF RAW DATA
    % if (plots);
    %     fig1_h = draw_plots1(uin, vin, win, co2in, h2oin, Tin, Pin, diagsonin, ...
    %                          outfolder, date, site);
    % end

    hfhrs = floor(date_start) + ((0:0.5:24.0) / 24.0);
    [hfhr_obs_count, hfhr_obs_idx] = histc(mdn, hfhrs);

    % create a dataset initialized to NaN to contain output data
    out_headers = define_fluxall_headers();
    out_data = dataset({repmat(NaN, 48, length(out_headers)), ...
                        out_headers{:, 1}});
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Start for-loop for 48 half-hour periods  
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    for i=1:48  %cycle through all 48 (potential) half-hour time periods
                %calculate hour & minutes for each period (time recorded at the
                %end)
        
        %write progress indicator	      
        fprintf(1, '.');
    
        if hfhr_obs_count(i) == 0
            % no data for this half hour -- create an output line of NaNs
            
        else 
            % there are data for this half hour
            this_hfhr = tob1(hfhr_obs_idx == i, :);
            [year_ts, month_ts, day_ts, hour_ts, min_ts, sec_ts] = datevec(hfhrs(i));
            
            % initialize some intermediate variables
            % by setting to NaN, the arrays aren't backfilled with zeros if a
            % partial day is processed
            theta = repmat(NaN, 48, 1);
            speed = repmat(NaN, 48, 1);
            uvwtmean = repmat(NaN, 48, 4);
            uvwmeanrot = repmat(NaN, 48, 3);
            uvwmean = repmat(NaN, 48, 3);
            lagCO2= repmat(NaN, 48, 7);
            lagH2O = repmat(NaN, 48, 5);
            
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % CALL UNM_dry_air_conversions  
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

            [CO2,H2O,PWATER,TD,RHO,IRGADIAG,IRGAP,P,removedco2] = ...
                UNM_dry_air_conversions(this_hfhr.co2,...
                                        this_hfhr.h2o,...
                                        this_hfhr.press,...
                                        this_hfhr.Ts,...
                                        hfhr_obs_count(i),...
                                        sitecode);

            removed(i,1:5) = removedco2;
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % Call UNM_csat3 for despiking sonic variables, calculating mean winds,
            % and calculating theta.
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

            % if the TOB1 file for this site does not 
            % include a sonic diagnostic field, fill in zeros
            if not(any(strcmp(this_hfhr.Properties.VarNames, 'diagson')))
                this_hfhr.diagson = zeros(length(this_hfhr), 1);
            end

            %uvwt is transposed here because fluxcat3freemanKA was written for data in
            %rows....
            uvwt = [this_hfhr.Ux, this_hfhr.Uy, this_hfhr.Uz, this_hfhr.Ts];
            [uvwt2, SONDIAG, THETA, uvwtmean_, speed_] = ...
                UNM_csat3(uvwt', this_hfhr.diagson', sitecode);
            
            % uvwt2 is despiked wind and temperature matrix
            % SONDIAG is sonic diagnostic variable combining both original
            %     diagson and despike (1 for good, 0 for bad)
            
            uvw2 = uvwt2(1:3,:); % pare down to just winds
            uvwtmean(i,:) = uvwtmean_; %mean values for (despiked) sonic
                                       %measurements
            uvwmean = uvwtmean(i,1:3); % pare means down to just winds
            theta(i,1) = THETA;  %meteorological mean wind angle - it is the compass
                                 %angle in degrees that the wind is blowing FROM (0 =
                                 %North, 90 = east, etc)
            speed(i,1) = speed_;
            temp2 = uvwt2(4,:);

            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % Split path for 3d versus planar rotation
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

            if strcmp(rotation, '3d') % 3d rotation
                [UVWROT,uvwmeanrot_] = UNM_coordrot(uvw2,SONDIAG); % ROTATE
                                                                   % COORDINATES SUCH
                                                                   % THAT MEAN U, V,
                                                                   % & W = 0
                
                UVW2 = UVWROT; % in this case, UVW2 !! is !! rotated 
                               % ROW 1: sonic component
                               %   rotated into the mean wind direction 
                               % ROW 2: sonic cross-wind component 
                               % ROW 3: sonic w component
                uvwmeanrot(i,:) = uvwmeanrot_; %mean values for despiked and 3D
                                                 %rotated sonic measurements
                
            elseif strcmp(rotation, 'planar') % planar rotation
                UVW2 = uvw2; %in this case, UVW2 !! is not !! rotated
                uvwmeanrot(i,:) = NaN*ones(3,1);
            end
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % CALL UNM_flux
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            if lag == 0
                [CO2_, H2O_, FCO2_, FH2O_, HSENSIBLE_, HLATENT_, RHOM_, TDRY_, ...
                 IOKNUM_, zoL, UVWTVAR_, COVUVWT_, HBUOYANT_, USTAR_, TRANSPORT_, ...
                 u_vector_, w_mean_, rH_] = UNM_flux(year_ts, month_ts, day_ts, ...
                                                     UVW2, uvwmean, SONDIAG, ...
                                                     CO2', H2O', TD', RHO', ...
                                                     IRGADIAG', rotation, site, ...
                                                     sitecode, hfhr_obs_count,...
                                                     PWATER, ...
                                                     uvwmeanrot(i, :), IRGAP, ...
                                                     speed(i), temp2, ...
                                                     theta(i));
                
            elseif lag==1
                [CO2_, H2O_, FCO2_, FH2O_, HSENSIBLE_, HLATENT_, RHOM_, TDRY_, ...
                 IOKNUM_, LAGCO2, LAGH2O, zoL] = ...
                    flux7500freeman_lag(UVW2, uvwmean, USTAR_, SONDIAG,  ...
                                        CO2', H2O', TD',  RHO', IRGADIAG', ...
                                        rotation, sitecode, num, PWATER,  ...
                                        uvwmeanrot(i, 1:3), hsout, IRGAP, theta(i));
                lagCO2(i,1:7)=LAGCO2;
                lagH2O(i,1:5)=LAGH2O;
            end

            co2out(i,1:5) = CO2_; %CO2 (umol/mol dry air). 
                                  % 1- min, %2-max, 3-median, %4-mean, 5-std
            h2oout(i,1:5) = H2O_; %H20 (mmol/mol dry air) 
                                  %1- min, 2-max, %3-median, %4-mean, 5-std
            fco2out(i,1:5) = FCO2_; %CO2 flux
                                    % [Fc_corr;
                                    % Fc_raw; Fc_heat_term; Fc_water_term;
                                    %  Fc_raw_massman; Fc_heat_term_massman;
                                    %  Fc_corr_massman_ourwpl]
            fh2oout(i,1:6) = FH2O_; %H20 flux
                                    % [E_corr;Euncorr;E_heat_term;E_water_term;
                                    %  Euncorr_massman;E_heat_term_massman;
                                    %  E_corr_massman]
            hsout_flux(i,1:4) = HSENSIBLE_; %sensible heat (W m-2) [HSdry; HSwet;
                                            %HSwetwet; HSdry_massman]
            hlout(i,1:3) = HLATENT_; %latent heat (W m-2) [HLuncorr; HLuncorr_massman;
                                     %HLcorr_massman]
            rhomout(i,1:3) = RHOM_; %dry air molar density (moles/m^3 moist air)
            tdryout(i,1) = TDRY_;
            iokout(i,1:2) = IOKNUM_;
            zoLout(i,1) = zoL;
            uvwtvar(i,1:4) = UVWTVAR_;   %variances of ROTATED wind components and the
                                         %sonic temperature
            covuvwt(i,1:6) = COVUVWT_;   %covariances of ROTATED wind components and
                                         %the sonic temperature
            hbuoyantout(i,1) = HBUOYANT_;  %bouyancy flux (W m-2)
            ustar(i,1) = USTAR_;  % NX1 friction velocity (m/s)
            transportout(i,1) = TRANSPORT_;  %turblent transport
            u_vector(i,1:3) = u_vector_;
            w_mean(i,1) = w_mean_; %this is rotated from planar fit
            rH(i,1) = rH_;

            % calculate day of year (DOY) for this half hour; 1 Jan is DOY 1
            decimal_day = hfhrs(i) - datenum(year_ts, 1, 1, 0, 0 ,0) + 1;
            julday(i,1) = floor(decimal_day);
            numdate(i,1) = month_ts * 1e4 + day_ts * 1e2 + mod(year_ts, 100);
            
            UVW2      = NaN*ones(3,size(uvwt,2));
            UVWTVAR   = NaN*ones(4,1);
            COVUVWT   = NaN*ones(6,1);
            USTAR     = NaN;
            HBUOYANT  = NaN;
            TRANSPORT = NaN;
            hsout = NaN;
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % Hold out periods of known calibration for Texas site
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            outputs_on = true;
            if sitecode == 7
                outputs_on = TX_site_known_calibrations(hfhrs(i));
            end
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % produce outputs
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            keyboard()
            out_data.julday(i)=dayofyear(year_ts, month_ts, day_ts, ...
                                         hour_ts, min_ts, sec_ts);
            out_data.numdate(i)=month_ts * 1e4 + day_ts * 1e2 + mod(year_ts, 100);
            if ~outputs_on
                out_data.uvwtvar(i,1:4)=UVWTVAR_;   %variances of ROTATED wind
                                                    %components and the sonic
                                                    %temperature
                covuvwt(i,1:6)=COVUVWT_;   %covariances of ROTATED wind
                                           %components and the sonic temperature
                hbuoyantout(i,1)=HBUOYANT_;  %bouyancy flux (W m-2)
                ustar(i,1)=USTAR_;  % NX1 friction velocity (m/s)
                transportout(i,1)=TRANSPORT_;  %turblent transport
                u_vector(i,1:3) = u_vector_;
                w_mean(i,1) = w_mean_; %this is rotated from planar fit
            end
        end
    end
    
    fprintf('\n');  %finish the ASCII progress bar
        
    timestamp = datestr(datev_30);
    datenumber = datenum(datev_30);
    ioko = iokout(:,2);

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % if plots are on, draw them now
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %make automatic plots using these variables
    % draw_plots2 and draw_plots3 code below
    if plots2
        draw_plots2(datenumber, uvwt_mean, theta, uvwtvar, ustar, speed, ...
                    co2out, h2oout, fco2out, fh2oout, hsout_flux, hlout, ...
                    tdryout, hbuoyantout, transportout, ioko, date, ...
                    outfolder);
    end
    if plots3
        draw_plots3(datenumber, tdryout, fco2out, fh2oout, hsout_flux, ...
                    hlout, outfolder);
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % write output files
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % daily output: "fairly useless, except as source for header"
    keyboard()
    y = [datev_30, numdate, julday, ioko, uvwtmean, tdryout, theta, speed, rH, ...
         uvwtvar, covuvwt, ustar,co2out,h2oout,fco2out,fh2oout,hsout_flux, ...
         hlout,rhomout, hbuoyantout,transportout, removed,zoLout,u_vector, ...
         w_mean];
    write_xls = false;
    write_daily_files(y, date, outfolder, write_xls);
    
    
    
    %running compilation
    ofid = fopen(fullfile(sitefolder,' output'),'a');
    for i=1:size(y,1)
        fprintf(ofid,'%f ', y(i,:));
        fprintf(ofid, '\n');
    end
    fclose(ofid);

    keyboard()
    if writefluxall
        disp('preparing to enter data in FLUX_all file....')
        fluxallfile = fullfile(outfolder, sprintf('%s_FLUX_all.csv']);
        [num text] = xlsread(fluxallfile,'matlab','A1:A65500');
        col='B';    
        
        timestamp2=text(5:size(text,1));
        n=1;
        time_match1=NaN; % time match lag is the row of the excel file for a given
                         % date/time (MF)
        for i=1:48
            if isnan(time_match1)==1 & ioko(i)>6000 %have not yet matched up first row
                timenum=datenum(timestamp2);
                time_match=find(abs(timenum-datenumber(i)) < 1/(48*3))+4;
                if time_match >4  % a row with a matching date/time has been
                                  % found in timestamp2 (MF) 
                    if lag==0
                        y2(n,:)=y(i,:);
                    elseif lag==1
                        y2(n,:)=y_lag(i,:);
                    end
                    time_match1=time_match;  % set time match lag equal to
                                             % time match if matching row
                                             % found; otherwise leave as NaN
                                             % (MF)
                    n=n+1;           
                end
            elseif isnan(time_match1)==0 & sum(find(ioko(i:48)>0))>0
                %already have matched up first row & there is more data that day
                if lag==0 
                    y2(n,:)=y(i,:);
                elseif lag==1
                    y2(n,:)=y_lag(i,:);
                end
                n=n+1;  
            else %no more data
            end
        end
        
        if isnan(time_match1)==0 & size(time_match1,1)==1;
            xlswrite(fluxallfile,y2,'matlab', strcat(col,num2str(time_match1)));
            disp('wrote to FLUX_all')
        else
            %disp('rows that match date/time') % MF Aug 2011
            %disp(time_match1)                 % MF Aug 2011
            
            disp('ERROR: FAILED TO WRITE TO FLUX_ALL!!!!!!!!!')   
            disp('ERROR: FAILED TO WRITE TO FLUX_ALL!!!!!!!!!')
            disp('ERROR: FAILED TO WRITE TO FLUX_ALL!!!!!!!!!')
            disp('ERROR: FAILED TO WRITE TO FLUX_ALL!!!!!!!!!')
            disp('ERROR: FAILED TO WRITE TO FLUX_ALL!!!!!!!!!')     
        end
    end 
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    % compoutput = [datev_30, numdate,julday, ioko, ustar, fco2out, fh2oout, ...
    %               hsout, hlout];
    % 
    % comparison = strcat(sitedir,site,'_lag_test'); %setting up the lag output file
    % xlswrite(comparison,compoutput);
    
    removedfile = fullfile(sitedir,[site, '_removed']); %create a file for removed
                                                        %output
    xlswrite(removedfile,removed);
    
    % removed a lot of commented-out code here.  See archived
    % UNM_data_processor.m for that code.   -TWH
    
    % update progress to stdout
    fprintf(1, '--\n');
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% file-writing helper functions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function write_daily_files(y, date, outdir, write_xls)
% WRITE_DAILY_FILES - helper function for UNM_data_processor; writes daily files
% to disk
%   
    
    headertext = {'year', 'month', 'day', 'hour', 'min', 'second', 'date', ...
                  'jday', 'iok', 'u_mean', 'v_mean', 'w_mean',...
                  'temp_mean','tdry', 'wind direction (theta)', 'speed','rH',...
                  'a4long-wind velocity variance','cross-wind velocity variance', ...
                  'vertical-wind velocity variance',...
                  'sonic temperature variance','uw co-variance','vw co-variance',...
                  'uv co-variance','ut co-variance','vt co-variance','wt co-variance',...
                  'ustar (friction velocity, m/s)',...
                  'CO2_min (umol/mol dry air)', 'CO2_max (umol/mol dry air)', ...
                  'CO2_median (umol/mol dry air)', 'CO2_mean (umol/mol dry air)',...
                  'CO2_std (umol/mol dry air)',...
                  'H2O_min (mmol/mol dry air)','H2O_max (mmol/mol dry air)',...
                  'H2O_median (mmol/mol dry air)','H2O_mean (mmol/mol dry air)',...
                  'H2O_std (mmol/mol dry air)',...
                  'Fc_raw','Fc_raw_massman','Fc_water_term','Fc_heat_term_massman',...
                  'Fc_raw_massman_ourwpl',...
                  'E_raw','E_raw_massman','E_water_term','E_heat_term_massman',...
                  'E_raw_massman','E_rhov_massman',...
                  'SensibleHeat_dry (W m-2)','SensibleHeat_wet (W m-2)',...
                  'SensibleHeat_wetwet (W m-2)','HSdry_massman',...
                  'LatentHeat_raw (W m-2)','LatentHeat_raw_massman',...
                  'LatentHeat_wpl_massman',...
                  'rhoa_dry air molar density (g/m^3 moist air)',...
                  'rhov_dry air molar density (g/m^3 moist air)',...
                  'rhoc_dry air molar density (g/m^3 moist air)',...
                  'BouyancyFlux','transport',...
                  'NaNs','Maxs','Mins','Spikes','Bad variance','zoL',...
                  'urot','vrot','wrot',...
                  'u_vector_u','u_vector_v','u_vector_w','w_mean'};
    
    %write data to files
    fprintf(1, 'writing data to files - ');

    %build filename
    if write_xls
        outfile_ext = '.xls';
    else
        outfile_ext = '.csv';
    end 
    fname = sprintf('%s_processed_data%s', datestr(date, 'YYYY_mm_dd'), outfile_ext);
    outfile = fullfile(outdir, fname);
    if write_xls
        %write excel files
        if lag == 0
            xlswrite(fileout, headertext, int2str(date),'A1');
            xlswrite(fileout, y,int2str(date),'A2');
        elseif lag == 1
            xlswrite(fileout, headertext_lag,int2str(date),'A1');
            xlswrite(fileout, y_lag,int2str(date),'A2');
        end
        disp('wrote excel file');
    else
        %write ascii files
        ofid = fopen(outfile, 'w');
        if ofid ~= -1
            fprintf(ofid, '%s,', headertext{:});
            fclose(ofid);
            dlmwrite(outfile, y, '-append', 'precision', '%.10f');
            %write progress to stdout
            fprintf(1, 'wrote %s\n', fname);
        end
    end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% plotting helper functions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function h = draw_plots1(uin, vin, win, co2in, h2oin, Tin, Pin, diagsonin, ...
			 outfolder, date, site)
    % DRAW_PLOTS1 - draw_plots1: helper function for UNM_data_processor
    h = figure(1);
    clf;
    disp('creating plots of raw data.....')    
    subplot(3,3,1); plot(uin); axis tight; xlabel('time'); ylabel('uin');
    subplot(3,3,2); plot(vin); axis tight; xlabel('time'); ylabel('vin');
    subplot(3,3,3); plot(win); axis tight; xlabel('time'); ylabel('win');
    subplot(3,3,4); plot(co2in); axis tight; xlabel('time'); ylabel('CO2in');
    subplot(3,3,5); plot(h2oin); axis tight; xlabel('time'); ylabel('H2Oin');
    subplot(3,3,6); plot(Tin); axis tight; xlabel('time'); ylabel('Tin');
    subplot(3,3,7); plot(Pin); axis tight; xlabel('time'); ylabel('Pin');
    subplot(3,3,8); plot(diagsonin); axis tight; xlabel('time'); ylabel('diagsonin');
    %subplot(3,3,9); plot(diagirga); axis tight; xlabel('time'); ylabel('diagirga');
    figname= strcat(outfolder, int2str(date), site ,' diagnostic plot');
    print('-dpng', '-r300', figname);
    shg;

%--------------------------------------------------  
function [h] = draw_plots2(datenumber, uvwt_mean, theta, uvwtvar, ustar, speed, ...
			   co2out, h2oout, fco2out, fh2oout, hsout_flux, hlout, ...
			   tdryout, hbuoyantout, transportout, ioko, date, ...
			   outfolder)
    % plotting helper function for UNM_data_processor

    disp ('making plots of processed data....')
    
    h = figure(2);

    subplot (5,3,1);
    plot (datenumber,uvwtmean);
    axis tight;
    ylabel ('u,v,w, Temp');
    %legend ('u','v','w','Temp');   

    subplot (5,3,3);
    plot (datenumber,theta);
    axis tight;
    ylabel ('theta (wd)');
    
    subplot (5,3,2);
    plot (datenumber,uvwtvar);
    axis tight;
    ylabel ('uvwT variance');
    %legend ('along-wind','cross-wind','vertical wind','sonic temp');
    %%variances of ROTATED wind components and the sonic temperature

    subplot (5,3,4);
    plot (datenumber,ustar, datenumber, speed);
    axis tight;
    ylabel ('ustar (bl), speed (gr)');
    %legend ('ustar', 'speed');
    
    subplot (5,3,5);
    plot (datenumber,co2out);
    axis tight;
    ylabel ('CO_2 (umol/mol)');
    %legend ('min', 'max', 'median', 'mean', 'std');
    
    subplot (5,3,6);
    plot (datenumber,h2oout);
    axis tight;
    ylabel ('H_20 (mmol/mol)');
    %legend ('min', 'max', 'median', 'mean', 'std');

    subplot (5,3,7);
    plot (datenumber,fco2out(:,1:5));
    axis tight;
    ylabel ('CO_2 flux');
    %legend ('Fco2','corrected','raw','heat term', 'water term', 'advection');
    
    subplot (5,3,8);
    plot (datenumber,fh2oout);
    axis tight;
    ylabel ('H_2O flux');
    %legend ('Ecorr', 'corrected', 'uncorrected', 'heat term', 'water term','advection');

    subplot (5,3,9);
    plot (datenumber,hsout_flux);
    axis tight;
    ylabel ('sensible heat (W m^-^2)');
    %legend ('dry', 'wet', 'wetwet');

    subplot (5,3,10);
    plot (datenumber,hlout);
    axis tight;
    ylabel ('latent heat (W m^-^2)');
    %legend('corrected', 'uncorrected', 'advection');

    subplot (5,3,11);
    plot (datenumber,rhomout);
    axis tight;
    ylabel ('dry air molar density');
    %legend('rhoa', 'rhov','rhoc');

    subplot (5,3,12);
    plot (datenumber,tdryout);
    axis tight;
    ylabel ('T_d_r_y');

    subplot (5,3,13);
    plot (datenumber,hbuoyantout);
    axis tight;
    xlabel ('time hours)');
    ylabel ('buoyancy flux');

    subplot (5,3,14);
    plot (datenumber,transportout);
    axis tight;
    xlabel ('time (hours)');
    ylabel ('transport');

    subplot (5,3,15);
    plot (datenumber,ioko);
    axis tight;
    xlabel ('time (hours)');
    ylabel ('ioko');

    figname2 = [outfolder,int2str(date) site ' summary plots'];
    print ('-dpng', '-r300', figname2);
    shg;

%--------------------------------------------------  
function h = draw_plots3(datenumber, tdryout, fco2out, fh2oout, hsout_flux, ...
			 hlout, outfolder)
    % DRAW_PLOTS3 - another helper function for UNM_data_processor.  Plots a number
    % of variables.
    %  
    
    h = figure(3);
    clf;
    
    subplot (2,2,1);
    plot (datenumber,tdryout-273.15);
    axis tight;
    ylabel ('T_d_r_y (C)');
    
    subplot (2,2,2);
    plot (datenumber, fco2out(:,1:5));
    axis tight;
    ylabel ('CO_2 flux');
    legend ('Fco2','corrected','raw','heat term', 'water term', 'advection', ...
            'location', 'Bestoutside');
    
    subplot (2,2,3);
    plot (datenumber,fh2oout(:,1:5));
    axis tight;
    ylabel ('H_2O flux');
    legend ('Ecorr', 'corrected', 'uncorrected', 'heat term', 'water term', ...
            'location', 'Bestoutside');

    subplot (2,2,4);
    plot (datenumber,hsout_flux, datenumber, hlout);
    axis tight;
    ylabel ('Sensible Heat ,Latent Heat (W m^-^2)');
    legend ('H dry', 'H wet', 'H wetwet', 'LE corrected', 'LE uncorrected', ...
            'LE advection', 'location', 'Bestoutside');
    
    figname3= [outfolder, int2str(date) site ' key plots'];
    print ('-dpng', '-r300', figname3);
    shg;


