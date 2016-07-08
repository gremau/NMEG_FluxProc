%Program to read 30-min data in from flux_all files, make corrections, and
%write the corrected fluxes back to the flux_all files.  This is used only
%when the ts data are not available for time periods but the 30-min data
%are

%Written by John DeLong summer 2008

% Edited by Mike Fuller, July 2011
% This version was edited to add the 'New GLand' site to the list of sites,
% fix a faulty block of 'if-else' statements that used incorrect logical
% flow and unecessary comparison statements (i.e. '==1'), and to add 
% exception handling for a incorrectly formed input file (xls file)and when 
% NANs are encountered for date/time.

% Further updated by Timothy W. Hilton, Sep 2011 to add updated angles and
% instrument height for PJ girdle site.

%UNM_30min_flux_processor_v2.1

function [] = UNM_30min_flux_processor_Tim(sitecode,year,first_row,last_row)

% This is now deprecated - see fill_30min_flux_processor.m
error( 'This file is now deprecated' );

% sitecode=7;
% year=2008;
% first_row=10228;
% last_row=10707;

% MF:
% Flux-All File Columns used to index the input data range.
% data1c1-data1c2 = TOA5 Data Section of Flux_All file
% data2c1-data2c2 = MATLAB Processed Section of Flux_All file
% (the index of these columns in the flux-all file differs among sites and
% years):
%
%   timestamp_col = "TOA5 Timestamp" column
%   bad_variance_col = "Bad Variance" column 
%   data1c1 = "Fc_wpl" column (corrected carbon flux)
%   data1c2 = "rain_Tot" (total rain precipitation)
%   data2c1 = "jday" (Julian day)
%   data2c2 = "w_mean" (last column of "MATLAB processed" section)


newfile_ext = '30minfill';

if sitecode == 1
    site = 'GLand';
    z_CSAT = 3.2; sep2 = 0.191; angle = 28.94; h_canopy = 0.25;
    timestamp_col = 'CG';
    bad_variance_col = 'BP';
    if year == 2007
        timestamp_col = 'CG';
        bad_variance_col = 'BP';
        data1c1 = 'CH';
        data1c2 = 'IL';
        data2c1 = 'J';
        data2c2 = 'BQ';
        cov_Ux_Ux = -9999;          % next three lines added by MF
        cov_Uy_Uy = -9999;
        cov_Uz_Uz = -9999;
    else                            % added by MF
        timestamp_col = 'BW';
        bad_variance_col = 'BP';
        data1c1 = 'BX';
        data1c2 = 'IC';
        data2c1 = 'J';
        data2c2 = 'BU';
        cov_Ux_Ux = -9999;
        cov_Uy_Uy = -9999;
        cov_Uz_Uz = -9999;
    end
    
elseif sitecode == 2
    site = 'SLand';
    z_CSAT = 3.2; sep2 = 0.134; angle = 11.18; h_canopy = 0.8;
    timestamp_col = 'CG';
    bad_variance_col = 'BP';
    data1c1 = 'CH';
    data1c2 = 'IL';
    data2c1 = 'J';
    data2c2 = 'BQ';
    cov_Ux_Ux = -9999;  % this line added by MF
    
elseif sitecode == 3
    site = 'JSav';
    z_CSAT = 10.35; sep2 = .2; angle = 25; h_canopy = 3;
    if year == 2009 || year == 2010
        timestamp_col = 'BW';
        bad_variance_col = 'BP';
        data1c1 = 'BX';
        data1c2 = 'IE';
        data2c1 = 'J';
        data2c2 = 'BU';
    end
    
elseif sitecode == 4
    site = 'PJ';
    z_CSAT = 8.2; sep2 = .143; angle = 19.3; h_canopy = 4;
    if year == 2009
        timestamp_col = 'CG';
        bad_variance_col = 'BX';
    elseif year == 2010
        timestamp_col = 'BW';
        bad_variance_col = 'BP';
        data1c1 = 'BX';
        data1c2 = 'EZ';
        data2c1 = 'J';
        data2c2 = 'BU';
    end
elseif sitecode == 5
    z_CSAT = 24.02; sep2 = 0.15; angle = 15.266; h_canopy = 17.428;
    site = 'PPine';
    if year == 2009
        timestamp_col = 'CG';
        bad_variance_col = 'BP';
        data1c1 = 'CH';
        data1c2 = 'GF';
        data2c1 = 'J';
        data2c2 = 'BU';
    elseif year == 2010
        timestamp_col = 'CG';
        bad_variance_col = 'BP';
        data1c1 = 'CH';
        data1c2 = 'GG';
        data2c1 = 'J';
        data2c2 = 'BU';
    elseif year == 2011
        timestamp_col = 'BW';
        bad_variance_col = 'BP';
        data1c1 = 'BX';
        data1c2 = 'FW';
        data2c1 = 'J';
        data2c2 = 'BU';
    end
    
elseif sitecode == 6
    site = 'MCon';
    z_CSAT = 23.9; sep2 = 0.375; angle = 71.66; h_canopy = 16.56;
    if year == 2009
        timestamp_col = 'CG';
        bad_variance_col = 'BP';
        data1c1 = 'CH';
        data1c2 = 'GF';
        data2c1 = 'J';
        data2c2 = 'BU';
    end
    if year == 2010
        timestamp_col = 'CG';
        bad_variance_col = 'BP';
        data1c1 = 'CH';
        data1c2 = 'GI';
        data2c1 = 'J';
        data2c2 = 'BU';
    end
    
elseif sitecode == 7
    site = 'TX';
    z_CSAT = 8.75; sep2 = .2; angle = 25; h_canopy = 2.5;
    if year == 2008
        timestamp_col = 'BV';
        bad_variance_col = 'BP';
        data1c1 = 'BW';
        data1c2 = 'FC';
        data2c1 = 'J';
        data2c2 = 'BU';
    elseif year == 2009
        timestamp_col = 'CG';
        bad_variance_col = 'BX';
        data1c1 = 'CH';
        data1c2 = 'GP';
        data2c1 = 'J';
        data2c2 = 'BQ';
    end
    
elseif sitecode == 8
    site = 'TX_forest';
    timestamp_col = 'BV';
    bad_variance_col = 'BP';
    z_CSAT = 15.24; sep2 = .11; angle = 13.79; h_canopy = 7.62;
    if year == 2008
        timestamp_col = 'CG';
        bad_variance_col = 'BX';
        data1c1 = 'CH';
        data1c2 = 'EN';
        data2c1 = 'J';
        data2c2 = 'BQ';
    elseif year == 2009
        timestamp_col = 'CG';
        bad_variance_col = 'BX';
        data1c1 = 'CH';
        data1c2 = 'EN';
        data2c1 = 'J';
        data2c2 = 'BQ';
    end
    
elseif sitecode == 9
    site = 'TX_grassland';
    z_CSAT = 4; sep2 = .19; angle = 31.59; h_canopy = 1;
    timestamp_col = 'BV';
    bad_variance_col = 'BP';
    if year == 2008
        timestamp_col = 'CG';
        bad_variance_col = 'BX';
        data1c1 = 'CH';
        data1c2 = 'ET';
        data2c1 = 'J';
        data2c2 = 'BQ';
    elseif year == 2009
        timestamp_col = 'CG';
        bad_variance_col = 'BX';
        data1c1 = 'CH';
        data1c2 = 'EN';
        data2c1 = 'J';
        data2c2 = 'BQ';
    end
    
elseif sitecode == 10
    % 5 Sep 2011 - changed z_CSAT from 5.5 to 6.5 (as per Marcy's instruction)
    site = 'PJ_girdle';
    z_CSAT = 5.5; sep2 = 0.194; angle = 13.3; h_canopy = 4;
    if year == 2009
        timestamp_col = 'BV';
        bad_variance_col = 'BP';
    elseif year == 2010
        timestamp_col = 'BW';
        bad_variance_col = 'BP';
        data1c1 = 'BX';
        data1c2 = 'FE';
        data2c1 = 'J';
    elseif year == 2011
        if first_row < 10660 & last_row >= 10660
            ME = MException('UNM_30min_flux_processor', 'PJgirdle instrument height and angles changed on 11 Aug 2011.  Please do not call UNM_30min_flux_processor for dates spanning 11 Aug 2011.');
            throw(ME);
        end
        if first_row >= 10660
            z_CSAT = 6.5; sep2 = 0.194; angle = 16.71; h_canopy = 4;          
        end
    elseif year >= 2012
        z_CSAT = 6.5; sep2 = 0.194; angle = 16.71; h_canopy = 4;
    end
    
elseif sitecode == 11 % added July 2011 by MF
    site = 'New_GLand';
    z_CSAT = 3.2; sep2 = 0.142; angle = 21.67; h_canopy = 0.25;
    if year == 2010 || year == 2011
        timestamp_col = 'BW';
        bad_variance_col = 'BP';
        data1c1 = 'BX';
        data1c2 = 'HF';
        data2c1 = 'J';
        data2c2 = 'BU';
        
    end
    
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Set up files and read in data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if year <= 2008
    filename = strcat(site,'_flux_all_',num2str(year))
    filein = strcat('C:\Research_Flux_Towers\Flux_Tower_Data_by_Site\',site,'\',filename); % assemble path to file
    datarange = strcat(data1c1,num2str(first_row),':',data1c2,num2str(last_row)); % specify what portion of spreadsheet to read in
    headerrange = strcat(data1c1,'2:',data1c2,'2'); % specify portion of spreadsheet that is headers

    [num text] = xlsread(filein,headerrange); % read in the text in the header
    headertext = text; % assign column headers to header text array

    [num text]=xlsread(filein,datarange);  %does not read in first column because its text!!!!!!!!
    data = num; % assign data to data array

    datarange2 = strcat(data2c1,num2str(first_row),':',data2c2,num2str(last_row));
    [num text]=xlsread(filein,datarange2);
    DATA_IN = num;

    % timestamps are text so read them in separately
    [num text] = xlsread(filein,strcat(timestamp_col,num2str(first_row),':',timestamp_col,num2str(last_row)));
    timestamp = text; % assign timestamp array

    % added by MF
    try
        [year2 month day hour minute second] = datevec(timestamp); % ,'dd/mm/yyyy HH:MM:SS'); %break timestamp into usable data and time variables
                                                                   %[year month day hour minute second] = datevec(timestamp); %break timestamp into usable data and time variables
    catch err
        error('timestamp value found does not seem to be a date; check that correct column is being used for this input file');
    end

    bad_v = NaN(nrows);
    [num text] = xlsread(filein,strcat(bad_variance_col,num2str(first_row),':',bad_variance_col,num2str(last_row))); % 
else
    
    % Look for an already filled fluxall to use
    fname = sprintf( '%s_FLUX_all_%d_%s.txt', site, year, newfile_ext );
    filled_fname = fullfile( get_site_directory( sitecode ), fname );
    % Check if file exists
    if exist( filled_fname )
        ds = UNM_parse_fluxall_txt_file( UNM_sites( sitecode ), year, ...
            'file', filled_fname );
    % If it doesn't exist use the original fluxall file
    else
        ds = UNM_parse_fluxall_txt_file( UNM_sites( sitecode ), year );
    end
    
    [ year2 month day hour minute second ] = datevec( ds.timestamp );
    timestamp = ds.timestamp;
    ds.timestamp = [];
    headertext = ds.Properties.VarNames;
    data = double( ds( first_row:last_row, : ) );
end    
%bad_v = num; % assign bad_variance array

jday = datenum(timestamp) - datenum( year2(1), 1, 0 );
jday = jday( first_row:last_row );
ncol = size(data,2); % find number of columns for use in locating headers below
nrows = size(data,1);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 30-minute data vary in column and header name across sites and years, 
% so we are using this string comparison function to locate data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Edited from original if-else block (MF)
% Note: this block should also contain 'else' statements for the FALSE case
% of each evaluation

for i=1:ncol
    
    if strcmp('Ts_Avg',headertext(i)) || strcmp('Ts_mean',headertext(i)) || strcmp('Ts_a',headertext(i))
        Ts_meanC = data(:,i); % read in in C 
        Ts_meanK = data(:,i) + 273.15; % converted to K
    end
    if strcmp('wnd_dir_compass',headertext(i)) || strcmp('cmpss_dir',headertext(i))
        wind_direction = data(:,i); % read in in degrees and just written back out
    end
    if strcmp('rslt_wnd_spd',headertext(i)) || strcmp('wnd_spd_a',headertext(i))
        wind_speed = data(:,i); % read in in m per s and just written back out
    end
    if strcmp('cov_Ux_Ts',headertext(i)) || strcmp('cov_Ts_Ux',headertext(i)) || strcmp('Ux_Ts',headertext(i))
        cov_Ts_Ux = data(:,i); % this is cov b/w t and u
    end
    if strcmp('cov_Uy_Ts',headertext(i)) || strcmp('cov_Ts_Uy',headertext(i)) || strcmp('Uy_Ts',headertext(i))
        cov_Ts_Uy = data(:,i); % this is cov b/w t and y
    end
    if strcmp('cov_Uz_Ts',headertext(i)) || strcmp('cov_Ts_Uz',headertext(i)) || strcmp('Uz_Ts',headertext(i))
        cov_Ts_Uz = data(:,i); % this is cov b/w t and w
    end
    if strcmp('cov_Uz_Uz',headertext(i)) || strcmp('stdev_Uz',headertext(i))
        cov_Uz_Uz = data(:,i); % this is vertical wind varianc
    end
    if strcmp('cov_Ux_Ux',headertext(i)) || strcmp('stdev_Ux',headertext(i))
        cov_Ux_Ux = data(:,i); % this is along wind variance
    end
    if strcmp('cov_Uy_Uy',headertext(i)) || strcmp('stdev_Uy',headertext(i))
        cov_Uy_Uy = data(:,i); % this is across wind variance
    end
    if strcmp('co2_Avg',headertext(i)) || strcmp('co2_mean',headertext(i))...
            || strcmp('co2_a',headertext(i)) || strcmp('co2_mean_Avg',headertext(i))
        co2_mean = (data(:,i))./44; % read in in mg per m^3 but converted to mmol per m^3
    end
    if strcmp('cov_Ux_co2',headertext(i)) || strcmp('cov_co2_Ux',headertext(i)) || strcmp('Ux_co2',headertext(i))
        cov_co2_Ux = data(:,i); % read in in mg per m^2 per s
    end
    if strcmp('cov_Uy_co2',headertext(i)) || strcmp('cov_co2_Uy',headertext(i)) || strcmp('Uy_co2',headertext(i))
        cov_co2_Uy = data(:,i); % read in in mg per m^2 per s
    end
    if strcmp('cov_Uz_co2',headertext(i)) || strcmp('cov_co2_Uz',headertext(i)) || strcmp('Uz_co2',headertext(i))
        cov_co2_Uz = data(:,i); % read in in mg per m^2 per s
    end
    if strcmp('h2o_Avg',headertext(i)) || strcmp('h2o_mean',headertext(i))...
            || strcmp('h2o_a',headertext(i)) || strcmp('h2o_mean_Avg',headertext(i))
        h2o_Avg = data(:,i)./0.018; % read in in g per m^3 and converted to mmol per m^3
    end
    if strcmp('cov_Ux_h2o',headertext(i)) || strcmp('cov_h2o_Ux',headertext(i)) || strcmp('Ux_h2o',headertext(i))
        cov_h2o_Ux = data(:,i)./0.018; % read in in g per m^2 per s and converted to mmol per m^2 per s
    end
    if strcmp('cov_Uy_h2o',headertext(i)) || strcmp('cov_h2o_Uy',headertext(i)) || strcmp('Uy_h2o',headertext(i))
        cov_h2o_Uy = data(:,i)./0.018; % read in in g per m^2 per s and converted to mmol per m^2 per s
    end
    if strcmp('cov_Uz_h2o',headertext(i)) || strcmp('cov_h2o_Uz',headertext(i)) || strcmp('Uz_h2o',headertext(i))
        cov_h2o_Uz = data(:,i)./0.018; % read in in g per m^2 per s and converted to mmol per m^2 per s
    end
    if strcmp('Ux_Avg',headertext(i)) || strcmp('Ux_a',headertext(i))
        umean = data(:,i);
        disp('INITIALIZED UMEAN');
    end
    if strcmp('Uy_Avg',headertext(i)) || strcmp('Uy_a',headertext(i))
        vmean = data(:,i);
    end
    if strcmp('Uz_Avg',headertext(i)) || strcmp('Uz_a',headertext(i))
        wmean = data(:,i);
    end
    if strcmp('cov_Ux_Uy',headertext(i)) || strcmp('Ux_Uy',headertext(i)) 
        uv = data(:,i); %cov_Ux_Uy aka 12 , 21, aka uv,vu
    end
    if strcmp('cov_Uz_Ux',headertext(i)) || strcmp('cov_Ux_Uz',headertext(i)) || strcmp('Uz_Ux',headertext(i))
        uw = data(:,i); %cov_Ux_Uz aka 13 , 31, aka uw,wu
    end
    if strcmp('cov_Uz_Uy',headertext(i)) || strcmp('cov_Uy_Uz',headertext(i)) || strcmp('Uz_Uy',headertext(i))
        vw = data(:,i); %cov_Uy_Uz aka 23 , 32, aka vw,wv
    end
    if strcmp('press_Avg',headertext(i)) || strcmp('press_mean',headertext(i)) || strcmp('press_a',headertext(i))
        press_mean = data(:,i); % read in in kPa
    end
    if strcmp('RH',headertext(i))
        rH = 0.01.*data(:,i); % read in in kPa    
    end
end

% exception handling statement added by MF
try
    uvwmean = [umean vmean wmean]; % pool winds for use below
catch err
    error('Could not initialize wind parameters; check TOA5 Timestamp column of excel file for missing date values');
end

h2o_Avg = h2o_Avg - 195;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Dry air corrections
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% calculate the partial pressure of h2o vapor. Use the sonic temperaure to
% approximate the dry air temperature. This is shown below to give a maximum
% error (for this day) in the partial pressure of 0.95 percent 
%
% Pw (KPa) = (n/V) * R_u * T * 10e-6%
%   - n/V   = LI7500 output in mmol/m^3 wet air
%   - R_u   = 8.314 J/mol K
%   - T     = dry air temp in K
%   - 10e-6 = converts mmol to mol and Pa to KPa
PW = 1e-6.*8.314.*h2o_Avg.*Ts_meanK;

% calculate dry air temperature from sonic temperature using Gaynor eq:
Td = Ts_meanK./(1 + 0.32.*PW./press_mean);

% Make an iteration on the calculation of Pw, using the dry air temperature
PW = 1e-6.*8.314.*h2o_Avg.*Td;

% recalculate dry temperature w/new pressure
TD = Ts_meanK./(1 + 0.321.*PW./press_mean);

% calculate wet air molar density (mol wet air / m^3 wet air)
%  (n/V)_a = P/R_u/T  
%          = 1e3/8.314*P/T
rhomtotal  = (1e3./8.314).*press_mean./TD;

% calculate mol fraction of water vapor (mmol h2o/mol moist air) in wet air
h2owet = h2o_Avg./rhomtotal;

% calculate mol fraction of co2 (umol co2/mol moist air) in moist air
co2wet = 1e3.*co2_mean./rhomtotal;

% Assume wet air and the partial pressure of dry air is the output of the
% irga minus the vapor pressure
Pa = press_mean - PW;

% calculate dry air molar density (mol dry air / m^3 wet air)%
%  (n/V)_a = Pa/R_u/T%  
%          = 1e3 / 8.314 * Pa /T
rhomdry = (1e3/8.314).*Pa./TD;
rhomwater = rhomtotal - rhomdry;
rhotot = rhomdry.*29./1000 + rhomwater.*18./1000;

% calculate mol fraction of water vapor (mmol h2o/mol dry air) in dry air
h2odry = h2o_Avg./rhomdry;

% calculate mol fraction of co2 (umol co2/mol dry air) in dry air
co2dry = 1e3.*co2_mean./rhomdry;

% calculate relative humidity
meanTinC = TD-273.15;
es = 0.611 .* exp(17.502.*meanTinC./(meanTinC + 240.97));
rH = PW./es;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Unit corrections for co2 and h2o
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

co2_mean_out = co2_mean.*1000./rhomdry;
h2o_Avg_out = h2o_Avg./rhomdry;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Planar rotation, massman, and wpl corrections, run each row at a time
% through a for looop
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

for i = 1:nrows
    

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % 1 Planar rotation
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    USTAR(i) = sqrt(sqrt(uw(i)^2 + vw(i)^2)); % calculate unrotated ustar
    speed(i) = sqrt((umean(i)^2) + (vmean(i)^2) + (wmean(i)^2));

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Check that you have good data on the basis of speed < 20
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    if speed(i) <20
        
        % enter planar coefficients broken down by various factors
        if sitecode == 1
            if speed(i) >= 5
                b0 = 0.152528949;
                b1 = -0.00082989;
                b2 = 0.002517913;
                k(1) = 0.000829887;
                k(2) = -0.002517904;
                k(3) = 0.999996486;
            else
                b0 = 0.025221417;
                b1 = 0.011187435;
                b2 = 0.005053646;
                k(1) = -0.011186592;
                k(2) = -0.005053265;
                k(3) = 0.999924659;
            end
            
        elseif sitecode == 2 % these are for shrubland
            if speed(i) >= 5
                b0 = 0.153116813;
                b1 = 0.016330935;
                b2 = -0.018475587;
                k(1) = -0.016325972;
                k(2) = 0.018469973;
                k(3) = 0.999696115;
            else
                b0 = 0.046197667;
                b1 = 0.024851316;
                b2 = -0.018716161;
                k(1) = -0.024839298;
                k(2) = 0.01870711;
                k(3) = 0.99951641;
            end

        elseif sitecode == 3 % these are for juniper-savanna
            
            if speed(i) >= 5
                b0 = 0.081104622;
                b1 = -0.005862329;
                b2 = -0.015991732;
                k(1) = 0.005861479;
                k(2) = 0.015989413;
                k(3) = 0.99985498;
            else
                b0 = 0.02499662;
                b1 = -0.002888242;
                b2 = -0.013527774;
                k(1) = 0.002887966;
                k(2) = 0.01352648;
                k(3) = 0.999904342;
            end

        elseif sitecode == 4
            if speed(i) >= 5
                b0 = 0.152528949;
                b1 = -0.00082989;
                b2 = 0.002517913;
                k(1) = 0.000829887;
                k(2) = -0.002517904;
                k(3) = 0.999996486;
            else
                b0 = 0.025221417;
                b1 = 0.011187435;
                b2 = 0.005053646;
                k(1) = -0.011186592;
                k(2) = -0.005053265;
                k(3) = 0.999924659;
            end
            
        elseif sitecode == 5
            if speed(i) >= 5            
                b0 = -0.201583097;
                b1 = 0.039964498;
                b2 = 0.042832557;
                k(1) = -0.039896099;
                k(2) = -0.04275925;
                k(3) = 0.998288509;
            else
                b0 = 0.008839609;
                b1 = 0.020435491;
                b2 = 0.025895171;
                k(1) = -0.020424381;
                k(2) = -0.025881093;
                k(3) = 0.999456359;
            end
            
        elseif sitecode == 6
            if speed(i) >= 5            
                b0 = 0.259543188;
                b1 = -0.004703906;
                b2 = 0.014195398;
                k(1) = 0.00470338;
                k(2) = -0.014193811;
                k(3) = 0.999888201;
            else
                b0 = 0.079961079;
                b1 = -0.024930957;
                b2 = 0.044809422;
                k(1) = 0.024898245;
                k(2) = -0.044750626;
                k(3) = 0.998687869;
            end
            

        elseif sitecode == 7 && year == 2005 && month(1) < 5 % use one set of values for
                                                             % first seven months, not separated out by windspeed, then use the same values as 2006         
            b0 = 0.024873451;
            b1 = 0.002279925;
            b2 = 0.002839777;
            k(1) = -0.00227991;
            k(2) = -0.002839758;
            k(3) = 0.999993369;

        elseif sitecode == 7 && year == 2005 && month(1) >= 5 % latter half of 2005
                                                              % use same as 2006
            b0 = 0.064455667;
            b1 = 0.001620006;
            b2 = 0.004444167;
            k(1) = -0.001619988;
            k(2) = -0.004444117;
            k(3) = 0.999988813;

        elseif sitecode == 7 && year == 2006 % all of 2006 looks pretty consistent, use one set of data
            b0 = 0.064455667;
            b1 = 0.001620006;
            b2 = 0.004444167;
            k(1) = -0.001619988;
            k(2) = -0.004444117;
            k(3) = 0.999988813;

        elseif sitecode == 7 && year == 2007 && month(1) < 3 % first 2 months of 2007
                                                             % use same as 2006
            b0 = 0.064455667;
            b1 = 0.001620006;
            b2 = 0.004444167;
            k(1) = -0.001619988;
            k(2) = -0.004444117;
            k(3) = 0.999988813;

        elseif sitecode == 7 && year == 2007 && month(1) == 3 || sitecode == 7 && year == 2007 && month(1) == 4
            % March and April 2007 has their own set of coefficients
            b0 = 0.064455667;
            b1 = 0.001620006;
            b2 = 0.004444167;
            k(1) = -0.001619988;
            k(2) = -0.004444117;
            k(3) = 0.999988813;

        elseif sitecode == 7 && year == 2007 && month(1) >= 5 %after that, use a new set of
                                                              % coefficients calculated with only the data in the last 6 months of 2007 
            b0 = -0.007905583;
            b1 = 0.012986531;
            b2 = -0.000801434;
            k(1) = -0.012985432;
            k(2) = 0.000801367;
            k(3) = 0.999915365;
            
            
        elseif sitecode == 7 && year == 2008 || year ==2009% Using the same as the latter part of 2007 
            b0 = -0.007905583;
            b1 = 0.012986531;
            b2 = -0.000801434;
            k(1) = -0.012985432;
            k(2) = 0.000801367;
            k(3) = 0.999915365;

        elseif sitecode == 8 % TX_forest
            if wind_direction(i) >= 0 && wind_direction(i) <= 60
                b0 = 0.224838191;
                b1 = 0.051189541;
                b2 = -0.031249502;
                k(1) = -0.046221527;
                k(2) = 0.014738558;
                k(3) = 0.998206387;
            elseif wind_direction(i) > 60 && wind_direction(i) <= 210
                b0 = 0.094117303;
                b1 = 0.03882402;
                b2 = 0.011170481;
                k(1) = -0.038792377;
                k(2) = -0.011161377;
                k(3) = 0.999184955;
            elseif wind_direction(i) > 210 && wind_direction(i) <= 270
                b0 = 0.070326918;
                b1 = -0.026290012;
                b2 = -0.009114614;
                k(1) = 0.02627984;
                k(2) = 0.009111088;
                k(3) = 0.999613104;
            elseif wind_direction(i) > 270 && wind_direction(i) <= 360
                b0 = 0.215938294;
                b1 = 0.123314215;
                b2 = 0.000787889;
                k(1) = -0.122387155;
                k(2) = -0.000781966;
                k(3) = 0.992482127;
            end    

        elseif sitecode == 9 % TX_grassland
            b0 = 0.017508885;
            b1 = -0.005871475;
            b2 = 0.017895419;
            k(1) = 0.005870434;
            k(2) = -0.017892246;
            k(3) = 0.999822687;

        elseif sitecode == 10  % pinyon juniper - girdled
                               %             if speed >= 5
                               %                 b0 = -0.01340991;
                               %                 b1 = -0.01848391;
                               %                 b2 =  0.01754080;
                               %                 k(1) = 0.01847792;
                               %                 k(2) =-0.01753510;
                               %                 k(3) = 0.99967549;
                               %             else
                               %                 b0 =  -0.05509318;
                               %                 b1 =  -0.01227282;
                               %                 b2 =   0.01297221;
                               %                 k(1) = 0.01227087;
                               %                 k(2)= -0.01297014;
                               %                 k(3) = 0.99984058;
                               %             end   
            if speed >= 5
                b0 = -0.0344557038769674;
                b1 = -0.0128424391588686;
                b2 =  0.0160405052917033;
                k(1) = 0.012839728810921;
                k(2) =-0.0160371200040598;
                k(3) = 0.99978895380277;
            else
                b0 =  -0.0473758714816513;
                b1 =  -0.0128600161662158;
                b2 =   0.0101393306242113;
                k(1) = 0.0128582920745777;
                k(2)= -0.0101379712841514;
                k(3) = 0.99986593394473;
            end   
            
        elseif sitecode == 11 % New GLand; Values taken from other flux programs, July 2011 (MF)
            if speed(i) >= 5            
                b0 = 0.0430287;
                b1 = 0.351210;
                b2 = -0.0336278;
                k(1) = -0.0350796;
                k(2) = 0.0335881;
                k(3) = 0.9988199;
            else
                b0 = 0.0430287;
                b1 = 0.351210;
                b2 = -0.0336278;
                k(1) = -0.0350796;
                k(2) = 0.0335881;
                k(3) = 0.9988199;
            end
            
        end

        
        
        % determine unit vectors i,j (parallel to new coordinate x and y axes)
        j(i,:) = cross(k,uvwmean(i,:));
        j(i,:) = j(i,:)/(sum(j(i,:).*j(i,:)))^0.5;
        l(i,:) = cross(j(i,:),k); % changed i to l here to be compatible with for loop

        % rotating co2 flux
        if sitecode==7
            R=8.3143e-3;
            hh=(1./(R.*(Ts_meanK(i)./press_mean(i)).*1000)).*44; % This is the conversion from mumol mol to mg m3 for CO2 for TX
            cov_co2_Ux(i)=cov_co2_Ux(i).*hh;
            cov_co2_Uy(i)=cov_co2_Uy(i).*hh;
            cov_co2_Uz(i)=cov_co2_Uz(i).*hh;
        end
        
        C(i,:) = [cov_co2_Ux(i) cov_co2_Uy(i) cov_co2_Uz(i)];
        uxc_rot(i) = sum(l(i,:).*C(i,:));
        vxc_rot(i) = sum(j(i,:).*C(i,:));
        wxc_rot(i) = sum(k.*C(i,:));
        flux_co2(i) = wxc_rot(i); % in mg per m^2 s, original flux_co2(i)covariance only rotated
                                  % flux_co2(i) = ((flux_co2(i)./1000)./44).*1000000; % mumols for regression
                                  % flux_co2(i) = (flux_co2(i).*1.1623)-0.096; % Correction based on regression in Futher_flux_corrections .xls file
                                  % flux_co2(i) = (flux_co2(i)./1000000)*44*1000; % back to mg
        
        % rotating sensible heat flux
        cov_Ts_Ux(i);
        cov_Ts_Uy(i);
        cov_Ts_Uz(i);
        
        H(i,:) = [cov_Ts_Ux(i) cov_Ts_Uy(i) cov_Ts_Uz(i)];
        uxT_rot(i) = sum(l(i,:).*H(i,:));
        vxT_rot(i) = sum(j(i,:).*H(i,:));
        wxT_rot(i) = sum(k.*H(i,:));
        wTrot_dry(i) = wxT_rot(i)/(1 + 0.321*PW(i)/press_mean(i)); % take vertical component and convert it to dry air
        cpd = 1005;
        HSdry(i) = 28.966/1000*rhomdry(i)*cpd*wTrot_dry(i);
        HSwet(i) = 28.966/1000*rhomdry(i)*cpd*wxT_rot(i);
        HSwetwet(i) = 28.966/1000*rhomtotal(i)*cpd*wxT_rot(i);
        
        % rotating water and calculating latent heat flux from that
        
        if sitecode==7
            R=8.3143e-3;
            hh=(1./(R.*(Ts_meanK(i)./press_mean(i)))).*0.018; % This is the conversion from mumol mol to mg m3 for CO2 for TX
            cov_h2o_Ux(i)=cov_h2o_Ux(i).*hh;
            cov_h2o_Uy(i)=cov_h2o_Uy(i).*hh;
            cov_h2o_Uz(i)=cov_h2o_Uz(i).*hh;
        end
        
        W(i,:) = [cov_h2o_Ux(i) cov_h2o_Uy(i) cov_h2o_Uz(i)];
        uxh2o_rot(i) = sum(l(i,:).*W(i,:));
        vxh2o_rot(i) = sum(j(i,:).*W(i,:));
        wxh2o_rot(i) = sum(k.*W(i,:));
        flux_h2o(i) = wxh2o_rot(i); % flux still in mmol per m^2 per s
        Lv = (2.501-0.00237*(TD(i)-273.15))*10^3; % calculate latent heat of vaporization
        flux_HL(i) = 18.016/1000*Lv*wxh2o_rot(i); % calculate latent heat flux from water flux and Lv
                                                  % flux_HL(i) = (flux_HL(i).*1.1484)+3.6589; % Correction based on regression in Futher_flux_corrections .xls file
                                                  % flux_h2o(i) = ((flux_HL(i)./Lv)./18.016).*1000;
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 2 Massman
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        % calculate z and L
        z = z_CSAT/(0.7*h_canopy);
        L = -((USTAR(i))^3*TD(i))/(0.4 * 9.81 * cov_Ts_Uz(i));
        
        % CALL MASSMAN
        [X_op_C,X_op_H,X_T,zoL]= UNM_massman(z,L,uvwmean(i,:),sep2,angle);

        HSdry_massman(i) = HSdry(i)./X_T;
        flux_h2o_massman(i) = flux_h2o(i)/X_op_H; % flux still in mmol per m^2 per s
        flux_co2_massman(i) = (flux_co2(i)/X_op_C)*1000/44; %flux still in mg per m^2 s converted to umol per m^2 s

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 3 WPL
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        % calculate densities in grams/m^3 moist air
        rhoa(i) = rhomdry(i)*28.966;
        rhov(i) = (rhomtotal(i)-rhomdry(i))*18.016;
        rhoc(i) = co2_mean(i)*44/1000;
        rhoa_out(i) = rhoa(i)/28.966;
        rhov_out(i) = rhov(i)/18.016;
        rhoc_out(i) = rhoc(i)/44;
        
        mu = 28.966/18.016; % g per mol divided by g per mol >> unitless
        sigma = rhov(i)/rhoa(i); % g per m^3 divided by g per m^3 >> unitless
        
        
        % make WPL corrections for CO2 fluxes
        
        Fc_raw(i) = flux_co2(i).*1000./44; % convert rotated co2 flux back to umol per m^3
        Fc_water_term(i) = mu*rhoc(i)/rhoa(i)*flux_h2o(i)*0.018*(10^6/44);
        Fc_heat_term_massman(i) = (1+mu*sigma)*rhoc(i)/TD(i)*HSdry_massman(i)/28.966*1000/cpd/rhomdry(i)*(10^6/44);
        Fc_corr_massman_ourwpl(i) = flux_co2_massman(i) + Fc_water_term(i) + Fc_heat_term_massman(i);
        
        % make WPL corrections for H2O fluxes    
        E_water_term(i) = (1+mu*sigma)*flux_h2o(i)*0.018*(10^3/18.016);
        E_heat_term_massman(i) = (1+mu*sigma)*rhov(i)/TD(i)*wTrot_dry(i)*(10^3/18.016);
        %flux_h20_massman_wpl_heat(i) = (1+mu*sigma)*rhov(i)/TD(i)*HSdry_massman(i)/28.966*1000/cpd/rhomdry(i)*(10^3/18.016);
        E_corr_massman(i) = E_water_term(i) + E_heat_term_massman(i);
        
        % make WPL corrections for latent heat fluxes
        flux_HL_massman(i) = 18.016/1000*Lv*flux_h2o_massman(i);
        flux_HL_wpl_massman(i) = 18.016/1000*Lv*E_corr_massman(i);
        
        % need this for writing out to spreadsheet - see below
        blank(i) = NaN;
        
    else % Else you have bad data
        rH(i) = NaN;
        USTAR(i) = NaN;
        wTrot_dry(i) = NaN;
        co2_mean_out(i) = NaN;
        h2o_Avg_out(i) = NaN;
        Fc_raw(i) = NaN;
        flux_co2_massman(i) = NaN;
        Fc_water_term(i) = NaN;
        Fc_heat_term_massman(i) = NaN;
        Fc_corr_massman_ourwpl(i) = NaN;
        flux_h2o(i) = NaN;
        flux_h2o_massman(i) = NaN;
        E_water_term(i) = NaN;
        E_heat_term_massman(i) = NaN;
        E_corr_massman(i) = NaN;
        HSdry(i) = NaN;
        HSwet(i) = NaN;
        HSwetwet(i) = NaN;
        HSdry_massman(i) = NaN;
        flux_HL(i) = NaN;
        flux_HL_massman(i) = NaN;
        flux_HL_wpl_massman(i) = NaN;
        rhov(i) = NaN;
        rhoa_out(i) = NaN;
        rhov_out(i) = NaN;
        rhoc_out(i) = NaN;
        blank(i) = NaN;
        
    end
    
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Collect things to write out
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

ds.jday( first_row : last_row ) = jday;
ds.u_mean_unrot( first_row : last_row ) = umean;
ds.v_mean_unrot( first_row : last_row ) = vmean;
ds.w_mean_unrot( first_row : last_row ) = wmean;
ds.temp_mean( first_row : last_row ) = Ts_meanC;
ds.tdry( first_row : last_row ) = TD;
ds.wind_direction( first_row : last_row ) = wind_direction;
ds.speed( first_row : last_row ) = wind_speed;
ds.along_wind_velocity_variance( first_row : last_row ) = cov_Ux_Ux;
ds.cross_wind_velocity_variance( first_row : last_row ) = cov_Uy_Uy;
ds.vertical_wind_velocity_variance( first_row : last_row ) = cov_Uz_Uz;
ds.ut_covariance( first_row : last_row ) = cov_Ts_Ux;
ds.uv_covariance( first_row : last_row ) = cov_Ts_Uy;
ds.wt_covariance( first_row : last_row ) = cov_Ts_Uz;
ds.ustar( first_row : last_row ) = USTAR';
ds.CO2_mean( first_row : last_row ) = co2_mean_out;
ds.H2O_mean( first_row : last_row ) = h2o_Avg_out;
ds.Fc_raw( first_row : last_row ) = Fc_raw';
ds.Fc_water_term( first_row : last_row ) = Fc_water_term';
ds.Fc_raw_massman( first_row : last_row ) = flux_co2_massman';
ds.Fc_heat_term_massman( first_row : last_row ) = Fc_heat_term_massman';
ds.Fc_raw_massman_ourwpl( first_row : last_row ) = Fc_corr_massman_ourwpl'; 
ds.E_raw( first_row : last_row ) = flux_h2o';
ds.E_water_term( first_row : last_row ) = E_water_term';
ds.E_raw_massman( first_row : last_row ) = flux_h2o_massman';
ds.E_heat_term_massman( first_row : last_row ) = E_heat_term_massman';
ds.E_wpl_massman( first_row : last_row ) = E_corr_massman';
ds.SensibleHeat_dry( first_row : last_row ) = HSdry';
ds.SensibleHeat_wet( first_row : last_row ) = HSwet';
ds.SensibleHeat_wetwet( first_row : last_row ) = HSwetwet';
ds.HSdry_massman( first_row : last_row ) = HSdry_massman';
ds.LatentHeat_raw( first_row : last_row ) = flux_HL';
ds.LatentHeat_raw_massman( first_row : last_row ) = flux_HL_massman';
ds.LatentHeat_wpl_massman( first_row : last_row ) = flux_HL_wpl_massman';
ds.rhoa_dry_air_molar_density( first_row : last_row ) = rhoa_out';
ds.rhov_dry_air_molar_density( first_row : last_row ) = rhov_out';
ds.rhoc_dry_air_molar_density( first_row : last_row ) = rhoc_out';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Write fluxes back out to flux_all file
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if year >= 2009
    cdp = card_data_processor( UNM_sites( sitecode ), ...
                               'date_start', datenum( year, 1, 1 ), ...
                               'date_end', datenum( year, 12, 31, ...
                                                    23, 59, 59 ) );
    cdp.write_fluxall( ds, newfile_ext );
else
    error( ['fluxall xls writeout not implemented for years < 2012 -- TWH, ' ...
            '31 Oct 2012' ] );
    fileout = filein;
    %fileout = 'december_output.xls';
    %xlswrite (fileout,DATAOUT,'master',strcat('J',num2str(first_row)));
    %disp('Wrote to flux_all file');

    for i = 1:nrows
        if isnan(bad_v(i))
            TO_WRITE(i,:)=DATAOUT(i,:);
        else
            TO_WRITE(i,:)=DATA_IN(i,:);
        end
    end

    xlswrite (fileout,TO_WRITE,'master',strcat('J',num2str(first_row)));
end

