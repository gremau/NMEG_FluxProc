% This program pulls hourly rain data from , breaks it out by half-hour periods, 
% and writes it into the flux_all file.  Just comment out or uncomment for
% the periods and sites you want to use.  Double check the row numbers and
% column letters.

clear; clc;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% for grassland 2007
% hourly rain data from sevilleta met station 40 (Deep Well)
% 
%     rain_1 = xlsread('c:\Research_Flux_Towers\Flux_Tower_Data_by_Site\GLand\GLand_FLUX_all_2007','Deep well met data','R2:R5078');
%     rain_2 = xlsread('c:\Research_Flux_Towers\Flux_Tower_Data_by_Site\GLand\GLand_FLUX_all_2007','Deep well met data','R5079:R8190');
%     half_hour_rain_1 = rain_1./2;
%     half_hour_rain_2 = rain_2./2; 
%     for i = 1:10154
%         new_rain_1(i) = half_hour_rain_1(round(i/2));
%     end
%     for j = 1:6224
%         new_rain_2(j) = half_hour_rain_2(round(j/2));
%     end
%     xlswrite('c:\Research_Flux_Towers\Flux_Tower_Data_by_Site\GLand\GLand_FLUX_all_2007',new_rain_1','master','FF5:FF10158');
%     xlswrite('c:\Research_Flux_Towers\Flux_Tower_Data_by_Site\GLand\GLand_FLUX_all_2007',new_rain_2','master','FF11301:FF17524');
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% for grassland 2008
%     
%     rain = xlsread('c:\Research_Flux_Towers\Flux_Tower_Data_by_Site\GLand\GLand_FLUX_all_2008','Deep well met data','Q2:Q6133');
%     half_hour_rain = rain./2;% 
%     for i = 1:12264
%         new_rain(i) = half_hour_rain(round(i/2));
%     end
%     xlswrite('c:\Research_Flux_Towers\Flux_Tower_Data_by_Site\GLand\GLand_FLUX_all_2008',new_rain','master','FF5:FF12268');
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% for Mixed-con 2007
% hourly rain data from overal lter station 14 redondo
    %rain = xlsread('c:\Research_Flux_Towers\Flux_Tower_Data_by_Site\MCon\Mcon 2010 Aug-Oct LTER,'S11:S8761');
%    rain = xlsread('c:\Research_Flux_Towers\Flux_Tower_Data_by_Site\MCon\Mcon 2010 Aug-Oct LTER','S11:S1530');
%    half_hour_rain = rain./2;
    %for i = 1:17520
%        new_rain(i) = half_hour_rain(round(i/2));
%    end
%    xlswrite('c:\Research_Flux_Towers\Flux_Tower_Data_by_Site\MCon\MCon_FLUX_all_2007',new_rain','master','GC5:GC17524');
    
% for Mixed-con 2008
% hourly rain data from overall lter station 14 redondo
%     rain = xlsread('c:\Research_Flux_Towers\Flux_Tower_Data_by_Site\MCon\MCon_FLUX_all_2008','lter met data','S3:S8219');
%     half_hour_rain = rain./2;
%     for i = 1:16434 % this needs to be twice the number of original rows in the met data that you are going to use
%         new_rain(i) = half_hour_rain(round(i/2));
%     end
%     xlswrite('c:\Research_Flux_Towers\Flux_Tower_Data_by_Site\MCon\MCon_FLUX_all_2008',new_rain','master','GB7:GB16441');
% 

% for Mixed-con 2010
% hourly rain data from overal lter station 14 redondo
%     rain = xlsread('c:\Research_Flux_Towers\Flux_Tower_Data_by_Site\MCon\Mcon 2010 Aug-Oct LTER','S11:S1530');
%     half_hour_rain = rain./2;
%     for i = 1:3040
%         new_rain(i) = half_hour_rain(round(i/2));
%     end
%     xlswrite('c:\Research_Flux_Towers\Flux_Tower_Data_by_Site\MCon\MCon_FLUX_all_2010',new_rain','lter_rain','A1');
    
% for Ponderosa pine 2007
% hourly rain data from overal lter station 11 valle toledo
%     rain = xlsread('c:\Research_Flux_Towers\Flux_Tower_Data_by_Site\PPine\PPine_FLUX_all_2007','lter met data','S2:S8761');
%     half_hour_rain = rain./2;
%     for i = 1:17520
%         new_rain(i) = half_hour_rain(round(i/2));
%     end
%     xlswrite('c:\Research_Flux_Towers\Flux_Tower_Data_by_Site\PPine\PPine_FLUX_all_2007',new_rain','master','FU5:FU17524');
%     
% for Ponderosa pine 2008
% hourly rain data from overal lter station 11 valle toledo
%     rain = xlsread('c:\Research_Flux_Towers\Flux_Tower_Data_by_Site\PPine\PPine_FLUX_all_2008','lter met data','S2:S8077');
%     half_hour_rain = rain./2;
%     for i = 1:16152 % this needs to be twice the number of original rows in the met data that you are going to use
%         new_rain(i) = half_hour_rain(round(i/2));
%     end
%     xlswrite('c:\Research_Flux_Towers\Flux_Tower_Data_by_Site\PPine\PPine_FLUX_all_2008',new_rain','master','FU5:FU16156');
%     
% for Ponderosa pine 2010
% hourly rain data from overal lter station 14 redondo
    rain = xlsread('c:\Research_Flux_Towers\Flux_Tower_Data_by_Site\PPine\Ppine LTER met data Aug patch 2010','S14:S329');
    half_hour_rain = rain./2;
    for i = 1:632
        new_rain(i) = half_hour_rain(round(i/2));
    end
    xlswrite('c:\Research_Flux_Towers\Flux_Tower_Data_by_Site\PPine\PPine_FLUX_all_2010',new_rain','lter_rain','A1');  


    

