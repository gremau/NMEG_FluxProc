% This program pulls hourly rain data from sevilleta met station 40 (Deep
% Well), breaks it out by half-hour periods, and writes it into the
% flux_all file.  This is specifically set up for grassland at this point
% b/c that site did not have a working rain gauge until late summer 2008

% Below, I modify the code to process sw_incoming data from the same source
% for grassland

clear; clc;

year = 2007

% if year == 2008
%     temp_1 = xlsread('c:\Research_Flux_Towers\Flux_Tower_Data_by_Site\GLand\GLand_FLUX_all_2008','Deep well met data','N2:N6133');
%     temp_10 = xlsread('c:\Research_Flux_Towers\Flux_Tower_Data_by_Site\GLand\GLand_FLUX_all_2008','Deep well met data','O2:O6133');
%     moist_10 = xlsread('c:\Research_Flux_Towers\Flux_Tower_Data_by_Site\GLand\GLand_FLUX_all_2008','Deep well met data','R2:R6133');
%     moist_30 = xlsread('c:\Research_Flux_Towers\Flux_Tower_Data_by_Site\GLand\GLand_FLUX_all_2008','Deep well met data','S2:S6133');
%     
%     half_hour_temp_1 = temp_1./2;
%     half_hour_temp_10 = temp_10./2;
%     half_hour_moist_10 = moist_10./2;
%     half_hour_moist_30 = moist_30./2;
% 
%     for i = 1:12264
%         new_temp_1(i) = half_hour_temp_1(round(i/2));
%         new_temp_10(i) = half_hour_temp_10(round(i/2));
%         new_moist_10(i) = half_hour_moist_10(round(i/2));
%         new_moist_30(i) = half_hour_moist_30(round(i/2));
%     end
% 
%     data_out = [new_temp_1' new_temp_10' new_moist_10' new_moist_30']
%     xlswrite('c:\Research_Flux_Towers\Flux_Tower_Data_by_Site\GLand\for_sara',data_out,'data','A2:D12265');
% end
% 
% if year == 2007
%     jday = xlsread('c:\Research_Flux_Towers\Flux_Tower_Data_by_Site\GLand\GLand_FLUX_all_2007','Deep well met data','C2:C8189');
%     temp_1 = xlsread('c:\Research_Flux_Towers\Flux_Tower_Data_by_Site\GLand\GLand_FLUX_all_2007','Deep well met data','O2:O8189');
%     temp_10 = xlsread('c:\Research_Flux_Towers\Flux_Tower_Data_by_Site\GLand\GLand_FLUX_all_2007','Deep well met data','P2:P8189');
%     moist_10 = xlsread('c:\Research_Flux_Towers\Flux_Tower_Data_by_Site\GLand\GLand_FLUX_all_2007','Deep well met data','S2:S8189');
%     moist_30 = xlsread('c:\Research_Flux_Towers\Flux_Tower_Data_by_Site\GLand\GLand_FLUX_all_2007','Deep well met data','T2:T8189');
%     
%     half_hour_temp_1 = temp_1./2;
%     half_hour_temp_10 = temp_10./2;
%     half_hour_moist_10 = moist_10./2;
%     half_hour_moist_30 = moist_30./2;
% 
%     for i = 1:16374
%         new_jday(i) = jday();
%         new_temp_1(i) = half_hour_temp_1(round(i/2));
%         new_temp_10(i) = half_hour_temp_10(round(i/2));
%         new_moist_10(i) = half_hour_moist_10(round(i/2));
%         new_moist_30(i) = half_hour_moist_30(round(i/2));
%     end
% 
%     data_out = [new_temp_1' new_temp_10' new_moist_10' new_moist_30'];
%     xlswrite('c:\Research_Flux_Towers\Flux_Tower_Data_by_Site\GLand\for_sara',data_out,'data','B2:E16375');
% end





