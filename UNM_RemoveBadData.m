% This program was created by Krista Anderson Teixeira in July 2007
% Modified by John DeLong 2008 through 2009
%
% The program reads site_fluxall_year excel files and pulls in a
% combination of matlab processed ts data and data logged average 30-min
% flux data.  It then flags values based on a variety of criteria and
% writes out new files that do not have the identified bad values.  It
% writes out a site_flux_all_qc file and a site_flux_all_for_gap_filling
% file to send to the Reichstein online gap-filling program.  It can be
% adjusted to make other subsetted files too.
%
% This program is set up to run as a function where you enter the command
% along with the sitecode (1-7 see below) and the year.  This means that it
% only runs on files that are broken out by year.
%
% UNM_RemoveBadData_080310(sitecode,year)

function [] = UNM_RemoveBadData(sitecode,year)
%clear all
%close all

% sitecode = 10;
% year = 2011;
iteration = 6;

% sitecode key
% 1-GLand
% 2-SLand
% 3-JSav
% 4-PJ
% 5-PPine
% 6-MCon
% 7-TX_savanna
% 8-TX_forest
% 9-TX_grassland

write_complete_out_file = 1; %1 to write "[sitename].._qc", -- file with all variables & bad data removed
data_for_analyses = 0; %1 to output file with data sorted for specific analyses
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
        filelength_n = 17523;
        lastcolumn='HC';
        ustar_lim = 0.06;
        co2_min = -7; co2_max = 6;
        co2_max_by_month = [2.5 2.5 2.5 2.5 3.5 3.5 3.5 3.5 3.5 2.5 2.5 2.5];
        co2_min_by_month = [-0.5 -0.5 -1 -3 -3 -4 -4 -4 -4 -1 -0.5 -0.5];
    elseif year == 2008;
        filelength_n = 17572;
        lastcolumn='HD';
        ustar_lim = 0.06;
        co2_min = -10; co2_max = 6;
    elseif year == 2009;
        filelength_n = 17520;
        lastcolumn='IC';
        ustar_lim = 0.06;
        co2_min = -10; co2_max = 6;
    elseif year == 2010;
        filelength_n = 17523;
        lastcolumn='IL';
        ustar_lim = 0.06;
        co2_min = -10; co2_max = 6;
    elseif year == 2011;
        filelength_n = 17523;
        lastcolumn='IL';
        ustar_lim = 0.06;
        co2_min = -10; co2_max = 6;
    end
    wind_min = 330; wind_max = 30; % these are given a sonic_orient = 180;
    Tdry_min = 240; Tdry_max = 320;
    HS_min = -100; HS_max = 450;
    HSmass_min = -100; HSmass_max = 450;
    LH_min = -150; LH_max = 450;
    rH_min = 0; rH_max = 1;
    h2o_max = 30; h2o_min = 0;

elseif sitecode==2; % shrubland
    site='SLand'
    if year == 2006
    elseif year == 2007
        filelength_n = 17523;
        lastcolumn='HA';
        ustar_lim = 0.08;
        co2_min = -4; co2_max = 3.5;
    elseif year == 2008
        filelength_n = 17572;
        lastcolumn='GZ';
        ustar_lim = 0.08;
        co2_min = -10; co2_max = 6;
    elseif year == 2009
        filelength_n = 17523;
        lastcolumn='IL';
        ustar_lim = 0.08;
        co2_min = -10; co2_max = 6;
    elseif year == 2010
        filelength_n = 17523;
        lastcolumn='IE';
        ustar_lim = 0.08;
        co2_min = -10; co2_max = 6;
    elseif year == 2011
        filelength_n = 17523;
        lastcolumn='IQ';
        ustar_lim = 0.08;
        co2_min = -10; co2_max = 6;
    end
    wind_min = 330; wind_max = 30; % these are given a sonic_orient = 180;
    Tdry_min = 240; Tdry_max = 320;
    HS_min = -100; HS_max = 450;
    HSmass_min = -100; HSmass_max = 450;
    LH_min = -150; LH_max = 450;
    rH_min = 0; rH_max = 1;
    h2o_max = 30; h2o_min = 0;
     
elseif sitecode==3; % Juniper savanna
    site = 'JSav'
    if year == 2007
        filelength_n = 11596;
        lastcolumn='HR';
        ustar_lim = 0.09;
        co2_min = -11; co2_max = 7;
    elseif year == 2008
        filelength_n = 17572;
        lastcolumn='HJ';
        ustar_lim = 0.08;
        co2_min = -10; co2_max = 10;
    elseif year == 2009
        filelength_n = 17523;
        lastcolumn='IN';
        ustar_lim = 0.08;
        co2_min = -10; co2_max = 10;
    elseif year == 2010
        filelength_n = 17523;
        lastcolumn='IE';
        ustar_lim = 0.08;
        co2_min = -10; co2_max = 10;
    elseif year == 2011
        filelength_n = 17523;
        lastcolumn='IE';
        ustar_lim = 0.08;
        co2_min = -10; co2_max = 10;
    end
    wind_min = 15; wind_max = 75; % these are given a sonic_orient = 225;
    Tdry_min = 240; Tdry_max = 320;
    HS_min = -100; HS_max = 450;
    HSmass_min = -100; HSmass_max = 450;
    LH_min = -150; LH_max = 450;
    rH_min = 0; rH_max = 1;
    h2o_max = 30; h2o_min = 0;
    press_min = 70; press_max = 130;
    
elseif sitecode == 4; % Pinyon Juniper
    site = 'PJ'
    if year == 2007
        lastcolumn = 'HO';
        filelength_n = 2514;
        ustar_lim = 0.16;
    elseif year == 2008
        lastcolumn = 'HO';
        filelength_n = 17572;
        ustar_lim = 0.16;
    elseif year == 2009
        lastcolumn = 'HJ';
        filelength_n = 17523;
        ustar_lim = 0.16;
    elseif year == 2010
        lastcolumn = 'HA';
        filelength_n = 17523;
        ustar_lim = 0.16;
    elseif year == 2011  % added this block Mar 21, 2011
        lastcolumn = 'EZ';
        filelength_n = 17523;
        ustar_lim = 0.16;
    end    
    wind_min = 15; wind_max = 75; % these are given a sonic_orient = 225;
    co2_min = -10; co2_max = 6;
    Tdry_min = 240; Tdry_max = 310;
    HS_min = -100; HS_max = 640;
    HSmass_min = -100; HSmass_max = 640;
    LH_min = -150; LH_max = 450;
    rH_min = 0; rH_max = 1;
    h2o_max = 30; h2o_min = 0;
    press_min = 70; press_max = 130;
    
elseif sitecode==5; % Ponderosa Pine
    site = 'PPine'
    if year == 2006
        filelength_n = 11594;
    elseif year == 2007
        filelength_n = 17524;
        lastcolumn='FV';
        ustar_lim = 0.08;
        co2_min = -15; co2_max = 15;
%        co2_min = -30; co2_max = 30;
    elseif year == 2008;
        filelength_n = 17572;
        lastcolumn='FU';
        ustar_lim = 0.08;
        co2_min = -15; co2_max = 15;
%        co2_min = -30; co2_max = 30;
    elseif year == 2009;
        filelength_n = 17523;
        lastcolumn='FY';
        ustar_lim = 0.08;
        co2_min = -15; co2_max = 15;
%        co2_min = -30; co2_max = 30;
    elseif year == 2010;
        filelength_n = 17523;
        lastcolumn='FW';
        ustar_lim = 0.08;
        co2_min = -15; co2_max = 15;
    elseif year == 2011;
        filelength_n = 17523;
        lastcolumn='FY';
        ustar_lim = 0.08;
        co2_min = -15; co2_max = 15;
    end
%    co2_max_by_month = [4 4 4 4 5 12 12 12 12 12 4 4];
    co2_max_by_month = [4 4 4 5 8 8 8 8 8 8 5 4];
    wind_min = 119; wind_max = 179; % these are given a sonic_orient = 329;
    Tdry_min = 240; Tdry_max = 310;
    HS_min = -200; HS_max = 800;
    HSmass_min = -200; HSmass_max = 800;
    LH_min = -50; LH_max = 550;
    rH_min = 0; rH_max = 1;
    h2o_max = 30; h2o_min = 0;
    
elseif sitecode==6; % Mixed conifer
    site = 'MCon'
    if year == 2006
        filelength_n = 4420;
        lastcolumn='GA';
        ustar_lim = 0.12;
        co2_min = -12; co2_max = 6;
    elseif year == 2007
        filelength_n = 17524;
        lastcolumn='GB';
        ustar_lim = 0.12;
        co2_min = -12; co2_max = 6;
    elseif year == 2008;
        filelength_n = 17420;
        lastcolumn='GB';
        ustar_lim = 0.11;
        co2_min = -12; co2_max = 6;
    elseif year == 2009;
        filelength_n = 17523;
        lastcolumn='GF';
        ustar_lim = 0.11;
        co2_min = -12; co2_max = 6;
    elseif year == 2010;
        filelength_n = 17523;
        lastcolumn='GI';
        ustar_lim = 0.11;
        co2_min = -12; co2_max = 6;
    elseif year == 2011;
        filelength_n = 17523;
        lastcolumn='GI';
        ustar_lim = 0.11;
        co2_min = -12; co2_max = 6;
    end
    
    wind_min = 153; wind_max = 213; % these are given a sonic_orient = 333;
    Tdry_min = 250; Tdry_max = 300;
    HS_min = -200; HS_max = 800;
    HSmass_min = -200; HSmass_max = 800;
    LH_min = -50; LH_max = 550;
    rH_min = 0; rH_max = 1;
    h2o_max = 30; h2o_min = 0;
    
elseif sitecode == 7;
    site = 'TX'
    if year == 2005
        filelength_n = 17522;
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
        filelength_n = 17452;
        lastcolumn='GP';
        ustar_lim = 0.11;
        co2_min = -16; co2_max = 6;
    elseif year == 2009;
        filelength_n = 17282;
        lastcolumn='GP';
        ustar_lim = 0.11;
        co2_min = -16; co2_max = 6;
    elseif year == 2011;
        filelength_n = 7282;
        lastcolumn='GQ';
        ustar_lim = 0.11;
        co2_min = -16; co2_max = 6;
    end
    wind_min = 296; wind_max = 356; % these are given a sonic_orient = 146;
    Tdry_min = 265; Tdry_max = 315;
    HS_min = -200; HS_max = 800;
    HSmass_min = -200; HSmass_max = 800;
    LH_min = -150; LH_max = 550;
    rH_min = 0; rH_max = 1;
    h2o_max = 30; h2o_min = 0;
    press_min = 70; press_max = 130;

elseif sitecode == 8;
    site = 'TX_forest'
    if year == 2005
        filelength_n = 17524;
        lastcolumn='DO';
        ustar_lim = 0.12;
    elseif year == 2006
        filelength_n = 17524;
        lastcolumn='DO';
        ustar_lim = 0.12;
    elseif year == 2007
        filelength_n = 17524;
        lastcolumn='DO';
        ustar_lim = 0.12;
    elseif year == 2008;
        filelength_n = 17571;
        lastcolumn='ET';
        ustar_lim = 0.12;
    elseif year == 2009;
        filelength_n = 17180;
        lastcolumn='ET';
        ustar_lim = 0.11;
    end
    co2_min = -26; co2_max = 12;
    wind_min = 300; wind_max = 360; % these are given a sonic_orient = ;
    Tdry_min = 265; Tdry_max = 315;
    HS_min = -200; HS_max = 800;
    HSmass_min = -200; HSmass_max = 800;
    LH_min = -150; LH_max = 550;
    rH_min = 0; rH_max = 1;
    h2o_max = 30; h2o_min = 0;
    press_min = 70; press_max = 130;
    
elseif sitecode == 9;
    site = 'TX_grassland'
    if year == 2005
        filelength_n = 17524;
        lastcolumn='DT';
        ustar_lim = 0.06;
    elseif year == 2006
        filelength_n = 17523;
        lastcolumn='DO';
        ustar_lim = 0.06;
    elseif year == 2007
        filelength_n = 17524;
        lastcolumn='DO';
        ustar_lim = 0.07;
    elseif year == 2008;
        filelength_n = 17571;
        lastcolumn='ET';
        ustar_lim = 0.11;
    elseif year == 2009;
        filelength_n = 17180;
        lastcolumn='ET';
        ustar_lim = 0.11;
    end
    co2_min = -26; co2_max = 12;
    wind_min = 300; wind_max = 360; % these are given a sonic_orient = ;
    Tdry_min = 265; Tdry_max = 315;
    HS_min = -200; HS_max = 800;
    HSmass_min = -200; HSmass_max = 800;
    LH_min = -150; LH_max = 550;
    rH_min = 0; rH_max = 1;
    h2o_max = 35; h2o_min = 0;
    press_min = 70; press_max = 130;

elseif sitecode == 10; % Pinyon Juniper girdle
    site = 'PJ_girdle'
    lastcolumn = 'FE';
    ustar_lim = 0.16;
    wind_min = 15; wind_max = 75; % these are given a sonic_orient = 225;
    co2_min = -10; co2_max = 6;
    Tdry_min = 240; Tdry_max = 310;
    HS_min = -100; HS_max = 640;
    HSmass_min = -100; HSmass_max = 640;
    LH_min = -150; LH_max = 450;
    rH_min = 0; rH_max = 1;
    h2o_max = 30; h2o_min = 0;
    press_min = 70; press_max = 130;
    if year == 2009
        filelength_n = 17523;
    elseif year == 2010
        filelength_n = 17523;
    elseif year == 2011
        filelength_n = 17523;
    end      

elseif sitecode == 11; % new Grassland
    site = 'New_GLand'
    ustar_lim = 0.06;
    if year == 2010
        lastcolumn = 'HF';
        filelength_n = 17524;
    elseif year == 2011
        lastcolumn = 'HS';
        filelength_n = 17523; % updated 10 Nov, 2011
        
    end  
    co2_min = -7; co2_max = 6;
    wind_min = 330; wind_max = 30; % these are given a sonic_orient = 180;
    Tdry_min = 240; Tdry_max = 320;
    HS_min = -100; HS_max = 450;
    HSmass_min = -100; HSmass_max = 450;
    LH_min = -150; LH_max = 450;
    rH_min = 0; rH_max = 1;
    h2o_max = 30; h2o_min = 0;
    
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Set up file name and file path
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

drive='c:';
row1=5;  %first row of data to process - rows 1 - 4 are header
filename = strcat(site,'_flux_all_',num2str(year))
%filename = strcat(site,'_new_radiation_flux_all_',num2str(year))
filelength = num2str(filelength_n);
%datalength = filelength_n - row1 + 1; 
filein = strcat(drive,'\Research_Flux_Towers\Flux_Tower_Data_by_Site\',site,'\',filename)
outfolder = strcat(drive,'\Research_Flux_Towers\Flux_Tower_Data_by_Site\',site,'\processed_flux\');
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
datalength = size(data,1);
[num text] = xlsread(filein,time_stamp_range);
timestamp = text;
[year month day hour minute second] = datevec(timestamp);
datenumber = datenum(timestamp);
disp('file read');



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Read in Matlab processed ts data (these are in the same columns for all
% sites, so they can be just hard-wired in by column number
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if year(2) < 2009 && sitecode ~= 3 
    if sitecode == 7 && year(2) == 2008 % This is set up for 2009 output
        disp('TX 2008 is set up as 2009 output');
        stop
    end
    
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
u_mean=data(:,10);
t_mean=data(:,13);
t_meanK=t_mean+ 273.15;

fc_raw = data(:,38);
fc_raw_massman = data(:,39);
fc_water_term = data(:,42);
fc_heat_term_massman = data(:,45);
fc_raw_massman_wpl = data(:,46); % = flux_co2_massman + flux_co2_wpl_water + flux_co2_massman_wpl_heat

E_raw = data(:,47);
E_raw_massman = data(:,44);
E_water_term = data(:,51);
E_heat_term_massman = data(:,50);
E_wpl_massman = data(:,55); % = flux_h20_wpl_water + flux_h20_massman_wpl_heat

HSdry = data(:,56);
HSdry_massman = data(:,59);

HL_raw = data(:,60);
HL_wpl_massman = data(:,64);
HL_wpl_massman_un = data(:,63);
% Half hourly data filler only produces uncorrected HL_wpl_massman, but use
% these where available
HL_wpl_massman(isnan(HL_wpl_massman)&~isnan(HL_wpl_massman_un))=HL_wpl_massman_un(isnan(HL_wpl_massman)&~isnan(HL_wpl_massman_un));

rhoa_dry = data(:,65);

decimal_day = ( datenum( year, month, day, hour, minute, second ) - ...
                datenum( year, 1, 1 ) + 1 );
              
year2 = year(2);

for i=1:ncol;
    if strcmp('RH',headertext(i)) == 1 || strcmp('rh_hmp', headertext(i)) == 1 || strcmp('rh_hmp_4_Avg', headertext(i)) == 1
        rH = data(:,i-1);
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
else
    
jday=data(:,8);
iok=data(:,9);
Tdry=data(:,14);
wnd_dir_compass=data(:,15);
wnd_spd=data(:,16);
u_star=data(:,28);
CO2_mean=data(:,32);
CO2_std=data(:,33);
H2O_mean=data(:,37);
H2O_std=data(:,38);
u_mean=data(:,10);
t_mean=data(:,13);
t_meanK=t_mean+ 273.15;

fc_raw = data(:,39);
fc_raw_massman = data(:,40);
fc_water_term = data(:,41);
fc_heat_term_massman = data(:,42);
fc_raw_massman_wpl = data(:,43); % = flux_co2_massman + flux_co2_wpl_water + flux_co2_massman_wpl_heat

E_raw = data(:,44);
E_raw_massman = data(:,45);
E_water_term = data(:,46);
E_heat_term_massman = data(:,47);
E_wpl_massman = data(:,48);

HSdry = data(:,50);
HSdry_massman = data(:,53);

HL_raw = data(:,54);
HL_wpl_massman = data(:,56);
HL_wpl_massman_un = data(:,55);
% Half hourly data filler only produces uncorrected HL_wpl_massman, but use
% these where available as very similar values
HL_wpl_massman(isnan(HL_wpl_massman)&~isnan(HL_wpl_massman_un))=HL_wpl_massman_un(isnan(HL_wpl_massman)&~isnan(HL_wpl_massman_un));

rhoa_dry = data(:,57);

decimal_day = ( datenum( year, month, day, hour, minute, second ) - ...
                datenum( year, 1, 1 ) + 1 );
year2 = year(2);

 end

%initialize RH to NaN
rH = repmat( NaN, size( data, 1), 1 );

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Read in 30-min data, variable order and names in flux_all files are not  
% consistent so match headertext
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

for i=1:ncol;
    if strcmp('agc_Avg',headertext(i)) == 1
        agc_Avg = data(:,i-1);
    elseif strcmp('RH',headertext(i)) == 1 || ...
            strcmp('rh_hmp', headertext(i)) == 1 || ...
            strcmp('rh_hmp_4_Avg', headertext(i)) == 1 || ...
            strcmp('RH_Avg', headertext(i)) == 1
        rH = data(:,i-1) / 100.0;
    elseif strcmp( 'Ts_mean', headertext( i ) )
        Tair_TOA5 = data(:,i-1);    
    elseif  strcmp('5point_precip', headertext(i)) == 1 || ...
            strcmp('rain_Tot', headertext(i)) == 1 || ...
            strcmp('precip', headertext(i)) == 1 || ...
            strcmp('precip(in)', headertext(i)) == 1 || ...
            strcmp('ppt', headertext(i)) == 1 || ...
            strcmp('Precipitation', headertext(i)) == 1
        precip = data(:,i-1);
    elseif strcmp('press_mean', headertext(i)) == 1 || ...
            strcmp('press_Avg', headertext(i)) == 1 || ...
            strcmp('press_a', headertext(i)) == 1 || ...
            strcmp('press_mean', headertext(i)) == 1
        atm_press = data(:,i-1);
    elseif strcmp('par_correct_Avg', headertext(i)) == 1  || ...
            strcmp('par_Avg(1)', headertext(i)) == 1 || ...
            strcmp('par_Avg', headertext(i)) == 1 || ...
            strcmp('par_up_Avg', headertext(i)) == 1 || ...        
            strcmp('par_face_up_Avg', headertext(i)) == 1 || ...
            strcmp('par_incoming_Avg', headertext(i)) == 1 || ...
            strcmp('par_lite_Avg', headertext(i)) == 1
        Par_Avg = data(:,i-1);
    elseif strcmp('t_hmp_mean', headertext(i))==1 || ...
            strcmp('AirTC_Avg', headertext(i))==1 || ...
            strcmp('t_hmp_3_Avg', headertext(i))==1 || ...
            strcmp('pnl_tmp_a', headertext(i))==1 || ...
            strcmp('t_hmp_Avg', headertext(i))==1 || ...
            strcmp('t_hmp_4_Avg', headertext(i))==1 || ...
            strcmp('t_hmp_top_Avg', headertext(i))==1
        air_temp_hmp = data(:,i-1);
    elseif strcmp('AirTC_2_Avg', headertext(i))==1 && ...
            (year2 == 2009 || year2 ==2010) && sitecode == 6
        air_temp_hmp = data(:,i-1);
    elseif strcmp('Tsoil',headertext(i)) == 1 || ...
            strcmp('Tsoil_avg',headertext(i)) == 1 || ...
            strcmp('soilT_Avg(1)',headertext(i)) == 1
        Tsoil = data(:,i-1);
    elseif strcmp('Rn_correct_Avg',headertext(i))==1 || ...
            strcmp('NR_surf_AVG', headertext(i))==1 || ...
            strcmp('NetTot_Avg_corrected', headertext(i))==1 || ...
            strcmp('NetTot_Avg', headertext(i))==1 || ...
            strcmp('Rn_Avg',headertext(i))==1 || ...
            strcmp('Rn_total_Avg',headertext(i))==1
        NR_tot = data(:,i-1);
    elseif strcmp('Rad_short_Up_Avg', headertext(i)) || ...
            strcmp('pyrr_incoming_Avg', headertext(i))
        sw_incoming = data(:,i-1);
    elseif strcmp('Rad_short_Dn_Avg', headertext(i))==1 || ...
            strcmp('pyrr_outgoing_Avg', headertext(i))==1
        sw_outgoing = data(:,i-1);
    elseif strcmp('Rad_long_Up_Avg', headertext(i)) == 1 || ...
            strcmp('Rad_long_Up__Avg', headertext(i)) == 1
        lw_incoming = data(:,i-1);
    elseif strcmp('Rad_long_Dn_Avg', headertext(i))==1 || ...
            strcmp('Rad_long_Dn__Avg', headertext(i))==1
        lw_outgoing = data(:,i-1);
    elseif strcmp('VW_Avg', headertext(i))==1
        VWC = data(:,i-1);
    elseif strcmp('shf_Avg(1)', headertext(i))==1 || ...
            strcmp('shf_pinon_1_Avg', headertext(i))==1
        soil_heat_flux_1 = data(:,i-1);
        disp('FOUND shf_pinon_1_Avg');       
    elseif any( strcmp( headertext(i), ...
                        { 'hfp_grass_1_Avg', 'hfp01_grass_Avg' } ) )
        soil_heat_flux_1 = data(:,i-1);
        disp('FOUND hfp_grass_1_Avg');       
    elseif any( strcmp( headertext( i ), ...
                        { 'hfp_grass_2_Avg', 'hft3_grass_Avg' } ) )
        soil_heat_flux_2 = data(:,i-1);
        disp('FOUND hfp_grass_2_Avg');       
    elseif strcmp('shf_Avg(2)', headertext(i))==1 || ...
            strcmp('shf_jun_1_Avg', headertext(i))==1
        soil_heat_flux_2 = data(:,i-1);
    elseif strcmp('hfpopen_1_Avg', headertext(i))==1 % only for TX
        soil_heat_flux_open = data(:,i-1);
    elseif strcmp('hfpmescan_1_Avg', headertext(i))==1 % only for TX
        soil_heat_flux_mescan = data(:,i-1);
    elseif strcmp('hfpjuncan_1_Avg', headertext(i))==1 % only for TX
        soil_heat_flux_juncan = data(:,i-1);
    %Shurbland flux plates 2009 onwards
    elseif strcmp('hfp01_1_Avg', headertext(i))==1 
        soil_heat_flux_1 = data(:,i-1);
    elseif strcmp('hfp01_2_Avg', headertext(i))==1 
        soil_heat_flux_2 = data(:,i-1);
    elseif strcmp('hfp01_3_Avg', headertext(i))==1 
        soil_heat_flux_3 = data(:,i-1);
    elseif strcmp('hfp01_4_Avg', headertext(i))==1 
        soil_heat_flux_4 = data(:,i-1);
    elseif strcmp('hfp01_5_Avg', headertext(i))==1 
        soil_heat_flux_5 = data(:,i-1);
    elseif strcmp('hfp01_6_Avg', headertext(i))==1 
        soil_heat_flux_6 = data(:,i-1);
    elseif strcmp('shf_Avg(3)', headertext(i))==1 
        soil_heat_flux_3 = data(:,i-1);
    elseif strcmp('shf_Avg(4)', headertext(i))==1 
        soil_heat_flux_4 = data(:,i-1);
        
    end
end

if ismember( sitecode, [ 3, 4 ] )
    % use "RH" at JSav, PJ
    rh_col = find( strcmp( 'RH', headertext ) ) - 1;
    fprintf( 'found RH\n' );
    RH = data( :, rh_col ) / 100.0;
elseif ismember( sitecode, [ 5, 6 ] )
    % use "RH_2" at PPine, MCon
    rh_col = find( strcmp( 'RH_2', headertext ) ) - 1;
    fprintf( 'found RH_2\n' );
    RH = data( :, rh_col ) / 100.0;
end




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% correction for incorrectly-calculated latent heat flux pointed out by Jim
% Heilman 8 Mar 2012.  E_heat_term_massman should have been added to the
% latent heat flux.  To do the job right, this fix should happen in
% UNM_flux_DATE.m.  Doing the correction here is a temporary fix in order to
% get Ameriflux files created soon.
% -TWH 9 Mar 2012
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Lv = ( repmat( 2.501, size( E_raw_massman ) ) - ...
       0.00237 * ( Tdry - 273.15 ) )  * 10^3;
HL_wpl_massman = ( 18.016 / 1000 * Lv ) .* ...
    ( E_raw_massman + E_heat_term_massman );

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Site-specific steps for soil temperature
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if sitecode == 1 %GLand   added TWH, 27 Oct 2011
    for i=1:ncol;
        if strcmp('TCAV_grass_Avg',headertext(i)) == 1
            Tsoil = data(:,i-1);
        end
    end

elseif sitecode == 2 %SLand   added TWH, 4 Nov 2011
    for i=1:ncol;
        if strcmp( 'shf_sh_1_Avg', headertext( i ) ) == 1
            soil_heat_flux_1 = data(:,i-1);
        end    
        if strcmp( 'shf_sh_2_Avg', headertext( i ) ) == 1
            soil_heat_flux_2 = data(:,i-1);
        end
    end

elseif sitecode == 4 %PJ
    for i=1:ncol;
        if strcmp('tcav_pinon_1_Avg',headertext(i)) == 1
            Tsoil1 = data(:,i-1);
        elseif strcmp('tcav_jun_1_Avg',headertext(i)) == 1
            Tsoil2 = data(:,i-1);
        end
    end
    if exist( 'Tsoil1' ) == 1 & exist( 'Tsoil2' ) == 1
        Tsoil = (Tsoil1 + Tsoil2)/2;
    else
        Tsoil = repmat( NaN, size( data, 1 ), 1 );
    end
    soil_heat_flux_1 = repmat( NaN, size( data, 1 ), 1 );
    soil_heat_flux_2 = repmat( NaN, size( data, 1 ), 1 );
   
   % related lines 678-682: corrections for site 4 (PJ) soil_heat_flux_1 and soil_heat_flux_2
   Tsoil=sw_incoming.*NaN;  %MF: note, this converts all values in Tsoil to NaN. Not sure if this was intended.
  
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
        elseif strcmp('shf_Avg(1)',headertext(i)) == 1
            soil_heat_flux_1 = data(:,i-1);
        elseif strcmp('shf_Avg(2)',headertext(i)) == 1
            soil_heat_flux_2 = data(:,i-1);
        elseif strcmp('shf_Avg(3)',headertext(i)) == 1
            soil_heat_flux_3 = data(:,i-1);
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
    
    elseif sitecode == 10 || sitecode == 11
       Tsoil=sw_incoming.*NaN;
       soil_heat_flux_1 =sw_incoming.*NaN;
       soil_heat_flux_2 =sw_incoming.*NaN;
end


% Juniper S heat flux plates need multiplying by calibration factors
if sitecode == 3 
    soil_heat_flux_1 = soil_heat_flux_1.*32.27;
    soil_heat_flux_2 = soil_heat_flux_2.*33.00;
    soil_heat_flux_3 = soil_heat_flux_3.*31.60;
    soil_heat_flux_4 = soil_heat_flux_4.*32.20;
end

% Pinon Juniper heat flux plates need multiplying by calibration factors
if sitecode == 4 
    
    soil_heat_flux_1 = soil_heat_flux_1.*35.2;
    soil_heat_flux_2 = soil_heat_flux_2.*32.1;
end


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
        
    elseif year2 >= 2008
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
        
    elseif any( intersect ( year2, 2008:2011 ) )
        % calibration and unit conversion into W per m^2 for CNR1 variables
        % adjust for program error and convert into W per m^2
        sw_incoming = sw_incoming./136.99.*(1000./12.34);
        sw_outgoing = sw_outgoing./136.99.*(1000./12.34);
        lw_incoming = lw_incoming./136.99.*(1000./12.34);
        lw_outgoing = lw_outgoing./136.99.*(1000./12.34);
        % temperature correction just for long-wave
        lw_incoming = lw_incoming + 0.0000000567.*(Tdry).^4;
        lw_outgoing = lw_outgoing + 0.0000000567.*(Tdry).^4;
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
    elseif any( intersect ( year2, 2008:2011 ) )
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
        
        lw_incoming(find(decimal_day > 171.5)) = lw_incoming(find(decimal_day > 171.5)) + 0.0000000567.*(Tdry(find(decimal_day > 171.5))).^4; % temperature correction just for long-wave
        lw_outgoing(find(decimal_day > 171.5)) = lw_outgoing(find(decimal_day > 171.5)) + 0.0000000567.*(Tdry(find(decimal_day > 171.5))).^4; % temperature correction just for long-wave
        
        % calculate new net radiation values
        NR_lw = lw_incoming - lw_outgoing;
        NR_sw = sw_incoming - sw_outgoing;
        NR_tot(find(decimal_day > 171.5)) = NR_lw(find(decimal_day > 171.5)) + NR_sw(find(decimal_day > 171.5));
    elseif year2 == 2009 || year2 == 2010 || year2 == 2011
        % calibration for par-lite installed on 2/11/08
        Par_Avg = Par_Avg.*1000./5.51;
        % calculate new net radiation values
        NR_lw = lw_incoming - lw_outgoing;
        NR_sw = sw_incoming - sw_outgoing;
        NR_tot = NR_lw + NR_sw;
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
        Par_Avg=Par_Avg.*225;  % Apply correct calibration value 7.37, SA190 manual section 3-1
        Par_Avg=Par_Avg+(0.2210.*sw_incoming); % Apply correction to bring in to line with Par-lite from mid 2008 onwards
    
    elseif year2 == 2008
        % radiation values apparently already calibrated and unit-converted
        % in progarm for valles sites
        lw_incoming = lw_incoming + 0.0000000567.*(Tdry).^4; % temperature correction just for long-wave
        lw_outgoing = lw_outgoing + 0.0000000567.*(Tdry).^4; % temperature correction just for long-wave        
        NR_lw = lw_incoming - lw_outgoing; % calculate new net long wave
        NR_sw = sw_incoming - sw_outgoing; % calculate new net short wave
        NR_tot = NR_lw + NR_sw;
        % calibration for Licor sesor  
        Par_Avg(1:10063)=Par_Avg(1:10063).*225;  % Apply correct calibration value 7.37, SA190 manual section 3-1
        Par_Avg(1:10063)=Par_Avg(1:10063)+(0.2210.*sw_incoming(1:10063));
        % calibration for par-lite sensor
        Par_Avg(10064:17568) = Par_Avg(10064:17568).*1000./5.25;
        
    elseif year2 == 2009 || year2 ==2010 || year2 == 2011
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
        
    elseif year2 == 2008 || year2 == 2009 || year2 == 2010 || year2 == 2011
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
    if year2 == 2007 || year2 == 2006 || year2 == 2005
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
        Par_Avg(find(Par_Avg > 9.5)) = NaN;
        Par_Avg = Par_Avg.*1000./(6.16.*0.604);
    elseif year2 == 2008 || year2 == 2009
        % par switch to par-lite on ??
        NR_lw = lw_incoming - lw_outgoing;
        NR_sw = sw_incoming - sw_outgoing;
        NR_tot = NR_lw + NR_sw;
    end
    
elseif intersect( sitecode, [ 9, 10 ] )
        NR_lw = lw_incoming - lw_outgoing;
        NR_sw = sw_incoming - sw_outgoing;
        NR_tot = NR_lw + NR_sw;

%%%%%%%%%%%%%%%%% New Grassland
elseif sitecode == 11 
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

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Apply Burba 2008 correction for sensible heat conducted from 7500
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% define some constants
R = 8.3143e-3; % universal gas constant  [J / kmol / K ]
Rd = 287.04; % dry air gas constant [J / kg / K]
MWd = 28.97; % dry air molecular weight [g / mol]
R_h2o = 461.5; % water vapor gas constant [J / kg / K]
MW_h2o = 16; % water vapor molecular weight [g / mol]

% This is the conversion from mumol mol to mg m3 for CO2
hh = (1 ./ ( R .* ( t_meanK ./ atm_press ) .* 1000 ) ) .* 44;
% convert umol CO2 / mol dry air to mg CO2 / m3 dry air -- TWH
% cf_co2 abbreviates "conversion factor CO2"
%cf_co2 = ( ( MWd * Rd * t_meanK ) / ( 1000 * atm_press ) ) * ( 44 / 1000 );
CO2_mg = CO2_mean .* hh;

% This is the conversion from mmol mol to g m3 for H2O
gg = ( ( 1 ./ ...
         ( R .* ( t_meanK ./ atm_press ) ) ) .* 18 ) ...
     ./ 1000;
% convert mmol H2O / mol dry air to g H2O / m3 dry air -- TWH
% cf_co2 abbreviates "conversion factor CO2"
%cf_h2o = ( MW_h2o * R_h2o * t_meanK ) / ( 1000 * atm_press )
H2O_g = H2O_mean .* gg;

rhoa_dry_kg = ( rhoa_dry .* MWd ) ./ 1000; % from mol/m3 to kg/m3

Cp = 1004.67 + ( Tdry .^ 2 ./ 3364 );
RhoCp = rhoa_dry_kg .* Cp;
NR_pos = find( NR_tot > 0 );

Kair = ( 0.000067 .* t_mean ) + 0.024343;

Ti_bot = (0.883.*t_mean+2.17)+273.16;
Ti_bot(NR_pos) = (0.944.*t_mean(NR_pos)+2.57)+273.16;
Ti_top = (1.008.*t_mean-0.41)+273.16;
Ti_top(NR_pos) = (1.005.*t_mean(NR_pos)+0.24)+273.16;
Ti_spar = (1.01.*t_mean-0.17)+273.16;
Ti_spar(NR_pos) = (1.01.*t_mean(NR_pos)+0.36)+273.16;
Si_bot = Kair.*(Ti_bot-t_meanK)./(0.004.*sqrt(0.065./abs(u_mean))+0.004);
Si_top = ( Kair.*(Ti_top-t_meanK) .* ...
           (0.0225+(0.0028.*sqrt(0.045./abs(u_mean)) + ...
                    0.00025./abs(u_mean)+0.0045)) ./ ...
           (0.0225*(0.0028*sqrt(0.045./abs(u_mean)) + ...
                    0.00025./abs(u_mean)+0.0045)) );
Sip_spar = ( Kair .* (Ti_spar - t_meanK) ./ ...
             (0.0025 .* log((0.0025 + 0.0058.*sqrt(0.005./abs(u_mean))) ./ ...
                            0.0025)).*0.15 );
pd = 44.6.*28.97.*atm_press./101.3.*273.16./t_meanK;
dFc = (Si_top+Si_bot+Sip_spar) ./ RhoCp.*CO2_mg ./ t_meanK .* ...
      (1+1.6077.*H2O_g./pd);

h_burba_fig = figure; 
plot(dFc,'.'); ylim([-1 1]);
ylabel('Burba cold temp correction');
xlabel('time');

fc_mg = fc_raw_massman_wpl.*0.044; % Convert correct flux from mumol/m2/s to
                                   % mg/m2/s
fc_mg_corr = (fc_raw_massman_wpl.*0.044)+dFc;


found = find(t_mean<0);
fc_out=fc_mg;
fc_out(found)=fc_mg_corr(found);
% not sure what this next line is plotting -- TWH 23 Mar 2012
%figure; plot(fc_mg.*22.7273,'-'); hold on; plot(fc_out.*22.7273,'r-'); ylim([-20 20]);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Set up filters for co2 and make a master flag variable (decimal_day_nan)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

decimal_day_nan = decimal_day;
record = 1:1:length(fc_raw_massman_wpl);
conc_record = 1:1:length(CO2_mean);

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
nanflag = find(isnan(fc_raw_massman_wpl));
removednans = length(nanflag);
decimal_day_nan(nanflag) = NaN;
record(nanflag) = NaN;
nanflag = find(isnan(CO2_mean));
conc_record(nanflag) = NaN;
disp(sprintf('    original empties = %d',removednans));

% % Remove values during precipitation
precipflag = find(precip > 0);
removed_precip = length(precipflag);
decimal_day_nan(precipflag) = NaN;
record(precipflag) = NaN;
conc_record(precipflag) = NaN;
disp(sprintf('    precip = %d',removed_precip));

% Remove for behind tower wind direction
windflag = find(wnd_dir_compass > wind_min & wnd_dir_compass < wind_max);
removed_wind = length(windflag);
decimal_day_nan(windflag) = NaN;
record(windflag) = NaN;
disp(sprintf('    wind direction = %d',removed_wind));

% Remove night-time negative fluxes
% changed NEE cutoff from 0 to -0.2 as per conversation with Marcy 29 Mar 2012
nightnegflag = find( Par_Avg < 20.0 & fc_raw_massman_wpl < -0.2);
removed_nightneg = length(nightnegflag);
decimal_day_nan(nightnegflag) = NaN;
record(nightnegflag) = NaN;
disp(sprintf('    night-time negs = %d',removed_nightneg));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PPINE EXTRA WIND DIRECTION REMOVAL
% ppine has super high night respiration when winds come from ~ 50 degrees, so these must be excluded also:
if sitecode == 5
    ppine_night_wind = find((wnd_dir_compass > 30 & wnd_dir_compass < 65)& (hour <= 9 | hour > 18));
    ppine_night_wind = find((wnd_dir_compass > 25 & wnd_dir_compass < 70));
    removed_ppine_night_wind = length(ppine_night_wind);
    decimal_day_nan(ppine_night_wind) = NaN;
    record(ppine_night_wind) = NaN;
    conc_record(ppine_night_wind) = NaN;
    disp(sprintf('    ppine night winds = %d',removed_ppine_night_wind));
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% gland 2007 had large fluxes for very cold temperatures early in the year.
if sitecode == 1 && year2 == 2007
    gland_cold = find(Tdry < 271);
    removed_gland_cold = length(gland_cold);
    decimal_day_nan(gland_cold) = NaN;
    record(gland_cold) = NaN;
    disp(sprintf('    gland cold = %d',removed_gland_cold));
end

% Take out dodgy calibration period at Shrubland in 2007
if sitecode == 2 && year2 == 2007 
    decimal_day_nan(12150:12250) = NaN;
    record(12150:12250) = NaN;
    conc_record(12600:12750) = NaN;
end
    
% Take out dodgy calibration period at Shrubland in 2009
if sitecode == 2 && year2 == 2009 
    conc_record(11595:11829) = NaN;
end

    
% Plot out to see and determine ustar cutoff
if iteration == 1    
    u_star_2 = u_star(find(~isnan(decimal_day_nan)));
    fc_raw_massman_wpl_2 = fc_raw_massman_wpl(find(~isnan(decimal_day_nan)));
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
        co2mean(i) = mean(fc_raw_massman_wpl_2(elementstouse));
    end

    startbin;

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
    
    % Remove values with low U*
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
    if sitecode ==1 && year(1) == 2007
        removed_maxs_mins=0;
        for i = 1:12
                maxminflag = find((month==i & fc_raw_massman_wpl> co2_max_by_month(i)) | (month ==i & fc_raw_massman_wpl < co2_min_by_month(i)));
                removed_maxs_mins = removed_maxs_mins+length(maxminflag);
                decimal_day_nan(maxminflag) = NaN;
                record(maxminflag) = NaN;
        end
    elseif sitecode == 5
        removed_maxs_mins=0;
        for i = 1:12
                maxminflag = find((month==i & fc_raw_massman_wpl> co2_max_by_month(i)) | (month ==i & fc_raw_massman_wpl < co2_min) | fc_raw_massman_wpl == 0);
                removed_maxs_mins = removed_maxs_mins+length(maxminflag);
                decimal_day_nan(maxminflag) = NaN;
                record(maxminflag) = NaN;
        end
    else
    % Pull out maxs and mins
    maxminflag = find(fc_raw_massman_wpl > co2_max | fc_raw_massman_wpl < co2_min);
    removed_maxs_mins = length(maxminflag);
    decimal_day_nan(maxminflag) = NaN;
    record(maxminflag) = NaN;
    end
    
    % display what is pulled for maxs and mins
    disp(sprintf('    above max or below min = %d',removed_maxs_mins));
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
% Iteration 4 - Now examine the effect of high and low co2 filters by
% running program with iteration 4
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
    
if iteration > 3
    
    % Remove high CO2 concentration points
    highco2flag = find(CO2_mean > 450);

    % exceptions
    % keep index 5084 to 5764 in 2010 - these CO2 obs are bogus but the
    % fluxes look OK.  TWH 27 Mar 2012
    co2_conc_filter_exceptions = repmat( false, size( CO2_mean ) );
    if ( sitecode == 1 ) & ( year(1) == 2010 )
        co2_conc_filter_exceptions( 5084:5764 ) = true;
    end

    removed_highco2 = length(highco2flag);
    decimal_day_nan(highco2flag) = NaN;
    record(highco2flag) = NaN;
    conc_record(highco2flag) = NaN;

    % Remove low CO2 concentration points
    if sitecode == 9
        lowco2flag = find(CO2_mean <250);
    elseif sitecode == 8 && year(1) ==2008
        lowco2flag = find(CO2_mean <250);
    else
        lowco2flag = find(CO2_mean <350);
    end

    % exceptions 
    % keep index 4128 to 5084, 7296-8064 (days 152:168) in 2010 -
    % these CO2 obs are bogus but the datalogger 30-min fluxes look OK.  TWH 27
    % Mar 2012
    if ( sitecode == 1 ) & ( year(1) == 2010 )
        co2_conc_filter_exceptions( 4128:5084 ) = true;
        co2_conc_filter_exceptions( 7296:8064 ) = true;
    end

    removed_lowco2 = length(lowco2flag);
    decimal_day_nan(lowco2flag) = NaN;
    record(lowco2flag) = NaN;
    conc_record(lowco2flag) = NaN;
    
    % display what's pulled for too high or too low co2
    disp(sprintf('    low co2 = %d',removed_lowco2));
    disp(sprintf('    high co2 = %d',removed_highco2));
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
% Iteration 5 - Now clear out the last of the outliers by running iteration
% 5, which removes values outside a running standard deviation window
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if iteration > 4
    %     figure;
    %     element = gcf;
    % Remove values outside of a running standard deviation
    n_bins = 24;
    std_bin = zeros( 1, n_bins );
    bin_length = round(length(fc_raw_massman_wpl)/ n_bins);
    n_SDs_filter = 3; % how many std devs away from the mean to allow

    % count up what's been filtered out already
    good_co2 = repmat( true, size( decimal_day ) );
    good_co2( highco2flag ) = false;
    good_co2( lowco2flag ) = false;
    good_co2( co2_conc_filter_exceptions ) = true;

    idx_NEE_good = repmat( true, size( decimal_day ) );
    idx_NEE_good( ustarflag ) = false;
    idx_NEE_good( precipflag ) = false;
    idx_NEE_good( nightnegflag ) = false;
    idx_NEE_good( windflag ) = false;
    idx_NEE_good( maxminflag ) = false;
    idx_NEE_good( nanflag ) = false;
    idx_NEE_good( ~good_co2 ) = false;
    %    idx_NEE_good( idx_std_removed ) = false;
    stdflag = repmat( false, size( idx_NEE_good ) );

    % figure();
    % idx_ax = axes();
    % plot( decimal_day, idx_std_removed, '.' );

    for i = 1:n_bins
        if i == 1
            startbin( i ) = 1;
        elseif i >= 2
            startbin( i ) = ((i-1) * bin_length);
        end    
        endbin( i ) = min( bin_length + startbin( i ), numel( idx_NEE_good) );

        % make logical indices for elements that are (1) in this bin and (2)
        % not already filtered for something else
        this_bin = repmat( false, size( idx_NEE_good ) );
        this_bin( startbin( i ):endbin( i ) ) = true;
        
        std_bin(i) = nanstd( fc_raw_massman_wpl( this_bin & idx_NEE_good ) );
        mean_flux(i) = nanmean( fc_raw_massman_wpl( this_bin & idx_NEE_good ) );
        bin_ceil = mean_flux( i ) + ( n_SDs_filter * std_bin( i ) );
        bin_floor = mean_flux( i ) - ( n_SDs_filter * std_bin( i ) );
        stdflag_thisbin_hi = ( this_bin & ...
                               fc_raw_massman_wpl > bin_ceil );
        stdflag_thisbin_low = ( this_bin & ...
                                fc_raw_massman_wpl < bin_floor );
        stdflag = stdflag | stdflag_thisbin_hi | stdflag_thisbin_low;

        % %plot each SD window and its mean and SD
        % figure()
        % h_all = plot( decimal_day( this_bin ),...
        %               fc_raw_massman_wpl( this_bin ), 'ok' );
        % hold on
        % if any( stdflag_thisbin_low | stdflag_thisbin_hi )
        %     h_out = plot( decimal_day( stdflag_thisbin_low | ...
        %                                stdflag_thisbin_hi ), ...
        %                   fc_raw_massman_wpl( stdflag_thisbin_low | ...
        %                                       stdflag_thisbin_hi ), ...
        %                   'r.' );
        %     refline( 0, bin_ceil );
        %     refline( 0, bin_floor );
        %     legend( [ h_all, h_out ], 'all NEE', 'filtered for SD' );
        % end
        % title( sprintf( 'SD filter, window %d/%d', i, n_bins ) );

        elementstouse_c = find(conc_record > startbin( i ) & conc_record <= endbin( i ) & isnan(conc_record) == 0);
        conc_std_bin(i) = std(CO2_mean(elementstouse_c));
        mean_conc(i) = mean(CO2_mean(elementstouse_c));
        if sitecode == 7
        conc_bin_index = find(CO2_mean(elementstouse_c) < (mean_conc(i)-(2.*conc_std_bin(i)))...
            | CO2_mean(elementstouse_c) > (mean_conc(i)+(2.*conc_std_bin(i))) & wnd_spd(elementstouse_c) > 0.3);  %u_star(elementstouse_c) > ustar_lim);
        else
         conc_bin_index = find(CO2_mean(elementstouse_c) < (mean_conc(i)-(2.*conc_std_bin(i)))...
            | CO2_mean(elementstouse_c) > (mean_conc(i)+(2.*conc_std_bin(i))) & wnd_spd(elementstouse_c) > 3);  %u_star(elementstouse_c) > ustar_lim);           
        end
        conc_outofstdnan = elementstouse_c(conc_bin_index);
        conc_record(conc_outofstdnan) = NaN;
        
        CO2_to_plot = CO2_mean(elementstouse_c);
        wnd_to_plot = wnd_spd(elementstouse_c);
        xxo=ones(length(elementstouse_c),1);
        xaxis=linspace(1,length(elementstouse_c),length(elementstouse_c));
%         
%         figure(element); 
%         plot(elementstouse_c,CO2_to_plot,'o'); hold on
%         plot(elementstouse_c,xxo.*mean_conc(i),'r'); hold on
%         plot(elementstouse_c,xxo.*(mean_conc(i)-(2.*conc_std_bin(i))),'g'); hold on
%         plot(elementstouse_c,xxo.*(mean_conc(i)+(2.*conc_std_bin(i))),'g'); hold on
%         plot(elementstouse_c(conc_bin_index),CO2_to_plot(conc_bin_index),'k*')
%         plot(elementstouse_c,wnd_to_plot+mean_conc(i),'c'); hold on
%         plot(elementstouse_c,1+mean_conc(i),'m'); hold on
%         plot(elementstouse_c,10+mean_conc(i),'m'); hold on
        
        xx((i*2)-1)=startbin( i );
        xx(i*2)=endbin( i );
        yy((i*2)-1)=mean_conc(i);
        yy(i*2)=mean_conc(i);
        yyl((i*2)-1)=(mean_conc(i)-(2.*conc_std_bin(i)));
        yyl(i*2)=(mean_conc(i)-(2.*conc_std_bin(i)));
        yyu((i*2)-1)=(mean_conc(i)+(2.*conc_std_bin(i)));
        yyu(i*2)=(mean_conc(i)+(2.*conc_std_bin(i)));
        
    end   
    idx_NEE_good( stdflag ) = false;
    decimal_day_nan(stdflag) = NaN;
    record(stdflag) = NaN;
    removed_outofstdnan = numel( find (stdflag ) );
    disp(sprintf('    above or below %dX running standard deviation = %d', ...
                 n_SDs_filter, removed_outofstdnan ));

    if xx( end ) > length( decimal_day )
        xx(end) = length(decimal_day);
    end
    h_co2_fig = figure();
    CO2_mean_clean=CO2_mean;
    CO2_mean_clean(find(isnan(conc_record)))=-9999;
    plot(decimal_day, CO2_mean,'.'); hold on;
    plot(decimal_day, CO2_mean_clean,'ro'); hold on;
    plot(decimal_day(xx), yy,'go-'); hold on;
    plot(decimal_day(xx), yyl,'c','linewidth',2); hold on;
    plot(decimal_day(xx), yyu,'c','linewidth',2); hold on;
    xx=linspace(1, length(CO2_mean), length(CO2_mean));
    ylim([300 450]);
    xlabel('day of year');
    ylabel('[CO_2], ppm');
end % close if statement for iterations

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Plot the co2 flux for the whole series
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

pal = brewer_palettes( 'Dark2' );

h_fig_flux = figure( 'Units', 'Normalized', ...
                     'Position', [ 0.1, 0.2, 0.85, 0.70 ] );
ax2 = subplot( 'Position', [ 0.1, 0.05, 0.89, 0.2 ] );
ax1 = subplot( 'Position', [ 0.1, 0.30, 0.89, 0.64 ] );
hold on; 
box on;
% --------
% plot NEE in the top panel
% plot all observations as black circles
axes( ax1 );
h_all = plot( decimal_day, fc_raw_massman_wpl, 'ok' );
% plot the "good" observations (that weren't filtered out) as red dots
% find [CO2] observations that are (1) good or (2) excepted

h_good = plot( decimal_day( idx_NEE_good  ), ...
               fc_raw_massman_wpl( idx_NEE_good ), ...
               'LineStyle', 'none', ...
               'Marker', '.', ...
               'Color', pal( 1, : ) );

%plot std dev windows
endbin( end ) = numel( decimal_day );
for i = 1:n_bins
    bin_x = [ decimal_day( startbin( i ) ), decimal_day( endbin( i ) ) ];
    bin_y = repmat( mean_flux( i ) + n_SDs_filter * std_bin( i ), 1, 2 );
    h_SD = plot( bin_x, bin_y, ...
                 'Color', pal( 2, : ), 'LineStyle', '-', 'LineWidth', 2 );
    bin_y = repmat( mean_flux( i ) - n_SDs_filter * std_bin( i ), 1, 2 );
    h_SD = plot( bin_x, bin_y, ...
                 'Color', pal( 2, : ), 'LineStyle', '-', 'LineWidth', 2 );
    bin_y = [ mean_flux( i ), mean_flux( i ) ];
    h_mean = plot( bin_x, bin_y, ...
                   'Color', pal( 2, : ), 'LineStyle', '--', 'LineWidth', 2 );
           
end

legend( [ h_all, h_good, h_SD ], 'all obs', '"good" obs', ...
        sprintf( '%d x sigma', n_SDs_filter ) );
xlabel('decimal day'); 
ylabel('CO_2 flux');
title( sprintf( '%s %d', get_site_name( sitecode ), year( 2 ) ) );
ylim( [ -15, 15 ] );
hold off; 

% -------
% plot reasons NEE was screened in the bottom panel
axes( ax2 );
hold on
h_ustar = plot( decimal_day( ustarflag ), ...
                repmat( 1, numel( ustarflag), 1 ), '.k' );
h_pcp = plot( decimal_day( precipflag ), ...
                repmat( 2, numel( precipflag), 1 ), '.k' );
h_nightneg = plot( decimal_day( nightnegflag ), ...
                repmat( 3, numel( nightnegflag), 1 ), '.k' );
h_wind = plot( decimal_day( windflag ), ...
                repmat( 4, numel( windflag), 1 ), '.k' );
h_maxs_mins = plot( decimal_day( maxminflag ), ...
                repmat( 5, numel( maxminflag), 1 ), '.k' );
h_lowco2 = plot( decimal_day( lowco2flag ), ...
                repmat( 6, numel( lowco2flag), 1 ), '.k' );
h_highco2 = plot( decimal_day( highco2flag ), ...
                repmat( 7, numel( highco2flag), 1 ), '.k' );
h_nan = plot( decimal_day( nanflag ), ...
                repmat( 8, numel( nanflag), 1 ), '.k' );
h_std = plot( decimal_day( stdflag ), ...
              repmat( 9, numel( find( stdflag ) ), 1 ), '.k' );
set( ax2, 'YLim', [0, 10 ], ...
          'YTick', 1:9, ...
          'YTickLabel', ...
          { 'ustar', 'precip', 'night neg', 'wind', ...
            'max min', 'low co2', 'high co2', 'NaN', 'std dev' } );
ylabel( 'reason screened' );
xlabel( 'decimal day' );

linkaxes( [ ax1, ax2 ], 'x' );  %make axes zoom together horizontally

shg;  %bring current window to front
save;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Filter for sensible heat
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% max and mins for HSdry
HS_flag = find(HSdry > HS_max | HSdry < HS_min);
HSdry(HS_flag) = NaN;
% remove HS data when raining, use existing precipflag variable
HSdry(precipflag) = NaN;
% remove HS data with low ustar, use existing ustarflag variable
if iteration > 1
    HSdry(ustarflag) = NaN;
    removed_HS = length(find(isnan(HSdry)));
end

% max and mins for HSdry_massman
HSmass_flag = find(HSdry_massman > HSmass_max | HSdry_massman < HSmass_min);
HSdry_massman(HSmass_flag) = NaN;
% remove HS data when raining, use existing precipflag variable
HSdry_massman(precipflag) = NaN;
% remove HS data with low ustar, use existing ustarflag variable
HSdry_massman(ustarflag) = NaN;
removed_HSmass = length(find(isnan(HSdry_massman)));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Filter for max's and min's for other variables
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% QC for HL_raw
LH_flag = find(HL_raw > LH_max | HL_raw < LH_min);
removed_LH = length(LH_flag);
HL_raw(LH_flag) = NaN;

% QC for HL_wpl_massman
LH_min = -20;  %as per Jim Heilman, 28 Mar 2012
LH_maxmin_flag = ( HL_wpl_massman > LH_max ) | ( HL_wpl_massman < LH_min );
LH_night_flag = ( Par_Avg < 20.0 ) & ( abs( HL_wpl_massman ) > 20.0 );
LH_day_flag = ( Par_Avg >= 20.0 ) & ( HL_wpl_massman < 0.0 );
removed_LH_wpl_mass = numel( find( LH_maxmin_flag | ...
                                   LH_night_flag | ...
                                   LH_day_flag ) );
HL_wpl_massman( LH_maxmin_flag | LH_night_flag | LH_day_flag ) = NaN;

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

% QC for atmospheric pressure
press_flag = []; %find(atm_press > press_max | atm_press < press_min);
removed_press = length(press_flag);
atm_press(press_flag) = NaN;

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
disp(sprintf('    number of atm press values removed = %d',removed_press));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%WRITE FILE FOR ONLINE GAP-FILLING PROGRAM (REICHSTEIN)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

dd_idx = isnan(decimal_day_nan);
qc = ones(datalength,1);
%qc(dd_idx) = 2;
qc( not( idx_NEE_good ) ) = 2;
NEE = fc_raw_massman_wpl; 
NEE( not( idx_NEE_good ) ) = -9999;
LE = HL_wpl_massman; LE(dd_idx) = -9999;

H_dry = HSdry_massman; H_dry(dd_idx) = -9999;
Tair = Tdry - 273.15;

if sitecode == 1 & year == 2010
    Tair( 12993:end ) = Tair_TOA5(  12993:end );
end

if write_gap_filling_out_file == 1;
    if (sitecode>7 && sitecode<10) % || 9);
        disp('writing gap-filling file...')
        header = {'day' 'month' 'year' 'hour' 'minute' ...
                  'qcNEE' 'NEE' 'LE' 'H' 'Rg' 'Tair' 'Tsoil' ...
                  'rH' 'precip' 'Ustar'};
        %sw_incoming=ones(size(qc)).*-999;
        Tsoil=ones(size(qc)).*-999;
        datamatrix = [day month year hour minute qc NEE LE H_dry sw_incoming Tair Tsoil rH precip u_star];
        for n = 1:datalength
            for k = 1:15;
                if isnan(datamatrix(n,k)) == 1;
                    datamatrix(n,k) = -9999;
                else
                end
            end
        end
        outfilename = strcat(outfolder,filename,'_for_gap_filling');
        xlswrite(outfilename, header, 'data', 'A1');
        xlswrite(outfilename, datamatrix, 'data', 'A2');
    else    
        disp('writing gap-filling file...')
        header = {'day' 'month' 'year' 'hour' 'minute' ...
                  'qcNEE' 'NEE' 'LE' 'H' 'Rg' 'Tair' 'Tsoil' ...
                  'rH' 'precip' 'Ustar'};
        if sitecode == 3
            Tsoil = ones(size(qc)).*-999;
        end
        datamatrix = [day month year hour minute qc NEE ...
                      LE H_dry sw_incoming Tair Tsoil rH precip u_star];
        for n = 1:datalength
            for k = 1:15;
                if isnan(datamatrix(n,k)) == 1;
                    datamatrix(n,k) = -9999;
                else
                end
            end
        end
        outfilename = strcat(outfolder,filename,'_for_gap_filling');
        xlswrite(outfilename, header, 'data', 'A1');
        xlswrite(outfilename, datamatrix, 'data', 'A2');

        outfilename = strcat( outfilename, '.txt' );
        fid = fopen( outfilename , 'w' );
        fmt = repmat('%s\t', 1, numel( header ) - 1 );
        fmt = [ fmt, '%s\n' ];
        fprintf( fid, fmt, header{ : } );
        fclose( fid );
        dlmwrite( outfilename, datamatrix, '-append', 'delimiter', '\t' );
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%WRITE COMPLETE OUT-FILE  (FLUX_all matrix with bad values removed)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% clean the co2 flux variables
fc_raw(find(isnan(decimal_day_nan))) = NaN;
fc_raw_massman(find(isnan(decimal_day_nan))) = NaN;
fc_water_term(find(isnan(decimal_day_nan))) = NaN;
fc_heat_term_massman(find(isnan(decimal_day_nan))) = NaN;
fc_raw_massman_wpl(find(isnan(decimal_day_nan))) = NaN;

% clean the h2o flux variables
E_raw(find(isnan(decimal_day_nan))) = NaN;
E_raw_massman(find(isnan(decimal_day_nan))) = NaN;
E_water_term(find(isnan(decimal_day_nan))) = NaN;
E_heat_term_massman(find(isnan(decimal_day_nan))) = NaN;
E_wpl_massman(find(isnan(decimal_day_nan))) = NaN;

% clean the co2 concentration
CO2_mean(find(isnan(decimal_day_nan))) = NaN;

if write_complete_out_file == 1;
    disp('writing qc file...')
    
    if sitecode == 5 || sitecode == 6 
%         header2 = {'timestamp','year','month','day','hour','minute','second','jday','iok','agc_Avg',...
%             'wnd_dir_compass','wnd_spd','CO2_mean','CO2_std','H2O_mean','H2O_std',...
%             'fc_raw','fc_raw_massman','fc_water_term','fc_heat_term_massman','fc_raw_massman_wpl',...
%             'E_raw','E_raw_massman','E_water_term','E_heat_term_massman','E_wpl_massman',...
%             'HSdry','HSdry_massman','HL_raw','HL_wpl_massman',...
%             'Tdry','air_temp_hmp','Tsoil_2cm','Tsoil_6cm','precip','atm_press','rH'...
%             'Par_Avg','sw_incoming','sw_outgoing','lw_incoming','lw_outgoing','NR_sw','NR_lw','NR_tot'};
%         datamatrix2 = [year,month,day,hour,minute,second,jday,iok,agc_Avg,...
%             wnd_dir_compass,wnd_spd,CO2_mean,CO2_std,H2O_mean,H2O_std,...        
%             fc_raw,fc_raw_massman,fc_water_term,fc_heat_term_massman,fc_raw_massman_wpl,...
%             E_raw,E_raw_massman,E_water_term,E_heat_term_massman,E_wpl_massman,...
%             HSdry,HSdry_massman,HL_raw,HL_wpl_massman,...
%             Tdry,air_temp_hmp,Tsoil_2cm,Tsoil_6cm,precip,atm_press,rH...
%             Par_Avg,sw_incoming,sw_outgoing,lw_incoming,lw_outgoing,NR_sw,NR_lw,NR_tot];
        header2 = {'timestamp', ...
                   'year', ...
                   'month', ...
                   'day', ...
                   'hour', ...
                   'minute', ...
                   'second', ...
                   'jday', ...
                   'iok', ...
                   'agc_Avg', ...
                   'u_star',...
                   'wnd_dir_compass', ...
                   'wnd_spd', ...
                   'CO2_mean', ...
                   'CO2_std', ...
                   'H2O_mean', ...
                   'H2O_std',...
                   'fc_raw', ...
                   'fc_raw_massman', ...
                   'fc_water_term', ...
                   'fc_heat_term_massman', ...
                   'fc_raw_massman_wpl',...
                   'E_raw', ...
                   'E_raw_massman', ...
                   'E_water_term', ...
                   'E_heat_term_massman', ...
                   'E_wpl_massman',...
                   'HSdry', ...
                   'HSdry_massman', ...
                   'HL_raw', ...
                   'HL_wpl_massman',...
                   'Tdry', ...
                   'air_temp_hmp', ...
                   'Tsoil_2cm', ...
                   'Tsoil_6cm', ...
                   'VWC_2cm', ...
                   'precip', ...
                   'atm_press', ...
                   'rH'...
                   'Par_Avg', ...
                   'sw_incoming', ...
                   'sw_outgoing', ...
                   'lw_incoming', ...
                   'lw_outgoing', ...
                   'NR_sw', ...
                   'NR_lw', ...
                   'NR_tot'};
        datamatrix2 = [year, ...
                       month, ...
                       day, ...
                       hour, ...
                       minute, ...
                       second, ...
                       jday, ...
                       iok, ...
                       agc_Avg, ...
                       u_star,...
                       wnd_dir_compass, ...
                       wnd_spd, ...
                       CO2_mean, ...
                       CO2_std, ...
                       H2O_mean, ...
                       H2O_std,...        
                       fc_raw, ...
                       fc_raw_massman, ...
                       fc_water_term, ...
                       fc_heat_term_massman, ...
                       fc_raw_massman_wpl,...
                       E_raw, ...
                       E_raw_massman, ...
                       E_water_term, ...
                       E_heat_term_massman, ...
                       E_wpl_massman,...
                       HSdry, ...
                       HSdry_massman, ...
                       HL_raw, ...
                       HL_wpl_massman,...
                       Tdry, ...
                       air_temp_hmp, ...
                       Tsoil_2cm, ...
                       Tsoil_6cm, ...
                       VWC, ...
                       precip ...
                       atm_press, ...
                       rH...
                       Par_Avg, ...
                       sw_incoming, ...
                       sw_outgoing, ...
                       lw_incoming, ...
                       lw_outgoing, ...
                       NR_sw, ...
                       NR_lw, ...
                       NR_tot];
           
    elseif sitecode == 7
        header2 = {'timestamp', ...
                   'year', ...
                   'month', ...
                   'day', ...
                   'hour', ...
                   'minute', ...
                   'second', ...
                   'jday', ...
                   'iok', ...
                   'agc_Avg', ...
                   'u_star',...
                   'wnd_dir_compass', ...
                   'wnd_spd', ...
                   'CO2_mean', ...
                   'CO2_std', ...
                   'H2O_mean', ...
                   'H2O_std',...
                   'fc_raw', ...
                   'fc_raw_massman', ...
                   'fc_water_term', ...
                   'fc_heat_term_massman', ...
                   'fc_raw_massman_wpl',...
                   'E_raw', ...
                   'E_raw_massman', ...
                   'E_water_term', ...
                   'E_heat_term_massman', ...
                   'E_wpl_massman',...
                   'HSdry', ...
                   'HSdry_massman', ...
                   'HL_raw', ...
                   'HL_wpl_massman',...
                   'Tdry', ...
                   'air_temp_hmp', ...
                   'Tsoil', ...
                   'canopy_5cm', ...
                   'canopy_10cm', ...
                   'open_5cm', ...
                   'open_10cm',...
                   'soil_heat_flux_open', ...
                   'soil_heat_flux_mescan', ...
                   'soil_heat_flux_juncan', ...
                   'precip', ...
                   'atm_press', ...
                   'rH'...
                   'Par_Avg', ...
                   'sw_incoming', ...
                   'sw_outgoing', ...
                   'lw_incoming', ...
                   'lw_outgoing', ...
                   'NR_sw', ...
                   'NR_lw', ...
                   'NR_tot'};
        datamatrix2 = [year, ...
                       month, ...
                       day, ...
                       hour, ...
                       minute, ...
                       second, ...
                       jday, ...
                       iok, ...
                       agc_Avg, ...
                       u_star,...
                       wnd_dir_compass, ...
                       wnd_spd, ...
                       CO2_mean, ...
                       CO2_std, ...
                       H2O_mean, ...
                       H2O_std,...        
                       fc_raw, ...
                       fc_raw_massman, ...
                       fc_water_term, ...
                       fc_heat_term_massman, ...
                       fc_raw_massman_wpl,...
                       E_raw, ...
                       E_raw_massman, ...
                       E_water_term, ...
                       E_heat_term_massman, ...
                       E_wpl_massman,...
                       HSdry, ...
                       HSdry_massman, ...
                       HL_raw, ...
                       HL_wpl_massman,...
                       Tdry, ...
                       air_temp_hmp, ...
                       Tsoil, ...
                       canopy_5cm, ...
                       canopy_10cm, ...
                       open_5cm, ...
                       open_10cm,...
                       soil_heat_flux_open, ...
                       soil_heat_flux_mescan, ...
                       soil_heat_flux_juncan, ...
                       precip, ...
                       atm_press, ...
                       rH...
                       Par_Avg, ...
                       sw_incoming, ...
                       sw_outgoing, ...
                       lw_incoming, ...
                       lw_outgoing, ...
                       NR_sw, ...
                       NR_lw, ...
                       NR_tot];
        
%     elseif sitecode == 8
%         header2 = {'timestamp','year','month','day','hour','minute','second','jday','iok','u_star',...
%             'wnd_dir_compass','wnd_spd','CO2_mean','CO2_std','H2O_mean','H2O_std',...
%             'fc_raw','fc_raw_massman','fc_water_term','fc_heat_term_massman','fc_raw_massman_wpl',...
%             'E_raw','E_raw_massman','E_water_term','E_heat_term_massman','E_wpl_massman',...
%             'HSdry','HSdry_massman','HL_raw','HL_wpl_massman',...
%             'Tdry','air_temp_hmp','precip','atm_press','rH'};    
%         datamatrix2 = [year,month,day,hour,minute,second,jday,iok,u_star,...
%             wnd_dir_compass,wnd_spd,CO2_mean,CO2_std,H2O_mean,H2O_std,...        
%             fc_raw,fc_raw_massman,fc_water_term,fc_heat_term_massman,fc_raw_massman_wpl,...
%             E_raw,E_raw_massman,E_water_term,E_heat_term_massman,E_wpl_massman,...
%             HSdry,HSdry_massman,HL_raw,HL_wpl_massman,...
%             Tdry,air_temp_hmp,precip,atm_press,rH];
        
     elseif sitecode == 8 || sitecode == 9
        header2 = {'timestamp', ...
                   'year', ...
                   'month', ...
                   'day', ...
                   'hour', ...
                   'minute', ...
                   'second', ...
                   'jday', ...
                   'iok', ...
                   'u_star',...
                   'wnd_dir_compass', ...
                   'wnd_spd', ...
                   'CO2_mean', ...
                   'CO2_std', ...
                   'H2O_mean', ...
                   'H2O_std',...
                   'fc_raw', ...
                   'fc_raw_massman', ...
                   'fc_water_term', ...
                   'fc_heat_term_massman', ...
                   'fc_raw_massman_wpl',...
                   'E_raw', ...
                   'E_raw_massman', ...
                   'E_water_term', ...
                   'E_heat_term_massman', ...
                   'E_wpl_massman',...
                   'HSdry', ...
                   'HSdry_massman', ...
                   'HL_raw', ...
                   'HL_wpl_massman',...
                   'Tdry', ...
                   'air_temp_hmp', ...
                   'precip', ...
                   'atm_press', ...
                   'rH'};
        %atm_press=ones(size(precip)).*-999;
        %air_temp_hmp=ones(size(precip)).*-999;
        datamatrix2 = [year, ...
                       month, ...
                       day, ...
                       hour, ...
                       minute, ...
                       second, ...
                       jday, ...
                       iok, ...
                       u_star,...
                       wnd_dir_compass, ...
                       wnd_spd, ...
                       CO2_mean, ...
                       CO2_std, ...
                       H2O_mean, ...
                       H2O_std,...        
                       fc_raw, ...
                       fc_raw_massman, ...
                       fc_water_term, ...
                       fc_heat_term_massman, ...
                       fc_raw_massman_wpl,...
                       E_raw, ...
                       E_raw_massman, ...
                       E_water_term, ...
                       E_heat_term_massman, ...
                       E_wpl_massman,...
                       HSdry, ...
                       HSdry_massman, ...
                       HL_raw, ...
                       HL_wpl_massman,...
                       Tdry, ...
                       air_temp_hmp, ...
                       precip, ...
                       atm_press, ...
                       rH];
    
    else
        header2 = {'timestamp', ...
                   'year', ...
                   'month', ...
                   'day', ...
                   'hour', ...
                   'minute', ...
                   'second', ...
                   'jday', ...
                   'iok', ...
                   'agc_Avg', ...
                   'u_star',...
                   'wnd_dir_compass', ...
                   'wnd_spd', ...
                   'CO2_mean', ...
                   'CO2_std', ...
                   'H2O_mean', ...
                   'H2O_std',...
                   'fc_raw', ...
                   'fc_raw_massman', ...
                   'fc_water_term', ...
                   'fc_heat_term_massman', ...
                   'fc_raw_massman_wpl',...
                   'E_raw', ...
                   'E_raw_massman', ...
                   'E_water_term', ...
                   'E_heat_term_massman', ...
                   'E_wpl_massman',...
                   'HSdry', ...
                   'HSdry_massman', ...
                   'HL_raw', ...
                   'HL_wpl_massman',...
                   'Tdry', ...
                   'air_temp_hmp', ...
                   'Tsoil', ...
                   'soil_heat_flux_1', ...
                   'soil_heat_flux_2', ...
                   'precip', ...
                   'atm_press', ...
                   'rH'...
                   'Par_Avg', ...
                   'sw_incoming', ...
                   'sw_outgoing', ...
                   'lw_incoming', ...
                   'lw_outgoing', ...
                   'NR_sw', ...
                   'NR_lw', ...
                   'NR_tot'};
        datamatrix2 = [year, ...
                       month, ...
                       day, ...
                       hour, ...
                       minute, ...
                       second, ...
                       jday, ...
                       iok, ...
                       agc_Avg, ...
                       u_star, ...
                       wnd_dir_compass, ...
                       wnd_spd,CO2_mean, ...
                       CO2_std,H2O_mean,H2O_std, ...
                       fc_raw, ...
                       fc_raw_massman, ...
                       fc_water_term, ...
                       fc_heat_term_massman, ...
                       fc_raw_massman_wpl, ...
                       E_raw,E_raw_massman,E_water_term, ...
                       E_heat_term_massman,E_wpl_massman, ...
                       HSdry,HSdry_massman,HL_raw,HL_wpl_massman, ...
                       Tdry, ...
                       air_temp_hmp,Tsoil, ...
                       soil_heat_flux_1, ...
                       soil_heat_flux_2, ...
                       precip, ...
                       atm_press, ...
                       rH Par_Avg, ...
                       sw_incoming, ...
                       sw_outgoing, ...
                       lw_incoming, ...
                       lw_outgoing,NR_sw,NR_lw,NR_tot];
    end

    outfilename = strcat(outfolder,filename,'_qc');
    xlswrite(outfilename,header2,'data','A1');
    xlswrite(outfilename,datamatrix2,'data','B2');
    xlswrite(outfilename,timestamp,'data','A2');
   
    if iteration > 4
        
        if sitecode == 8 || sitecode == 9
            numbers_removed = [removednans removed_precip ...
                               removed_wind removed_nightneg ...
                               removed_ustar removed_maxs_mins ...
                               removed_lowco2 removed_highco2 ...
                               removed_outofstdnan NaN ...
                               (filelength_n-sum(~isnan(record))) ...
                               sum(~isnan(record)) removed_LH ...
                               removed_LH_wpl_mass removed_HS ...
                               removed_HSmass removed_Tdry ...
                               removed_rH removed_h2o];
            removals_header = {'Original nans', ...
                               'Precip periods', ...
                               'Bad wind direction', ...
                               'Night-time negs', ...
                               'Low ustar', ...
                               'Over max or min', ...
                               'Low co2', ...
                               'High co2', ...
                               'Outside running std', ...
                               '', ...
                               'Total co2 pulled', ...
                               'Total retained', ...
                               'LH values removed', ...
                               'LH with WPL/Massman removed', ...
                               'HS removed', ...
                               'HS with massman removed', ...
                               'Temp removed', ...
                               'Rel humidity removed', ...
                               'Water removed'};
            xlswrite(outfilename,numbers_removed','numbers removed','B1');
            xlswrite (outfilename, removals_header', 'numbers removed', 'A1');
        else
            numbers_removed = [removednans removed_precip ...
                               removed_wind removed_nightneg ...
                               removed_ustar removed_maxs_mins ...
                               removed_lowco2 removed_highco2 ...
                               removed_outofstdnan NaN ...
                               (filelength_n-sum(~isnan(record))) ...
                               sum(~isnan(record)) removed_LH ...
                               removed_LH_wpl_mass removed_HS ...
                               removed_HSmass removed_Tdry ...
                               removed_rH removed_h2o removed_press];
            removals_header = {'Original nans', ...
                               'Precip periods', ...
                               'Bad wind direction', ...
                               'Night-time negs', ...
                               'Low ustar',...
                               'Over max or min', ...
                               'Low co2', ...
                               'High co2', ...
                               'Outside running std', ...
                               '',...
                               'Total co2 pulled', ...
                               'Total retained',...
                               'LH values removed', ...
                               'LH with WPL/Massman removed', ...
                               'HS removed', ...
                               'HS with massman removed',...
                               'Temp removed', ...
                               'Rel humidity removed', ...
                               'Water removed', ...
                               'Pressure removed'};
            xlswrite(outfilename,numbers_removed','numbers removed','B1');
            xlswrite (outfilename, removals_header', 'numbers removed', 'A1');
        end
    end
    
    
    if iteration > 6
    
%         header2 = {'timestamp','year','month','day','hour','minute','second','jday','iok','agc_Avg',...
%             'wnd_dir_compass','wnd_spd','CO2_mean','CO2_std','H2O_mean','H2O_std',...
%             'fc_raw','fc_raw_massman','fc_water_term','fc_heat_term_massman','fc_raw_massman_wpl',...
%             'E_raw','E_raw_massman','E_water_term','E_heat_term_massman','E_wpl_massman',...
%             'HSdry','HSdry_massman','HL_raw','HL_wpl_massman',...
%             'Tdry','air_temp_hmp','Tsoil_2cm','Tsoil_6cm','precip','atm_press','rH'...
%             'Par_Avg','sw_incoming','sw_outgoing','lw_incoming','lw_outgoing','NR_sw','NR_lw','NR_tot'};
%         datamatrix2 =
%             [year,month,day,hour,minute,second,jday,iok,agc_Avg,...
%             wnd_dir_compass,wnd_spd,CO2_mean,CO2_std,H2O_mean,H2O_std,...
%             fc_raw,fc_raw_massman,fc_water_term,fc_heat_term_massman,fc_raw_massman_wpl,...
%             E_raw,E_raw_massman,E_water_term,E_heat_term_massman,E_wpl_massman,...
%             HSdry,HSdry_massman,HL_raw,HL_wpl_massman,...
%             Tdry,air_temp_hmp,Tsoil_2cm,Tsoil_6cm,precip,atm_press,rH...
%             Par_Avg,sw_incoming,sw_outgoing,lw_incoming,lw_outgoing,NR_sw,NR_lw,NR_tot];
  
time_out=fix(clock);
time_out=datestr(time_out);

sname={'Site name: Test'};
email={'Email: andyfox@unm.edu'};
timeo={'Created: ',time_out};
    outfilename = strcat(outfolder,filename,'_AF.xls');
    xlswrite(outfilename,sname,'data','A1');
    xlswrite(outfilename,email,'data','A2');
    xlswrite(outfilename,timeo,'data','A3');
    xlswrite(outfilename,header2,'data','A4');
    xlswrite(outfilename,header2,'data','A5');
    xlswrite(outfilename,header2,'data','A6');
    end
end

close( h_burba_fig, h_co2_fig );