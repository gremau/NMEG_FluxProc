%1-reads in raw ts data, separates into half-hour periods
%2-sends to other programs for processing/ averaging into half-hour values. 
%3-outputs half-hour values with timestamps corresponding to the end of the
%half-hour period
%
%modified by Krista Anderson-Teixeira 1/08
%substantially rewritten by Timothy W. Hilton, Sep 2011

function [date, hr, fco2out, tdryout, hsout, hlout, iokout] = ...
        UNM_data_processor(filename, date, site, figures_on, rotation, lag, ...
                           writefluxall);

    % preliminaries -- calculate day of year, get sitecode, set up input &
    % output directories
    jday = date2doy(date);
    sitecode = get_site_code(site);
    outfolder = get_out_directory(sitecode);
    sitefolder = get_site_directory(sitecode);

    CR=13;
    LF=10;
    COMMA=44;

    fid=fopen(filename,'r','ieee-le'); % file ID
    if fid == -1
        err = MException('UNM_data_processor', ...
                         'cannot open file %s\n', filename);
        throw(err);
    end
    d=fread(fid,864000,'uchar');

    % find Line Feeds and Carriage Returns
    icr = find(d==CR);
    ilf = find(d==LF);

    % find the end of the header
    EOH = ilf(5);

    % read last line of header to get the file structure
    HLine2 = d(ilf(1)+1:ilf(2)-1)';
    HLine5 = d(ilf(4)+1:ilf(5)-1)';

    begfields = [1 find(HLine5==COMMA)+1];
    endfields = [find(HLine5==COMMA)-1 length(HLine5)-1];

    begfields2 = [1 find(HLine2==COMMA)+1];
    endfields2 = [find(HLine2==COMMA)-1 length(HLine2)-1];

    Nfields = length(begfields);

    % don't read the quotes at beginning and end of each field
    for i=1:Nfields
        FieldName{i} = char(HLine2(begfields2(i)+1:endfields2(i)-1));
        Field{i} = char(HLine5(begfields(i)+1: endfields(i)-1));
    end

    % Calculate the number of bytes in a record and get the
    % corresponding matlab precision
    for i=1:size(Field,2)
        if strcmp(char(Field(i)),'ULONG')
            NBytes(i) = 4;
            MatlabPrec{i}='uint32';
        elseif  strcmp(char(Field(i)),'IEEE4')
            NBytes(i) = 4;
            MatlabPrec{i}='float32';
        elseif strcmp(char(Field(i)),'IEEE4L')
            NBytes(i) = 4;
            MatlabPrec{i}='float32';
        elseif strcmp(char(Field(i)),'SecNano')
            NBytes(i) = 4;
            MatlabPrec{i}='uint32';
        end       
    end

    %%% Start reading the channels
    fprintf(1, 'reading data: %s\n', datestr(date, 'dd mmm YYYY'));
    % first position pointer at the end of the header
    fseek(fid,EOH,'bof');   %fseek repositions file position indicator (doc
                            %fseek). 'bof' = beginning of file
    ftell(fid);  %position = ftell(fid) returns the location of the file position
                 %indicator for the file specified by fid

    BytesPerRecord=sum(NBytes)*ones(size(NBytes)) - NBytes ;
    BytesCumulative = [0 cumsum(NBytes(1:length(NBytes)-1))];

    % read each column into data matrix:
    for i=1:Nfields
        % fseek repositions file position indicator (doc fseek). problem here
        fseek(fid,EOH+BytesCumulative(i),'bof');
        % reads data into matrix (data, col i)
        data(:,i)= fread(fid,24*3600*10,char(MatlabPrec(i)),BytesPerRecord);
    end
    
    % assign variable names to columns of data:
    if (Nfields==14) % TX_forest & TX_grassland
        time1=(data(:,1));
        uin=(data(:,7));
        vin=(data(:,8));
        win=(data(:,9));
        Tin=(data(:,10)+273.15);
        co2in=(data(:,11))/44;
        h2oin=(data(:,12))/.018;
        Pin=(data(:,13));
        diagcsat=(data(:,14));
        diagsonin = zeros(length(diagcsat),1);
    elseif (Nfields==11); % JSAV, PPINE, TX_savanna ....
        time1=(data(:,1)); % seconds since 1990(?)
        time2=(data(:,2)); % nanoseconds
        uin=(data(:,3));
        vin=(data(:,4));
        win=(data(:,5));
        co2in=(data(:,6))/44;
        h2oin=(data(:,7));
        %h2oin(h2oin<0)=0.01*ones(size(find(h2oin<0)));
        h2oin=h2oin/.018;
        Tin=(data(:,8)+273.15);
        Pin=(data(:,9));
        diagsonin=(data(:,10));
    elseif (Nfields==12 & (sitecode==1 | sitecode==2 | sitecode==10));  
        %GLand, SLand. %Sev sites have their columns mixed up. There is no irga
        %diagnositc!
        time1=(data(:,1)); % seconds since 
        time2=(data(:,2)); % nanoseconds 
        uin=(data(:,3));
        vin=(data(:,4));
        win=(data(:,5));
        co2in=(data(:,6))/44;
        h2oin=(data(:,7));
        %h2oin(h2oin<0)=0.01*ones(size(find(h2oin<0)));
        h2oin=h2oin/.018;

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Correction for dodgy IRGA calibration, September 2009 - 17 March 2010
        %      if sitecode==10
        %         h2oin=(h2oin.*0.8881)-133.65;
        %      end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        Tin=(data(:,8)+273.15);
        Pin=(data(:,9));
        diagsonin=(data(:,10));
    elseif (Nfields==12 & ~(sitecode==1 | sitecode==2));
        time1=(data(:,1));  %seconds since 
        time2=(data(:,2));   % nanoseconds
        rn=(data(:,3));
        uin=(data(:,4));
        vin=(data(:,5));
        win=(data(:,6));
        co2in=(data(:,7))/44;
        h2oin=(data(:,8));
        %h2oin(h2oin<0)=0.01*ones(size(find(h2oin<0)));
        h2oin=h2oin/.018;
        Tin=(data(:,9)+273.15);
        Pin=(data(:,10));
        diagsonin=(data(:,11));
    elseif (Nfields==9);
        uin=(data(:,1));
        vin=(data(:,2));
        win=(data(:,3));
        co2in=(data(:,4))/44;
        h2oin=(data(:,5));
        %h2oin(h2oin<0)=0.01*ones(size(find(h2oin<0)));
        h2oin=h2oin/.018;
        Tin=(data(:,6)+273.15);
        Pin=(data(:,7));
        diagsonin=(data(:,8));
    end

    %convert seconds since 1990 to date vector [year ...]
    datev = datevec((time1./(60.*60.*24))+726834);
    %msec=time2/100000000;  %10 readings/ second-- this gives the number (1-10)

    %decide whether to make plots
    plots = 0;
    plots2 = figures_on;
    plots3 = figures_on;

    % Moved call to figure(1); clf; to inside if statement; MF Feb 17, 2011
    % MAKE PLOTS OF RAW DATA
    if (plots);
        fig1_h = draw_plots1(uin, vin, win, co2in, h2oin, Tin, Pin, diagsonin, ...
                             outfolder, date, site);
    end

    [m,n] = size(data);
    hfhrs = m/18000;
    hfhr1 = floor(hfhrs);
    hfhr2 = round(hfhrs);

    %%%calculate half-hourly values
    fprintf(1, 'calculating half-hourly vectors');
    year_ts=datev(:,1);
    month_ts=datev(:,2);
    day_ts=datev(:,3);
    hr_ts=datev(:,4);
    min_ts=datev(:,5);
    day=day_ts(1);

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Start for-loop for 48 half-hour periods  
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    for i=1:48  %cycle through all 48 (potential) half-hour time periods
                %calculate hour & minutes for each period (time recorded at the
                %end)
        
        %write progress indicator	      
        fprintf(1, '.');
        
        n = i;
        hr(i) = floor((i-1)/2);
        min_end(i) = (((i)/2)-hr(i))*60;
        if min_end(i) == 0;
            min_end(i) = 60;
        end
        min_beg(i) = min_end(i)-30;
        decimal_day = jday + hr(i)/24 + min_beg(i)/1440;
        
        %find indices for each half hour period
        this_half_hour = find(day_ts == day & ...
                              hr_ts == hr(i) & ...
                              min_ts >= min_beg(i) & ...
                              min_ts < min_end(i));
        
        if size(this_half_hour, 1) > 0 % half-hours with data
                                       % assign timestamp (end of period)
            datev_30(i,1:6) = datev(max(this_half_hour), :);
            
            % sonic measurements:
            u = uin(this_half_hour);
            v = vin(this_half_hour);
            w = win(this_half_hour);
            T = Tin(this_half_hour);
            diagson = diagsonin(this_half_hour);
            uvwt = [u v w T];
            % irga measurments - step set to 0 because it appears to be max for now
            co2 = co2in(this_half_hour);
            h2o = h2oin(this_half_hour);
            P = Pin(this_half_hour);
            % switch this line below to agc 
            
            num = size(this_half_hour);

            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % CALL UNM_dry_air_conversions  
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

            [CO2,H2O,PWATER,TD,RHO,IRGADIAG,IRGAP,P,removedco2] = ...
                UNM_dry_air_conversions(co2,h2o,P,T,num,sitecode);

            removed(i,1:5) = removedco2;

            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % Call UNM_csat3 for despiking sonic variables, calculating mean winds,
            % and calculating theta.
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

            %uvwt is transposed here because fluxcat3freemanKA was written for data in
            %rows....
            [uvwt2,SONDIAG,THETA,uvwtmean_,speed_] = ...
                UNM_csat3(uvwt',diagson',sitecode);
            
            % uvwt2 is despiked wind and temperature matrix
            % SONDIAG is sonic diagnostic variable combining both original diagson and
            %     despike (1 for good, 0 for bad)
            
            uvw2 = uvwt2(1:3,:); % pair down to just winds
            uvwtmean(i,1:4) = uvwtmean_; %mean values for (despiked) sonic
                                         %measurements
            uvwmean = uvwtmean(i,1:3); % pair means down to just winds
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
                uvwmeanrot(i,1:3) = uvwmeanrot_; %mean values for despiked and 3D
                                                 %rotated sonic measurements
                
            elseif strcmp(rotation, 'planar') % planar rotation
                UVW2 = uvw2; %in this case, UVW2 !! is not !! rotated
                uvwmeanrot(i,1:3) = NaN*ones(3,1);
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
                                                     sitecode, num, PWATER, ...
                                                     uvwmeanrot(i, :), IRGAP, ...
                                                     speed(i), temp2, ...
                                                     theta(i));
                
            elseif lag==1
                [CO2_,H2O_,FCO2_,FH2O_,HSENSIBLE_,HLATENT_,RHOM_,TDRY_,IOKNUM_, ...
                 LAGCO2, LAGH2O,zoL] = flux7500freeman_lag(UVW2,uvwmean, ...
                                                           USTAR_,SONDIAG, ...
                                                           CO2',H2O',TD', ...
                                                           RHO',IRGADIAG',rotation, ...
                                                           sitecode,num, ...
                                                           PWATER, ...
                                                           uvwmeanrot(i,1:3), ...
                                                           hsout,IRGAP, ...
                                                           theta(i));
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

            julday(i,1) = jday;
            numdate(i,1) = date;
            
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
                outputs_on = TX_site_known_calibrations(numdate, decimal_day);
            end
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % produce outputs
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

            no_data = size(this_half_hour, 1) == 0;
            
            if ~outputs_on | no_data
                julday(i,1)=jday;
                numdate(i,1)=date;
                %assign NaN's for missing data:
                uvwtmean(i,1:4)=NaN;
                uvwmeanrot(i,1:3)=NaN;
                theta(i,1)=NaN;
                uvwtvar(i,1:4)=NaN;
                covuvwt(i,1:6)=NaN;
                ustar(i,1)=NaN;
                speed(i,1)=NaN;
                hbuoyantout(i,1)=NaN;
                transportout(i,1)=NaN;
                co2out(i,1:5)=NaN;
                h2oout(i,1:5)=NaN;
                fco2out(i,1:5)=NaN;
                fh2oout(i,1:6)=NaN;
                hsout_flux(i,1:4)=NaN;
                hlout(i,1:3)=NaN;
                rhomout(i,1:3)=NaN;
                tdryout(i,1)=  NaN;
                iokout(i,1:2)=NaN;
                removed(i,1:5) = NaN;
                zoLout(i,1) = NaN;
                if ~outputs_on
                    uvwtvar(i,1:4)=UVWTVAR_;   %variances of ROTATED wind
                                               %components and the sonic
                                               %temperature
                    covuvwt(i,1:6)=COVUVWT_;   %covariances of ROTATED wind
                                               %components and the sonic temperature
                    hbuoyantout(i,1)=HBUOYANT_;  %bouyancy flux (W m-2)
                    ustar(i,1)=USTAR_;  % NX1 friction velocity (m/s)
                    transportout(i,1)=TRANSPORT_;  %turblent transport
                    u_vector(i,1:3) = u_vector_;
                    w_mean(i,1) = w_mean_; %this is rotated from planar fit
                elseif no_data
                    rH(i,1)=NaN;
                    u_vector(i,1) = NaN;
                    w_mean(i,1) = NaN;
                    if lag==1;
                        lagCO2(i,1: 9)=NaN;
                        lagH2O(i,1:5)=NaN;
                    end
                end
            end
        end % end if-then for enough data or not enough data
    end  % end 48 half-hour for-loop

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

    if writefluxall
        disp('preparing to enter data in FLUX_all file....')
        fluxallfile = fullfile(outfolder, [site, '_FLUX_all.xls']);
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
                    time_match1=time_match;  % set time match lag equal to time match if
                                             % matching row found; otherwise leave as NaN
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
                  'along-wind velocity variance','cross-wind velocity variance', ...
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


