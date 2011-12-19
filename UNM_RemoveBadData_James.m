% This program was created by Krista Anderson Teixeira in July 2007
% Modified by John DeLong summer 2008 through winter 2008-2009
% The program reads site_fluxall_year excel files and pulls in a
% combination of matlab processed ts data and data logged average 30-min
% flux data.  It then flags values based on a variety of criteria and
% writes out new files that do not have the identified bad values.  It
% writes out a site_flux_all_qc file and a site_flux_all_for_gap_filling
% file to send to the Reichstein online gap-filling program.  It can be
% adjusted to make other subsetted files too.

% This program is set up to run as a function where you enter the command
% along with the sitecode (1-7 see below) and the year.  This means that it
% only runs on files that are broken out by year.

function [] = UNM_RemoveBadData_James(sitecode,year,iteration)

% sitecode key
% 1-GLand
% 2-SLand
% 3-JSav
% 4-PJ
% 5-PPine
% 6-MCon
% 7-TX

write_complete_out_file = 1; %1 to write "[sitename].._qc", -- file with all variables & bad data removed
write_processed_out_file = 0;  %1 to write "[sitename]..._processed"-- file with variables of interest & bad data removed
pie_charts = 0; %1 to make pie charts of data quality
data_for_analyses = 0; %1 to output file with data sorted for specific analyses
make_plots = 0; %make plots of interest-- modify code below
ET_gap_filler = 0; %run ET gap-filler program
write_gap_filling_out_file = 1; %1 to write file for Reichstein's online gap-filling. SET U* LIM (including site- specific ones--comment out) TO 0!!!!!!!!!!

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Specify some details about sites and years
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if sitecode==1; % grassland
    site='GLand';
    if year == 2006
        filelength_n = 11594;
    elseif year == 2007
        filelength_n = 17524;
        lastcolumn='HC';
        ustar_lim = 0.06;
        co2_min = -7; co2_max = 6;
    elseif year == 2008;
        filelength_n = 17572;
        lastcolumn='HD';
        ustar_lim = 0.06;
        co2_min = -10; co2_max = 6;
    elseif year == 2009;
        filelength_n = 2763;
        lastcolumn='HD';
        ustar_lim = 0.06;
        co2_min = -10; co2_max = 6;
    end
    wind_min = 330; wind_max = 30; % these are given a sonic_orient = 180;
    Tdry_min = 240; Tdry_max = 320;
    HS_min = -100; HS_max = 450;
    HSmass_min = -100; HSmass_max = 450;
    LH_min = -150; LH_max = 450;
    rH_min = 0; rH_max = 100;
    h2o_max = 30; h2o_min = 0;

elseif sitecode==2; % shrubland
    site='SLand'    
    if year == 2006
    elseif year == 2007
        filelength_n = 17524;
        lastcolumn='GX';
        ustar_lim = 0.08;
        co2_min = -10; co2_max = 6;        
    elseif year == 2008
        filelength_n = 17572;
        lastcolumn='GZ';
        ustar_lim = 0.08;
        co2_min = -10; co2_max = 6;
    end
    wind_min = 330; wind_max = 30; % these are given a sonic_orient = 180;
    Tdry_min = 240; Tdry_max = 320;
    HS_min = -100; HS_max = 450;
    HSmass_min = -100; HSmass_max = 450;
    LH_min = -150; LH_max = 450;
    rH_min = 0; rH_max = 100;
    h2o_max = 30; h2o_min = 0;
     
elseif sitecode==3; % Juniper savanna
    site = 'JSav'   
    if year == 2007
        filelength_n = 11596;
        lastcolumn='HM';
        ustar_lim = 0.09;
        co2_min = -11; co2_max = 7;        
    elseif year == 2008
        filelength_n = 350;
        lastcolumn='FJ';
        ustar_lim = 0.08;
        co2_min = -10; co2_max = 10;
    elseif year == 2009
        
    end
    wind_min = 15; wind_max = 75; % these are given a sonic_orient = 225;
    Tdry_min = 240; Tdry_max = 320;
    HS_min = -100; HS_max = 450;
    HSmass_min = -100; HSmass_max = 450;
    LH_min = -150; LH_max = 450;
    rH_min = 0; rH_max = 100;
    h2o_max = 30; h2o_min = 0;
    
elseif sitecode == 4; % Pinyon Juniper
    site = 'PJ'
    lastcolumn = 'HO';
    if year == 2007
        filelength_n = 2514;
        ustar_lim = 0.16;
    elseif year == 2008
        filelength_n = 17572;
        ustar_lim = 0.16;
    end    
    wind_min = 15; wind_max = 75; % these are given a sonic_orient = 225;
    co2_min = -10; co2_max = 6;
    Tdry_min = 240; Tdry_max = 310;
    HS_min = -100; HS_max = 640;
    HSmass_min = -100; HSmass_max = 640;
    LH_min = -150; LH_max = 450;
    rH_min = 0; rH_max = 100;
    h2o_max = 30; h2o_min = 0;
    
elseif sitecode==5; % Ponderosa Pine
    site = 'PPine'
    if year == 2006
        filelength_n = 11594;
    elseif year == 2007
        filelength_n = 17524;
        lastcolumn='FV';
        ustar_lim = 0.08;
        co2_min = -18; co2_max = 15;
    elseif year == 2008;
        filelength_n = 17572;
        lastcolumn='FU';
        ustar_lim = 0.08;
        co2_min = -18; co2_max = 15;
    elseif year == 2009;
        filelength_n = 2954;
        lastcolumn='FU';
        ustar_lim = 0.08;
        co2_min = -18; co2_max = 15;
    end
    wind_min = 119; wind_max = 179; % these are given a sonic_orient = 329;
    Tdry_min = 240; Tdry_max = 300;
    HS_min = -200; HS_max = 800;
    HSmass_min = -200; HSmass_max = 800;
    LH_min = -150; LH_max = 550;
    rH_min = 0; rH_max = 100;
    h2o_max = 30; h2o_min = 0;
    
elseif sitecode==6; % Mixed conifer
    site = 'MCon'
    if year == 2006
        filelength_n = 2129; 
        lastcolumn='GB';
        ustar_lim = 0.12;
        co2_min = -12; co2_max = 6;
    elseif year == 2007
        filelength_n = 17524;
        lastcolumn='GB';
        ustar_lim = 0.12;
        co2_min = -12; co2_max = 6;
    elseif year == 2008;
        filelength_n = 16301;
        lastcolumn='GB';
        ustar_lim = 0.11;
        co2_min = -12; co2_max = 6;
    elseif year == 2009;
        filelength_n = 2913;
        lastcolumn='GB';
        ustar_lim = 0.11;
        co2_min = -12; co2_max = 6;    
    end
    
    wind_min = 153; wind_max = 213; % these are given a sonic_orient = 333;
    Tdry_min = 250; Tdry_max = 300;
    HS_min = -200; HS_max = 800;
    HSmass_min = -200; HSmass_max = 800;
    LH_min = -150; LH_max = 550;
    rH_min = 0; rH_max = 100;
    h2o_max = 30; h2o_min = 0;
    
elseif sitecode == 7;
    site = 'TX'
    if year == 2005
        filelength_n = 17524;  
        lastcolumn='GF';
        ustar_lim = 0.11;
        co2_min = -26; co2_max = 12;
    elseif year == 2006
        filelength_n = 17524;  
        lastcolumn='GF';
        ustar_lim = 0.11;
        co2_min = -26; co2_max = 12;
    elseif year == 2007
        filelength_n = 17524;
        lastcolumn='FZ';
        ustar_lim = 0.11;
        co2_min = -26; co2_max = 12;
    elseif year == 2008;
        filelength_n = 16253;
        lastcolumn='GP';
        ustar_lim = 0.11;
        co2_min = -11; co2_max = 6;
    end
    wind_min = 296; wind_max = 356; % these are given a sonic_orient = 146;
    Tdry_min = 265; Tdry_max = 315;
    HS_min = -200; HS_max = 800;
    HSmass_min = -200; HSmass_max = 800;
    LH_min = -150; LH_max = 550;
    rH_min = 0; rH_max = 100;
    h2o_max = 30; h2o_min = 0;
    
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Set up file name and file path
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

drive='c:';
row1=5;  %first row of data to process - rows 1 - 4 are header
filename = 'JSav_2008_for_James';
filelength = num2str(filelength_n);
datalength = filelength_n - row1 + 1; 
filein = strcat(drive,'\Research - Flux Towers\Flux Tower Data by Site\',site,'\',filename)
outfolder = strcat(drive,'\Research - Flux Towers\Flux Tower Data by Site\',site,'\processed flux\');
range = strcat('B',num2str(row1),':',lastcolumn,filelength);
headerrange = strcat('B2:',lastcolumn,'2');
time_stamp_range = strcat('A5:A',filelength);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Open file and parse out dates and times
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

disp('reading data...')
[num text] = xlsread(filein,headerrange);
headertext = text;
[num text] = xlsread(filein,range);  %does not read in first column because it's text!!!!!!!!
data = num;
ncol = size(data,2)+1;
[num text] = xlsread(filein,time_stamp_range);
timestamp = text;
[year month day hour minute second] = datevec(timestamp);
datenumber = datenum(timestamp);
disp('file read');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Read in Matlab processed ts data (these are in the same columns for all
% sites, so they can be just hard-wired in by column number
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

jday=data(:,8);
iok=data(:,9);
Tdry=data(:,14);
wnd_dir_compass=data(:,15);
wnd_spd=data(:,16);
u_star=data(:,27);
CO2_mean=data(:,31);
CO2_std=data(:,32);
H2O_mean=data(:,36);
H2O_std=data(:,37);

flux_co2 = data(:,38);
flux_co2_massman = data(:,40);
flux_co2_wpl_water = data(:,41);
flux_co2_massman_wpl_heat = data(:,42);
flux_co2_wpl_massman_final = data(:,43); % = flux_co2_massman + flux_co2_wpl_water + flux_co2_massman_wpl_heat

flux_h2o = data(:,44);
flux_h2o_massman = data(:,46);
flux_h20_wpl_water = data(:,45);
flux_h20_massman_wpl_heat = data(:,47);
flux_h20_massman_wpl = data(:,48); % = flux_h20_wpl_water + flux_h20_massman_wpl_heat

HSdry = data(:,50);
HSdry_massman = data(:,54);

flux_HL = data(:,55);
flux_HL_wpl_massman = data(:,56);

decimal_day = jday + hour./24 + (minute + 1)./1440;
year2 = year(2)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Read in 30-min data, variable order and names in flux_all files are not  
% consistent so match headertext
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

for i=1:ncol;
    if strcmp('agc_Avg',headertext(i)) == 1
        agc_Avg = data(:,i-1);
    elseif strcmp('rain_Tot', headertext(i)) == 1 || strcmp('precip', headertext(i)) == 1 || ...
            strcmp('precip(in)', headertext(i)) == 1 || strcmp('ppt', headertext(i)) == 1 || ...
            strcmp('Precipitation', headertext(i)) == 1
        precip = data(:,i-1);
    elseif strcmp('press_mean', headertext(i)) == 1 || strcmp('BP_mbar', headertext(i)) == 1 || strcmp('press_Avg', headertext(i)) == 1
        atm_press = data(:,i-1);
    elseif strcmp('par_correct_Avg', headertext(i)) == 1  || strcmp('par_Avg(1)', headertext(i)) == 1 || ...
            strcmp('par_Avg', headertext(i)) == 1
        Par_Avg = data(:,i-1);
    elseif strcmp('rh_hmp', headertext(i))==1 || strcmp('rh_hmp_3_Avg', headertext(i))==1 || ...
            strcmp('RH', headertext(i))==1
        rH = data(:,i-1);
    elseif strcmp('t_hmp_mean', headertext(i))==1 || strcmp('AirTC_Avg', headertext(i))==1 || ...
            strcmp('t_hmp_3_Avg', headertext(i))==1 
        air_temp_hmp = data(:,i-1);
    elseif strcmp('Tsoil',headertext(i)) == 1 || strcmp('Tsoil_avg',headertext(i)) == 1 || ...
            strcmp('soilT_Avg(1)',headertext(i)) == 1
        Tsoil = data(:,i-1);
    elseif strcmp('Rn_correct_Avg',headertext(i))==1 || strcmp('NR_surf_AVG', headertext(i))==1 || ...
            strcmp('NetTot_Avg_corrected', headertext(i))==1 || strcmp('NetTot_Avg', headertext(i))==1 || ...
            strcmp('Rn_Avg',headertext(i))==1
        NR_tot = data(:,i-1);
    elseif strcmp('Rad_short_Up_Avg', headertext(i))==1 || strcmp('pyrr_incoming_Avg', headertext(i))==1
        sw_incoming = data(:,i-1);
    elseif strcmp('Rad_short_Dn_Avg', headertext(i))==1 || strcmp('pyrr_outgoing_Avg', headertext(i))==1  
        sw_outgoing = data(:,i-1);
    elseif strcmp('Rad_long_Up_Avg', headertext(i))==1
        lw_incoming = data(:,i-1);
    elseif strcmp('Rad_long_Dn_Avg', headertext(i))==1
        lw_outgoing = data(:,i-1);
    elseif strcmp('shf_Avg(1)', headertext(i))==1 || strcmp('shf_pinon_1_Avg', headertext(i))==1 
        soil_heat_flux_1 = data(:,i-1);
    elseif strcmp('shf_Avg(2)', headertext(i))==1 || strcmp('shf_jun_1_Avg', headertext(i))==1
        soil_heat_flux_2 = data(:,i-1);
    elseif strcmp('hfpopen_1_Avg', headertext(i))==1 % only for TX
        soil_heat_flux_open = data(:,i-1);
    elseif strcmp('hfpmescan_1_Avg', headertext(i))==1 % only for TX
        soil_heat_flux_mescan = data(:,i-1);
    elseif strcmp('hfpjuncan_1_Avg', headertext(i))==1 % only for TX
        soil_heat_flux_juncan = data(:,i-1);
        
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Site-specific steps for soil temperature
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if sitecode == 4
    for i=1:ncol;
        if strcmp('tcav_pinon_1_Avg',headertext(i)) == 1
            Tsoil1 = data(:,i-1);
        elseif strcmp('tcav_jun_1_Avg',headertext(i)) == 1
            Tsoil2 = data(:,i-1);
        end
    end
    Tsoil = (Tsoil1 + Tsoil2)/2;
    
elseif sitecode == 5 || sitecode == 6 % Ponderosa pine or Mixed conifer
    for i=1:ncol;
        if strcmp('T107_C_Avg(1)',headertext(i)) == 1
            Tsoil_2cm_1 = data(:,i-1);
        elseif strcmp('T107_C_Avg(2)',headertext(i)) == 1
            Tsoil_2cm_2 = data(:,i-1);
        elseif strcmp('T107_C_Avg(3)',headertext(i)) == 1
            Tsoil_6cm_1 = data(:,i-1);
        elseif strcmp('T107_C_Avg(4)',headertext(i)) == 1
            Tsoil_6cm_2 = data(:,i-1);
        end
    end
    Tsoil_2cm = (Tsoil_2cm_1 + Tsoil_2cm_2)/2;
    Tsoil_6cm = (Tsoil_6cm_1 + Tsoil_6cm_2)/2;
    Tsoil = Tsoil_2cm;
    
elseif sitecode == 7 % Texas Freeman
    for i=1:ncol;
        if strcmp('Tsoil_Avg(2)',headertext(i)) == 1
            open_5cm = data(:,i-1);
        elseif strcmp('Tsoil_Avg(3)',headertext(i)) == 1
            open_10cm = data(:,i-1);
        elseif strcmp('Tsoil_Avg(5)',headertext(i)) == 1
            Mesquite_5cm = data(:,i-1);
        elseif strcmp('Tsoil_Avg(6)',headertext(i)) == 1
            Mesquite_10cm = data(:,i-1);
        elseif strcmp('Tsoil_Avg(8)',headertext(i)) == 1
            Juniper_5cm = data(:,i-1);
        elseif strcmp('Tsoil_Avg(9)',headertext(i)) == 1
            Juniper_10cm = data(:,i-1);
        end
    end
    if year2 == 2005 % juniper probes on-line after 5/19/05
        % before 5/19
        canopy_5cm = Mesquite_5cm(find(decimal_day < 139.61));
        canopy_10cm = Mesquite_10cm(find(decimal_day < 139.61));
        % after 5/19
        canopy_5cm(find(decimal_day >= 139.61)) = (Mesquite_5cm(find(decimal_day >= 139.61)) + Juniper_5cm(find(decimal_day >= 139.61)))/2;
        canopy_10cm(find(decimal_day >= 139.61)) = (Mesquite_10cm(find(decimal_day >= 139.61)) + Juniper_10cm(find(decimal_day >= 139.61)))/2;
        % clean strange 0 values
        canopy_5cm(find(canopy_5cm == 0)) = NaN;
        canopy_10cm(find(canopy_10cm == 0)) = NaN;
        Tsoil = (open_5cm + canopy_5cm)./2;
    else
        canopy_5cm = (Mesquite_5cm + Juniper_5cm)/2;
        canopy_10cm = (Mesquite_10cm + Juniper_10cm)/2;
        Tsoil = (open_5cm + canopy_5cm)/2;
    end
       
end

% for shrub and grass originally had Q*.7 and need cal factors for early
% processing >> so factors for shrub are same as for pj (same instrument)
% ...

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Radiation corrections
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%% grassland
if sitecode == 1
    if year2 == 2007
        % this is the wind correction factor for the Q*7 used before ??/??      
        for i = 1:5766
            if NR_tot(1) < 0
                NR_tot(i) = NR_tot(i)*11.42*((0.00174*wnd_spd(i)) + 0.99755);
            elseif NR_tot(1) > 0
                NR_tot(i) = NR_tot(i)*8.99*(1 + (0.066*0.2*wnd_spd(i))/(0.066 + (0.2*wnd_spd(i))));
            end
        end
        
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
        lw_incoming = lw_incoming + 0.0000000567.*(Tdry).^4; 
        lw_outgoing = lw_outgoing + 0.0000000567.*(Tdry).^4;
        % calculate new net radiation values
        NR_lw = lw_incoming - lw_outgoing; 
        NR_sw = sw_incoming - sw_outgoing;
        NR_tot = NR_lw + NR_sw;
        % calibration correction for the li190
        Par_Avg(find(decimal_day > 162.14)) = Par_Avg(find(decimal_day > 162.14)).*1000./(5.7*0.604);
        % estimate par from sw_incoming
        Par_Avg(find(decimal_day < 162.15)) = sw_incoming(find(decimal_day < 162.15)).*2.025 + 4.715;        
        
    elseif year2 == 2008 || year2 == 2009
        % calibration correction for the li190
        Par_Avg = Par_Avg.*1000./(5.7*0.604);
        % calibration and unit conversion into W per m^2 for CNR1 variables
        % and adjust for program error
        sw_incoming = sw_incoming./136.99.*(1000./8.49);
        sw_outgoing = sw_outgoing./136.99.*(1000./8.49);
        lw_incoming = lw_incoming./136.99.*(1000./8.49); 
        lw_outgoing = lw_outgoing./136.99.*(1000./8.49);
        % temperature correction just for long-wave
        lw_incoming = lw_incoming + 0.0000000567.*(Tdry).^4;
        lw_outgoing = lw_outgoing + 0.0000000567.*(Tdry).^4;
        % calculate new net radiation values
        NR_lw = lw_incoming - lw_outgoing; % calculate new net long wave
        NR_sw = sw_incoming - sw_outgoing; % calculate new net short wave
        NR_tot = NR_lw + NR_sw;        
    end
    
%%%%%%%%%%%%%%%%% shrubland 
elseif sitecode == 2    
    if year2 == 2007
        % was this a Q*7 through the big change on 5/30/07? need updated
        % calibration
        for i = 1:6816
            if NR_tot(1) < 0
                NR_tot(i) = NR_tot(i)*10.74*((0.00174*wnd_spd(i)) + 0.99755);
            elseif NR_tot(1) > 0
                NR_tot(i) = NR_tot(i)*8.65*(1 + (0.066*0.2*wnd_spd(i))/(0.066 + (0.2*wnd_spd(i))));
            end
        end
      
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
        lw_incoming = lw_incoming + 0.0000000567.*(Tdry).^4; % temperature correction just for long-wave        
        lw_outgoing = lw_outgoing + 0.0000000567.*(Tdry).^4; % temperature correction just for long-wave 
        
        % calculate new net radiation values
        NR_lw = lw_incoming - lw_outgoing; % calculate new net long wave
        NR_sw = sw_incoming - sw_outgoing; % calculate new net short wave
        NR_tot(find(decimal_day >= 150.75)) = NR_lw(find(decimal_day >= 150.75)) + NR_sw(find(decimal_day >= 150.75)); 
        NR_tpt(find(decimal_day >= 150.75 & isnan(NR_sw)==1)) = NaN;
        
        % calibration correction for the li190
        Par_Avg(find(decimal_day > 150.729)) = Par_Avg(find(decimal_day > 150.729)).*1000./(6.94*0.604);
        % estimate par from sw_incoming
        Par_Avg(find(decimal_day < 150.729)) = sw_incoming(find(decimal_day < 150.729)).*2.0292 + 3.6744;
        
    elseif year2 == 2008
        % calibration and unit conversion into W per m^2 for CNR1 variables
        sw_incoming = sw_incoming./136.99.*(1000./12.34); % adjust for program error and convert into W per m^2
        sw_outgoing = sw_outgoing./136.99.*(1000./12.34); % adjust for program error and convert into W per m^2
        lw_incoming = lw_incoming./136.99.*(1000./12.34); % adjust for program error and convert into W per m^2
        lw_outgoing = lw_outgoing./136.99.*(1000./12.34); % adjust for program error and convert into W per m^2        
        lw_incoming = lw_incoming + 0.0000000567.*(Tdry).^4; % temperature correction just for long-wave
        lw_outgoing = lw_outgoing + 0.0000000567.*(Tdry).^4; % temperature correction just for long-wave        
        NR_lw = lw_incoming - lw_outgoing; % calculate new net long wave
        NR_sw = sw_incoming - sw_outgoing; % calculate new net short wave
        NR_tot = NR_lw + NR_sw;
        % calibration correction for the li190
        Par_Avg = Par_Avg.*1000./(6.94*0.604);        
    end

%%%%%%%%%%%%%%%%% juniper savanna
elseif sitecode == 3 
    if year2 == 2007
        % calibration and unit conversion into W per m^2 for CNR1 variables
        sw_incoming = sw_incoming./163.666.*(1000./6.9); % convert into W per m^2
        sw_outgoing = sw_outgoing./163.666.*(1000./6.9); % convert into W per m^2
        lw_incoming = lw_incoming./163.666.*(1000./6.9); % convert into W per m^2
        lw_outgoing = lw_outgoing./163.666.*(1000./6.9); % convert into W per m^2        
        lw_incoming = lw_incoming + 0.0000000567.*(Tdry).^4; % temperature correction just for long-wave
        lw_outgoing = lw_outgoing + 0.0000000567.*(Tdry).^4; % temperature correction just for long-wave
        NR_lw = lw_incoming - lw_outgoing; % calculate new net long wave
        NR_sw = sw_incoming - sw_outgoing; % calculate new net short wave
        NR_tot = NR_lw + NR_sw;
        % calibration for par-lite
        Par_Avg = Par_Avg.*1000./5.48;
    elseif year2 == 2008
        % calibration and unit conversion into W per m^2 for CNR1 variables
        sw_incoming = sw_incoming./163.666.*(1000./6.9); % convert into W per m^2
        sw_outgoing = sw_outgoing./163.666.*(1000./6.9); % convert into W per m^2
        lw_incoming = lw_incoming./163.666.*(1000./6.9); % convert into W per m^2
        lw_outgoing = lw_outgoing./163.666.*(1000./6.9); % convert into W per m^2        
        lw_incoming = lw_incoming + 0.0000000567.*(Tdry).^4; % temperature correction just for long-wave
        lw_outgoing = lw_outgoing + 0.0000000567.*(Tdry).^4; % temperature correction just for long-wave
        NR_lw = lw_incoming - lw_outgoing; % calculate new net long wave
        NR_sw = sw_incoming - sw_outgoing; % calculate new net short wave
        NR_tot = NR_lw + NR_sw;
        % calibration for par-lite
        Par_Avg = Par_Avg.*1000./5.48;
    end
    
% all cnr1 variables for jsav need to be (value/163.666)*144.928

%%%%%%%%%%%%%%%%% pinyon juniper
elseif sitecode == 4
    if year2 == 2007
        % this is the wind correction factor for the Q*7
        NR_tot(find(NR_tot < 0)) = NR_tot(find(NR_tot < 0)).*10.74.*((0.00174.*wnd_spd(find(NR_tot < 0))) + 0.99755);
        NR_tot(find(NR_tot > 0)) = NR_tot(find(NR_tot > 0)).*8.65.*(1 + (0.066.*0.2.*wnd_spd(find(NR_tot > 0)))./(0.066 + (0.2.*wnd_spd(find(NR_tot > 0)))));
        % now correct pars
        Par_Avg = NR_tot.*2.7828 + 170.93; % see notes on methodology (PJ) for this relationship
        sw_incoming = Par_Avg.*0.4577 - 1.8691; % see notes on methodology (PJ) for this relationship
        NR_lw = lw_incoming - lw_outgoing; 
        NR_sw = sw_incoming - sw_outgoing;

    elseif year2 == 2008
        % this is the wind correction factor for the Q*7
        NR_tot(find(decimal_day < 172 & NR_tot < 0)) = NR_tot(find(decimal_day < 172 & NR_tot < 0)).*10.74.*((0.00174.*wnd_spd(find(decimal_day < 172 & NR_tot < 0))) + 0.99755);
        NR_tot(find(decimal_day < 172 & NR_tot > 0)) = NR_tot(find(decimal_day < 172 & NR_tot > 0)).*8.65.*(1 + (0.066.*0.2.*wnd_spd(find(decimal_day < 172 & NR_tot > 0)))./(0.066 + (0.2.*wnd_spd(find(decimal_day < 172 & NR_tot > 0)))));
        % now correct pars
        Par_Avg(find(decimal_day < 42.6)) = NR_tot(find(decimal_day < 42.6)).*2.7828 + 170.93;
        % calibration for par-lite installed on 2/11/08
        Par_Avg(find(decimal_day > 42.6)) = Par_Avg(find(decimal_day > 42.6)).*1000./5.51;
        sw_incoming(find(decimal_day < 172)) = Par_Avg(find(decimal_day < 172)).*0.4577 - 1.8691;
        % calculate new net radiation values
        NR_lw = lw_incoming - lw_outgoing; 
        NR_sw = sw_incoming - sw_outgoing;
        NR_tot(find(decimal_day > 171.5)) = NR_lw(find(decimal_day > 171.5)) + NR_sw(find(decimal_day > 171.5));  
    end

%%%%%%%%%%%%%%%%% ponderosa pine
elseif sitecode == 5
    if year2 == 2007
        % radiation values apparently already calibrated and unit-converted
        % in progarm for valles sites
        lw_incoming = lw_incoming + 0.0000000567.*(Tdry).^4; % temperature correction just for long-wave
        lw_outgoing = lw_outgoing + 0.0000000567.*(Tdry).^4; % temperature correction just for long-wave        
        NR_lw = lw_incoming - lw_outgoing; % calculate new net long wave
        NR_sw = sw_incoming - sw_outgoing; % calculate new net short wave
        NR_tot = NR_lw + NR_sw;
        % calibration for par-lite sensor
        Par_Avg = Par_Avg.*1000./5.25;
    elseif year2 == 2008 || year2 == 2009
        % radiation values apparently already calibrated and unit-converted
        % in progarm for valles sites
        lw_incoming = lw_incoming + 0.0000000567.*(Tdry).^4; % temperature correction just for long-wave
        lw_outgoing = lw_outgoing + 0.0000000567.*(Tdry).^4; % temperature correction just for long-wave        
        NR_lw = lw_incoming - lw_outgoing; % calculate new net long wave
        NR_sw = sw_incoming - sw_outgoing; % calculate new net short wave
        NR_tot = NR_lw + NR_sw;
        % calibration for par-lite sensor
        Par_Avg = Par_Avg.*1000./5.25;
    end
    
%%%%%%%%%%%%%%%%% mixed conifer
elseif sitecode == 6
    if year2 == 2006 || year2 == 2007
        % calibration and unit conversion into W per m^2 for CNR1 variables
        % cnr1 installed and working on 8/1/08
%         sw_incoming(find(decimal_day > 214.75)) = sw_incoming(find(decimal_day > 214.75)).*(1000./9.96); % convert into W per m^2
%         sw_outgoing(find(decimal_day > 214.75)) = sw_outgoing(find(decimal_day > 214.75)).*(1000./9.96); % convert into W per m^2
%         lw_incoming(find(decimal_day > 214.75)) = lw_incoming(find(decimal_day > 214.75)).*(1000./9.96); % convert into W per m^2
%         lw_outgoing(find(decimal_day > 214.75)) = lw_outgoing(find(decimal_day > 214.75)).*(1000./9.96); % convert into W per m^2        
        lw_incoming = lw_incoming + 0.0000000567.*(Tdry).^4; % temperature correction just for long-wave
        lw_outgoing = lw_outgoing + 0.0000000567.*(Tdry).^4; % temperature correction just for long-wave        
        NR_lw = lw_incoming - lw_outgoing; % calculate new net long wave
        NR_sw = sw_incoming - sw_outgoing; % calculate new net short wave
        NR_tot = NR_lw + NR_sw;        
        
    elseif year2 == 2008 || year2 == 2009
        % radiation values apparently already calibrated and unit-converted
        % in progarm for valles sites   
        lw_incoming = lw_incoming + 0.0000000567.*(Tdry).^4; % temperature correction just for long-wave
        lw_outgoing = lw_outgoing + 0.0000000567.*(Tdry).^4; % temperature correction just for long-wave        
        NR_lw = lw_incoming - lw_outgoing; % calculate new net long wave
        NR_sw = sw_incoming - sw_outgoing; % calculate new net short wave
        NR_tot = NR_lw + NR_sw;
        % calibration for par-lite sensor
        Par_Avg = Par_Avg.*1000./5.65;
        
    end
    
%%%%%%%%%%%%%%%%% texas
elseif sitecode == 7
    if year2 == 2007 || 2006
        % wind corrections for the Q*7
        NR_tot(find(NR_tot < 0)) = NR_tot(find(NR_tot < 0)).*10.91.*((0.00174.*wnd_spd(find(NR_tot < 0))) + 0.99755);
        NR_tot(find(NR_tot > 0)) = NR_tot(find(NR_tot > 0)).*8.83.*(1 + (0.066.*0.2.*wnd_spd(find(NR_tot > 0)))./(0.066 + (0.2.*wnd_spd(find(NR_tot > 0)))));

        % no long-wave data for TX
        lw_incoming(1:datalength,1) = NaN;
        lw_outgoing(1:datalength,1) = NaN;
        % pyrronometer corrections
        sw_incoming = sw_incoming.*1000./27.34;
        sw_outgoing = sw_outgoing.*1000./19.39;
        NR_sw = sw_incoming - sw_outgoing; % calculate new net short wave
        % calculate new net long wave from total net minus sw net
        NR_lw = NR_tot - NR_sw;
        % calibration for the li-190 par sensor - sensor had many high
        % values, so delete all values above 6.5 first
        Par_Avg(find(Par_Avg > 6.5)) = NaN;
        Par_Avg = Par_Avg.*1000./(6.16.*0.604);
    elseif year2 == 2008
        % par switch to par-lite on ??
        
    end
    
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Set up filters for co2 and make a master flag variable (decimal_day_nan)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

decimal_day_nan = decimal_day;
record = 1:1:length(flux_co2_wpl_massman_final);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Iteration 1 - run and plot fluxes with the following four filters with
% all other filters commented out, then evaluate the ustar cutoff with
% figure (1).  Use the plot to decide which ustar bin on the x-axis is the
% cutoff, and then use the printed out vector on the main screen to decide
% what the ustar value is for that bin.  That's the number you enter into
% the site-specific info above.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

disp('Number of co2 flux periods removed due to:');
% Original number of NaNs
nanflag = find(isnan(flux_co2_wpl_massman_final));
removednans = length(nanflag);
decimal_day_nan(nanflag) = NaN;
record(nanflag) = NaN;
disp(sprintf('    original empties = %d',removednans));

% % Remove values during precipitation
precipflag = find(precip > 0);
removed_precip = length(precipflag);
decimal_day_nan(precipflag) = NaN;
record(precipflag) = NaN;
disp(sprintf('    precip = %d',removed_precip));

% Remove for behind tower wind direction
windflag = find(wnd_dir_compass > wind_min & wnd_dir_compass < wind_max);
removed_wind = length(windflag);
decimal_day_nan(windflag) = NaN;
record(windflag) = NaN;
disp(sprintf('    wind direction = %d',removed_wind));

% Remove night-time negative fluxes
nightnegflag = find((hour >= 22 | hour <= 5) & flux_co2_wpl_massman_final < 0);
removed_nightneg = length(nightnegflag);
decimal_day_nan(nightnegflag) = NaN;
record(nightnegflag) = NaN;
disp(sprintf('    night-time negs = %d',removed_nightneg));

% ppine has super high night respiration when winds come from ~ 50 degrees, so these must be excluded also:
if sitecode == 5
    ppine_night_wind = find((wnd_dir_compass > 30 & wnd_dir_compass < 65) & (hour <= 9 | hour > 18));
    removed_ppine_night_wind = length(ppine_night_wind);
    decimal_day_nan(ppine_night_wind) = NaN;
    record(ppine_night_wind) = NaN;
    disp(sprintf('    ppine night winds = %d',removed_ppine_night_wind));
end

% gland 2007 had large fluxes for very cold temperatures early in the year.
if sitecode == 1 && year2 == 2007
    gland_cold = find(Tdry < 271);
    removed_gland_cold = length(gland_cold);
    decimal_day_nan(gland_cold) = NaN;
    record(gland_cold) = NaN;
    disp(sprintf('    gland cold = %d',removed_gland_cold));
end

% % Special removal for ppine wind directions
% if sitecode == 5
%     ppinewindflag = find((wnd_dir_compass >= 0 & wnd_dir_compass <= 180) & (hour >= 20 | hour <= 8));
%     removed_ppinewind = length(ppinewindflag);
%     decimal_day_nan(ppinewindflag) = NaN;
%     record(ppinewindflag) = NaN;
% end

% Plot out to see and determine ustar cutoff
if iteration == 1    
    u_star_2 = u_star(find(~isnan(decimal_day_nan)));
    flux_co2_wpl_massman_final_2 = flux_co2_wpl_massman_final(find(~isnan(decimal_day_nan)));
    hour_2 = hour(find(~isnan(decimal_day_nan)));

    ustar_bin = 1:1:30; % you can change this to have more or less categories
    for i = 1:30 % you can change this to have more or less categories
        if i == 1
            startbin(i) = 0;
        elseif i >= 2
            startbin(i) = (i - 1)*0.01;
        end
        endbin(i) = 0.01 + startbin(i);    
        elementstouse = find((u_star_2 > startbin(i) & u_star_2 < endbin(i)) & (hour_2 > 22 | hour_2 < 5));
        co2mean(i) = mean(flux_co2_wpl_massman_final_2(elementstouse));
    end

    startbin

    figure(1); clf;
    plot(ustar_bin,co2mean,'.r');
    shg;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Iteration 2 - Now that you have entered a ustar cutoff in the site
% options above, run with iteration 2 to see the effect of removing those
% values
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if iteration > 1
    
    %Remove values with low U*
    ustarflag = find(u_star < ustar_lim);
    removed_ustar = length(ustarflag);
    decimal_day_nan(ustarflag) = NaN;
    record(ustarflag) = NaN;
    
    % display pulled ustar
    disp(sprintf('    u_star = %d',removed_ustar));
end
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Iteration 3 - now that values have been filtered for ustar, decide what
% the min and max co2 flux values should be by examining figure 2 and then
% entering them in the site options above, then run program with iteration
% 3 and see the effect of removing them in figure 2
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
    
if iteration > 2

    %Pull out maxs and mins
    maxminflag = find(flux_co2_wpl_massman_final > co2_max | flux_co2_wpl_massman_final < co2_min); 
    removed_maxs_mins = length(maxminflag);
    decimal_day_nan(maxminflag) = NaN;
    record(maxminflag) = NaN;
    
    % display what is pulled for maxs and mins
    disp(sprintf('    above max or below min = %d',removed_maxs_mins));
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
% Iteration 4 - Now examine the effect of high and low co2 filters by
% running program with iteration 4
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
    
if iteration > 3
    
    % Remove high CO2 concentration points
    highco2flag = find(CO2_mean > 500);
    removed_highco2 = length(highco2flag);
    decimal_day_nan(highco2flag) = NaN;
    record(highco2flag) = NaN;

    % Remove low CO2 concentration points
    lowco2flag = find(CO2_mean <300);
    removed_lowco2 = length(lowco2flag);
    decimal_day_nan(lowco2flag) = NaN;
    record(lowco2flag) = NaN;
    
    % display what's pulled for too high or too low co2
    disp(sprintf('    low co2 = %d',removed_lowco2));
    disp(sprintf('    high co2 = %d',removed_highco2));
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
% Iteration 5 - Now clear out the last of the outliers by running iteration
% 5, which removes values outside a running standard deviation window
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if iteration > 4
    %Remove values outside of a running standard deviation
    std_bin = zeros(1,24);
    bin_length = round(length(flux_co2_wpl_massman_final)/24);
    for i = 1:24
        if i == 1
            startbin = 1;
        elseif i >= 2
            startbin = (i * bin_length);
        end    
        endbin = bin_length + startbin;
        elementstouse = find(record > startbin & record <= endbin & isnan(record) == 0);
        std_bin(i) = std(flux_co2_wpl_massman_final(elementstouse));
        mean_flux(i) = mean(flux_co2_wpl_massman_final(elementstouse));
        bin_index = find(abs(flux_co2_wpl_massman_final(elementstouse)) > ...
            (3*std_bin(i) + mean_flux(i)));
        outofstdnan = elementstouse(bin_index);
        decimal_day_nan(outofstdnan) = NaN;
        record(outofstdnan) = NaN;
        running_nans(i) = length(outofstdnan);
        removed_outofstdnan = sum(running_nans);
    end   
    
    disp(sprintf('    above or below 3X running standard deviation = %d',removed_outofstdnan));

end % close if statement for iterations


% Remove high AGC
% agcflag = find(agc_Avg > agc_lim);
% removed_agc = length(agcflag);
% decimal_day_nan(agcflag) = NaN;

% Remove for high or low advection
% advectionflag = find(LCO2flux_advection > 50 | LCO2flux_advection < -50);
% removed_advection = length(advectionflag);
% decimal_day_nan(advectionflag) = NaN;
% advection_threshold=1000;

% %disp(sprintf('advection = %d',removed_advection));
% %disp(sprintf('above agc = %d',removed_agc));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Plot the co2 flux for the whole series
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

figure(2); clf;
hold on; box on;
plot(decimal_day,flux_co2_wpl_massman_final,'or');
plot(decimal_day(find(~isnan(decimal_day_nan))),flux_co2_wpl_massman_final(find(~isnan(decimal_day_nan))),'.b');
xlabel('decimal day'); ylabel('co2 flux');
hold off; shg;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Filter for sensible heat
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% max and mins for HSdry
HS_flag = find(HSdry > HS_max | HSdry < HS_min);
HSdry(HS_flag) = NaN;
% remove sh data when raining, use existing precipflag variable
HSdry(precipflag) = NaN;
% remove sh data with low ustar, use existing ustarflag variable
HSdry(ustarflag) = NaN;
removed_HS = length(find(isnan(HSdry)));

% max and mins for HSdry_massman
HSmass_flag = find(HSdry_massman > HSmass_max | HSdry_massman < HSmass_min);
HSdry_massman(HSmass_flag) = NaN;
% remove sh data when raining, use existing precipflag variable
HSdry_massman(precipflag) = NaN;
% remove sh data with low ustar, use existing ustarflag variable
HSdry_massman(ustarflag) = NaN;
removed_HSmass = length(find(isnan(HSdry_massman)));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Filter for max's and min's for other variables
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% QC for flux_HL
LH_flag = find(flux_HL > LH_max | flux_HL < LH_min);
removed_LH = length(LH_flag);
flux_HL(LH_flag) = NaN;

% QC for flux_HL_wpl_massman
LH_flag = find(flux_HL_wpl_massman > LH_max | flux_HL_wpl_massman < LH_min);
removed_LH_wpl_mass = length(LH_flag);
flux_HL_wpl_massman(LH_flag) = NaN;

% QC for sw_incoming

% QC for Tdry
Tdry_flag = find(Tdry > Tdry_max | Tdry < Tdry_min);
removed_Tdry = length(Tdry_flag);
Tdry(Tdry_flag) = NaN;

% QC for Tsoil

% QC for rH
rH_flag = find(rH > rH_max | rH < rH_min);
removed_rH = length(rH_flag);
rH(rH_flag) = NaN;

% QC for h2o mean values
h2o_flag = find(H2O_mean > h2o_max | H2O_mean < h2o_min);
removed_h2o = length(h2o_flag);
H2O_mean(h2o_flag) = NaN;

% min/max QC for TX soil heat fluxes
if sitecode == 7
    if year2 == 2005
        soil_heat_flux_open(find(soil_heat_flux_open > 100 | soil_heat_flux_open < -50)) = NaN;
        soil_heat_flux_mescan(find(soil_heat_flux_mescan > 50 | soil_heat_flux_mescan < -40)) = NaN;
        soil_heat_flux_juncan(find(soil_heat_flux_juncan > 50 | soil_heat_flux_juncan < -60)) = NaN;
    elseif year2 == 2006
        soil_heat_flux_open(find(soil_heat_flux_open > 90 | soil_heat_flux_open < -60)) = NaN;
        soil_heat_flux_mescan(find(soil_heat_flux_mescan > 50 | soil_heat_flux_mescan < -50)) = NaN;
        soil_heat_flux_juncan(find(soil_heat_flux_juncan > 50 | soil_heat_flux_juncan < -60)) = NaN;        
    elseif year2 == 2007 
        soil_heat_flux_open(find(soil_heat_flux_open > 110 | soil_heat_flux_open < -50)) = NaN;
        soil_heat_flux_mescan(find(soil_heat_flux_mescan > 40 | soil_heat_flux_mescan < -40)) = NaN;
        soil_heat_flux_juncan(find(soil_heat_flux_juncan > 20 | soil_heat_flux_juncan < -40)) = NaN;
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Print to screen the number of removals
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

disp(' ');
disp(sprintf('number of co2 flux values pulled in post-process = %d',(filelength_n-sum(~isnan(record)))));
disp(sprintf('number of co2 flux values used = %d',sum(~isnan(record))));
disp(' ');
disp('Values removed for other qcd variables');
disp(sprintf('    number of latent heat values removed = %d',removed_LH));
disp(sprintf('    number of massman&wpl-corrected latent heat values removed = %d',removed_LH_wpl_mass));
disp(sprintf('    number of sensible heat values removed = %d',removed_HS));
disp(sprintf('    number of massman-corrected sensible heat values removed = %d',removed_HSmass));
disp(sprintf('    number of temperature values removed = %d',removed_Tdry));
disp(sprintf('    number of relative humidity values removed = %d',removed_rH));
disp(sprintf('    number of mean water vapor values removed = %d',removed_h2o));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%WRITE FILE FOR ONLINE GAP-FILLING PROGRAM (REICHSTEIN)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

qc = ones(datalength,1);
qc(find(isnan(decimal_day_nan))) = 2;
NEE = flux_co2_wpl_massman_final; NEE(find(isnan(decimal_day_nan))) = -9999;
LE = flux_HL_wpl_massman; LE(find(isnan(decimal_day_nan))) = -9999;
H_dry = HSdry_massman; H_dry(find(isnan(decimal_day_nan))) = -9999;
Tair = Tdry - 273.15;

if write_gap_filling_out_file == 1;
    disp('writing gap-filling file...')
    header = {'day' 'month' 'year' 'hour' 'minute' 'qcNEE' 'NEE' 'LE' 'H_dry' 'Rg' 'Tair' 'Tsoil' 'rH' 'precip' 'Ustar'};
    datamatrix = [day month year hour minute qc NEE LE H_dry sw_incoming Tair Tsoil rH precip u_star];
    for n = 1:datalength
        for k = 1:15;
            if isnan(datamatrix(n,k)) == 1;
                datamatrix(n,k) = -9999;
            else
            end
        end
    end
    outfilename = strcat(outfolder,filename,'_for_gap_filling')
    xlswrite(outfilename, header, 'data', 'A1');
    xlswrite(outfilename, datamatrix, 'data', 'A2');
else
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%WRITE COMPLETE OUT-FILE  (FLUX_all matrix with bad values removed)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% clean the co2 flux variables
flux_co2(find(isnan(decimal_day_nan))) = NaN;
flux_co2_massman(find(isnan(decimal_day_nan))) = NaN;
flux_co2_wpl_water(find(isnan(decimal_day_nan))) = NaN;
flux_co2_massman_wpl_heat(find(isnan(decimal_day_nan))) = NaN;
flux_co2_wpl_massman_final(find(isnan(decimal_day_nan))) = NaN;

% clean the h2o flux variables
flux_h2o(find(isnan(decimal_day_nan))) = NaN;
flux_h2o_massman(find(isnan(decimal_day_nan))) = NaN;
flux_h20_wpl_water(find(isnan(decimal_day_nan))) = NaN;
flux_h20_massman_wpl_heat(find(isnan(decimal_day_nan))) = NaN;
flux_h20_massman_wpl(find(isnan(decimal_day_nan))) = NaN;

if write_complete_out_file == 1;
    disp('writing qc file...')
    
    if sitecode == 5 || sitecode == 6 
        header2 = {'timestamp','year','month','day','hour','minute','second','jday','iok','agc_Avg',...
            'wnd_dir_compass','wnd_spd','CO2_mean','CO2_std','H2O_mean','H2O_std',...
            'flux_co2','flux_co2_massman','flux_co2_wpl_water','flux_co2_massman_wpl_heat','flux_co2_massman_wpl_final',...
            'flux_h2o','flux_h2o_massman','flux_h20_wpl_water','flux_h20_massman_wpl_heat','flux_h20_massman_wpl_final',...
            'HSdry','HSdry_massman','flux_HL','flux_HL_wpl_massman',...
            'Tdry','air_temp_hmp','Tsoil_2cm','Tsoil_6cm','precip','atm_press','rH'...
            'Par_Avg','sw_incoming','sw_outgoing','lw_incoming','lw_outgoing','NR_sw','NR_lw','NR_tot'};
        datamatrix2 = [year,month,day,hour,minute,second,jday,iok,agc_Avg,...
            wnd_dir_compass,wnd_spd,CO2_mean,CO2_std,H2O_mean,H2O_std,...        
            flux_co2,flux_co2_massman,flux_co2_wpl_water,flux_co2_massman_wpl_heat,flux_co2_wpl_massman_final,...
            flux_h2o,flux_h2o_massman,flux_h20_wpl_water,flux_h20_massman_wpl_heat,flux_h20_massman_wpl,...
            HSdry,HSdry_massman,flux_HL,flux_HL_wpl_massman,...
            Tdry,air_temp_hmp,Tsoil_2cm,Tsoil_6cm,precip,atm_press,rH...
            Par_Avg,sw_incoming,sw_outgoing,lw_incoming,lw_outgoing,NR_sw,NR_lw,NR_tot];
    
    elseif sitecode == 7
        header2 = {'timestamp','year','month','day','hour','minute','second','jday','iok','agc_Avg','u_star',...
            'wnd_dir_compass','wnd_spd','CO2_mean','CO2_std','H2O_mean','H2O_std',...
            'flux_co2','flux_co2_massman','flux_co2_wpl_water','flux_co2_massman_wpl_heat','flux_co2_massman_wpl_final',...
            'flux_h2o','flux_h2o_massman','flux_h20_wpl_water','flux_h20_massman_wpl_heat','flux_h20_massman_wpl_final',...
            'HSdry','HSdry_massman','flux_HL','flux_HL_wpl_massman',...
            'Tdry','air_temp_hmp','Tsoil','canopy_5cm','canopy_10cm','open_5cm','open_10cm',...
            'soil_heat_flux_open','soil_heat_flux_mescan','soil_heat_flux_juncan','precip','atm_press','rH'...
            'Par_Avg','sw_incoming','sw_outgoing','lw_incoming','lw_outgoing','NR_sw','NR_lw','NR_tot'};    
        datamatrix2 = [year,month,day,hour,minute,second,jday,iok,agc_Avg,u_star,...
            wnd_dir_compass,wnd_spd,CO2_mean,CO2_std,H2O_mean,H2O_std,...        
            flux_co2,flux_co2_massman,flux_co2_wpl_water,flux_co2_massman_wpl_heat,flux_co2_wpl_massman_final,...
            flux_h2o,flux_h2o_massman,flux_h20_wpl_water,flux_h20_massman_wpl_heat,flux_h20_massman_wpl,...
            HSdry,HSdry_massman,flux_HL,flux_HL_wpl_massman,...
            Tdry,air_temp_hmp,Tsoil,canopy_5cm,canopy_10cm,open_5cm,open_10cm,...
            soil_heat_flux_open,soil_heat_flux_mescan,soil_heat_flux_juncan,precip,atm_press,rH...
            Par_Avg,sw_incoming,sw_outgoing,lw_incoming,lw_outgoing,NR_sw,NR_lw,NR_tot];
    
    else
        header2 = {'timestamp','year','month','day','hour','minute','second','jday','iok','agc_Avg','u_star',...
            'wnd_dir_compass','wnd_spd','CO2_mean','CO2_std','H2O_mean','H2O_std',...
            'flux_co2','flux_co2_massman','flux_co2_wpl_water','flux_co2_massman_wpl_heat','flux_co2_massman_wpl_final',...
            'flux_h2o','flux_h2o_massman','flux_h20_wpl_water','flux_h20_massman_wpl_heat','flux_h20_massman_wpl_final',...
            'HSdry','HSdry_massman','flux_HL','flux_HL_wpl_massman',...
            'Tdry','air_temp_hmp','Tsoil','soil_heat_flux_1','soil_heat_flux_2','precip','atm_press','rH'...
            'Par_Avg','sw_incoming','sw_outgoing','lw_incoming','lw_outgoing','NR_sw','NR_lw','NR_tot'};    
        datamatrix2 = [year,month,day,hour,minute,second,jday,iok,agc_Avg,u_star,...
            wnd_dir_compass,wnd_spd,CO2_mean,CO2_std,H2O_mean,H2O_std,...        
            flux_co2,flux_co2_massman,flux_co2_wpl_water,flux_co2_massman_wpl_heat,flux_co2_wpl_massman_final,...
            flux_h2o,flux_h2o_massman,flux_h20_wpl_water,flux_h20_massman_wpl_heat,flux_h20_massman_wpl,...
            HSdry,HSdry_massman,flux_HL,flux_HL_wpl_massman,...
            Tdry,air_temp_hmp,Tsoil,soil_heat_flux_1,soil_heat_flux_2,precip,atm_press,rH...
            Par_Avg,sw_incoming,sw_outgoing,lw_incoming,lw_outgoing,NR_sw,NR_lw,NR_tot];
    end

    outfilename = strcat(outfolder,filename,'_qc_James')
    xlswrite(outfilename,header2,'data','A1');
    xlswrite(outfilename,datamatrix2,'data','B2');
    xlswrite(outfilename,timestamp,'data','A2');
    
    if iteration > 4
        numbers_removed = [removednans removed_precip removed_wind removed_nightneg removed_ustar ...
            removed_maxs_mins removed_lowco2 removed_highco2 removed_outofstdnan NaN ...
            (filelength_n-sum(~isnan(record))) sum(~isnan(record))...
            removed_LH removed_LH_wpl_mass removed_HS removed_HSmass ...
            removed_Tdry removed_rH removed_h2o];
        removals_header = {'Original nans','Precip periods','Bad wind direction','Night-time negs','Low ustar',...
            'Over max or min','Low co2','High co2','Outside running std','',...
            'Total co2 pulled','Total retained',...
            'LH values removed','LH with WPL/Massman removed','HS removed','HS with massman removed',...
            'Temp removed','Rel humidity removed','Water removed'};
    xlswrite(outfilename,numbers_removed','numbers removed','B1');
    xlswrite (outfilename, removals_header', 'numbers removed', 'A1');
    end

end
%________________________________________________________________________
% 
% %data-logger-temp issue in Jemez sites
%     elseif  (floor(sitecode)==5 || floor(sitecode)==6) && Ref_Tmp_a(j)>16 && iok(j) <9000
%         qc_sonic(j)=2;
%         if qc(j)==1;
%             qc(j)= 2;
%             nlost_dataloggertemp=nlost_dataloggertemp+1;
%             %------
%            % data(LCO2_min,j)=ev; 
%             %------
%         elseif qc(j)==2;
%         end
%     

% %PULL OUT VARIABLES (with bad data removed) that will be used later, and
% %remove unreasonable values from them
% NEE=data(:,LCO2flux_corrected);
% H_dry=data(:, LSensibleHeat_dry); %????? is this the one we want?????!
% H_wet=data(:, LSensibleHeat_wet); %????? is this the one we want?????!
% H_wetwet=data(:, LSensibleHeat_wetwet); %????? is this the one we want?????!
% LE=data(:, LLatentHeat_corrected); %????? is this the one we want?????!
% 
% for n=1:datalength;
%     if H_dry(n)<-100;
%        H_dry(n)=ev; 
%        data(n, LSensibleHeat_dry)=ev;
%     end
%     if H_wet(n)<-100;
%        H_wet(n)=ev; 
%        data(n, LSensibleHeat_wet)=ev;
%     end
%     if H_wetwet(n)<-100;
%        H_wetwet(n)=ev; 
%        data(n, LSensibleHeat_wetwet)=ev;
%     end
%     if LE(n)<-10;
%        LE(n)=ev; 
%        data(n, LLatentHeat_corrected)=ev;
%     end
%     if NEE(n)<-30 || NEE(n) >20;
%        NEE(n)=ev; 
%        data(n, LCO2flux_corrected)=ev;
%     end
% end
% 
% %replace missing Tair's
% for n=1:datalength
%     if isnan(Tair(n))==1
%         Tair(n)=T30min(n);
%     end
% end

% %_____________________________________
% 
% %MAKE PIE CHARTS OF DATA QUALITY
% if pie_charts==1;
%     disp('making pie charts...')
%      %pie chart 1- all error sources
%     gooddata=datalength-nRemoved;
%     data_categories=[gooddata nData_lost nlost_dataloggertemp nRemoved_agc  nRemoved_irga advection nRemoved_u_star nRemoved_wnd_dir nRemoved_n_Tot];
%     explode = [1 0 0 0 0 0 0 0 0];
%     pie(data_categories, explode);
%     legend ('Useable', 'Lost Data','Datalogger Malfunction (high T)', 'AGC high',  'IRGA warning', 'Advection', 'U* low', 'Wind from behind', '# samples low', 'location', 'bestoutside');
%     shg;
% 
%     figname= strcat (outfolder,filename,'_pie');
%     print ('-dpng', '-r300', figname);
% 
%     %pie chart 2-advection
%     no_advection=gooddata;
%     figure(2)
%     data_categories=[no_advection advection];
%     pie(data_categories);
%     legend('Minimal Advection', 'Advection', 'Location', 'BestOutside');
%     shg;
%     figname2=strcat(outfolder, filename,'_advection_pie');
%     print('-dpng', '-r300',figname2);
% else
% end
% 
% %OBTAIN SUBSETS OF DATA FOR SPECIFIC ANALYSES
% if data_for_analyses==1;
%     disp('creating files for specific analyses...')
%     %for nighttime respiration:
%     k=0;
%     day_n=NaN*ones(datalength/4,1);
%     month_n=NaN*ones(datalength/4,1);
%     year_n=NaN*ones(datalength/4,1);
%     hour_n=NaN*ones(datalength/4,1);
%     minute_n=NaN*ones(datalength/4,1);
%     Tair_n=NaN*ones(datalength/4,1);
%     Tsoil_n=NaN*ones(datalength/4,1);
%     NEE_n=NaN*ones(datalength/4,1);
%     soil_w_n=NaN*ones(datalength/4,1);
%     
%     for n=1:datalength;
%          if (Par_Avg(n) < 0.001 && NEE(n)<8 && NEE(n)>0)
%              k=k+1;
%             day_n(k)=day(n);
%             month_n(k)=month(n);
%             year_n(k)=year(n);
%             hour_n(k)=hour(n);
%             minute_n(k)=minute(n);
%             timestamp_n(k)=timestamp(n);
%             Tair_n(k)=Tair(n);
%             Tsoil_n(k)= Tsoil(n);
%             NEE_n(k)= data(n, LCO2flux_corrected);
%             soil_w_n(k)=soil_w(n);
%          elseif (isnan(Par_Avg(n))==1)&&(hour(n)<5 && NEE(n)<8 && NEE(n)>0)
%             k=k+1;
%             day_n(k)=day(n);
%             month_n(k)=month(n);
%             year_n(k)=year(n);
%             hour_n(k)=hour(n);
%             minute_n(k)=minute(n);
%             timestamp_n(k)=timestamp(n);
%             Tair_n(k)=Tair(n);
%             Tsoil_n(k)= Tsoil(n);
%             NEE_n(k)= data(n, LCO2flux_corrected);
%             soil_w_n(k)=soil_w(n);
%          else
%          end
%     end
% 
%     invTair=1./((273.15+Tair_n)*0.0000862);
%     invTsoil=1./((273.15+Tsoil_n)*0.0000862);
% 
%     header= { 'datestamp' 'day' 'month' 'year' 'hour' 'minute' 'Tair' '1/kTair' 'Tsoil' '1/kTsoil' 'soil_w' 'NEE' };
%     datamatrix= [day_n month_n year_n hour_n minute_n  Tair_n invTair Tsoil_n invTsoil soil_w_n NEE_n];  
%     outfilename=strcat(outfolder,filename,'_for_analyses');
%     xlswrite (outfilename, header, 'night_respiration', 'A1');
%     xlswrite(outfilename, timestamp_n', 'night_respiration', 'A2');
%     xlswrite (outfilename, datamatrix, 'night_respiration', 'B2');
% 
%     %for light-response curve
%     k=0;
%     day_l=NaN*ones(datalength/4,1);
%     month_l=NaN*ones(datalength/4,1);
%     year_l=NaN*ones(datalength/4,1);
%     hour_l=NaN*ones(datalength/4,1);
%     minute_l=NaN*ones(datalength/4,1);
%     Tair_l=NaN*ones(datalength/4,1);
%     Tsoil_l=NaN*ones(datalength/4,1);
%     NEE_l=NaN*ones(datalength/4,1);
%     Par_Avg_l=NaN*ones(datalength/4,1);
% 
%     for n=1:datalength;
%          if (hour(n)>= 6 && hour(n)<=12);
%              k=k+1;
%             day_l(k)=day(n);
%             month_l(k)=month(n);
%             year_l(k)=year(n);
%             hour_l(k)=hour(n);
%             minute_l(k)=minute(n);
%             timestamp_l(k)=timestamp(n);
%             Tair_l(k)=Tair(n);
%             NEE_l(k)= data(n, LCO2flux_corrected);
%             Par_Avg_l(k)=Par_Avg(n);
%          else
%          end
%     end
% 
%     invTair=1./((273.15+Tair_l)*0.0000862);
% 
%     header= { 'datestamp' 'day' 'month' 'year' 'hour' 'minute' 'Tair' '1/kTair' 'Par_Avg' 'NEE' };
%     datamatrix= [day_l month_l year_l hour_l minute_l  Tair_l invTair Par_Avg_l  NEE_l];  
%     outfilename=strcat(outfolder,filename,'_for_analyses');
%     xlswrite (outfilename, header, 'light_response', 'A1');
%     xlswrite(outfilename, timestamp_n', 'light_response', 'A2');
%     xlswrite (outfilename, datamatrix, 'light_response', 'B2');
% 
% 
%     %for peak daily NEE:
% 
%     %find peak NEE for each day
%     day_p=NaN*ones(datalength/48,1);
%     month_p=NaN*ones(datalength/48,1);
%     year_p=NaN*ones(datalength/48,1);
%     hour_p=NaN*ones(datalength/48,1);
%     minute_p=NaN*ones(datalength/48,1);
%     Tair_p=NaN*ones(datalength/48,1);
%     Tsoil_p=NaN*ones(datalength/48,1);
%     NEE_p=NaN*ones(datalength/48,1);
%     Par_Avg_p=NaN*ones(datalength/48,1);
%     k=0;
% 
%     for d=1:366;  %go through days
%         c_minNEE=9999;
%         c_min_n=0;
%         count=0;
%         for n=1:datalength;  %for each day, cycle through data
%             if jday(n)==d;
%                     if ((isnan(NEE(n))==0))
%                         count=count+1;
%                     end
%                 if ((NEE(n)<= c_minNEE))
%                     c_minNEE=NEE(n);
%                     c_min_n=n;         
%                 elseif ((NEE(n) >c_minNEE))
%                 end
%             else
%             end
%         end
%             if (c_min_n>0 && count >=36 && hour(c_min_n)>=7 && hour(c_min_n)<=19 ); 
%                 k=k+1;
%                 day_p(k)=day(c_min_n);
%                 month_p(k)=month(c_min_n);
%                 year_p(k)=year(c_min_n);
%                 hour_p(k)=hour(c_min_n);
%                 minute_p(k)=minute(c_min_n);
%                 timestamp_p(k)=timestamp(c_min_n);
%                 Tair_p(k)=Tair(c_min_n);
%                 NEE_p(k)= data(c_min_n, LCO2flux_corrected);
%                 Par_Avg_p(k)=Par_Avg(c_min_n);
%             else
%         end
%     end
% 
%     invTair=1./((273.15+Tair_p)*0.0000862);
% 
%     header= { 'datestamp' 'day' 'month' 'year' 'hour' 'minute' 'Tair' '1/kTair' 'Par_Avg' 'NEE' };
%     datamatrix= [day_p month_p year_p hour_p minute_p  Tair_p invTair Par_Avg_p  NEE_p];  
%     outfilename=strcat(outfolder,filename,'_for_analyses');
%     xlswrite (outfilename, header, 'peak_NEE', 'A1');
%     xlswrite(outfilename, timestamp_p', 'peak_NEE', 'A2');
%     xlswrite (outfilename, datamatrix, 'peak_NEE', 'B2');
% else
% end
% 
% if make_plots==1;
%     disp('creating plots...')
%     figure(3)
%     plot3(hour, wnd_dir, NEE, 'o');
%     axis ([0 24 0 360 -15 10]);
%     xlabel('hour');
%     ylabel('wind direction');
%     zlabel('NEE');
%     shg;
% 
%     figname= strcat (outfolder,filename,'_wind');
%     hgsave(figname);
%     print ('-dpng', '-r300', figname);
%     
%     figure (4)
%     subplot(3,1,1) 
%     plot(wnd_dir, NEE,'o')
%     xlabel('wind direction');
%     ylabel('NEE');
%     axis([0 360 -15 10]);
%     subplot(3,1,2)
%     plot(hour, NEE, 'o')
%     xlabel('hour');
%     ylabel('NEE');
%     axis([0 24 -15 10]);
%     subplot(3,1,3)
%     plot(hour, wnd_dir, 'o')
%     xlabel('hour');
%     ylabel('wind direction');
%     
%     figname= strcat (outfolder,filename,'_wind2');
%     hgsave(figname);
%     print ('-dpng', '-r300', figname);
% end
% 
% if ET_gap_filler==1
%     disp('writing file for ETgapFiller...')
%     header= { 'datestamp' 'VW_Avg' 'TSoil1' 'TSoil2' 'TSoil3' 'TSoil4' 'NetRadiation' 'H_dry' 'H_wet' 'H_wetwet' 'LE'};    
%     datamatrix= [soil_w Tsoilmatrix RN_Avg H_dry H_wet H_wetwet LE ];  
%     outfilename=strcat(outfolder,filename,'_for_ETgapFiller');
%     xlswrite (outfilename, header, 'data', 'A1');
%     xlswrite(outfilename, timestamp, 'data', 'A2');
%     xlswrite (outfilename, datamatrix, 'data', 'B2');
% end
% 
% disp('DONE!')
