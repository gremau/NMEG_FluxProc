% This program pulls hourly radiation data from lter data sets specified within
% the flux_all programs, breaks it out by half-hour periods, 
% and writes it back into the flux_all file master tab.  Just comment out or uncomment for
% the periods and sites you want to use.  Double check the row numbers and
% column letters.

% The thing you have to do to use this is figure out the rows to be filled
% and the rows you are going to pull from.  In the for-loop, the number to
% go to is the number of rows to be FILLED.

clear; clc;

%%%%%%%%%%%%%%%%%%%%% for mixed-conifer 2007 - whole year
%     radiation_hourly = xlsread('c:\Research - Flux Towers\Flux Tower Data by Site\MCon\MCon_FLUX_all_2007','lter met data','T2:T8761');
%     for i = 1:17520
%         sw_incoming(i) = radiation_hourly(round(i/2));
%     end
%     xlswrite('c:\Research - Flux Towers\Flux Tower Data by Site\MCon\MCon_FLUX_all_2007',sw_incoming','master','ES5:ES17524');


%%%%%%%%%%%%%%%%%%%%% for mixed-conifer 2008
% for rows 9494 to 10264
%     radiation_hourly = xlsread('c:\Research - Flux Towers\Flux Tower Data by Site\MCon\MCon_FLUX_all_2008','lter met data','T4748:T5132');
%     for i = 1:770 % this needs to be the number of original rows in the met data that you are going to use
%         sw_incoming(i) = radiation_hourly(round(i/2));
%     end
%     xlswrite('c:\Research - Flux Towers\Flux Tower Data by Site\MCon\MCon_FLUX_all_2008',sw_incoming','master','ES9495:ES10264');

% % for rows 15155 to 16301
%     radiation_hourly = xlsread('c:\Research - Flux Towers\Flux Tower Data by Site\MCon\MCon_FLUX_all_2008','lter met data','T7577:T8219');
%     for i = 1:1286 % this needs to be the number of original rows in the met data that you are going to use
%         sw_incoming(i) = radiation_hourly(round(i/2));
%     end
%     xlswrite('c:\Research - Flux Towers\Flux Tower Data by Site\MCon\MCon_FLUX_all_2008',sw_incoming','master','ES15155:ES16441');

% % for rows 5 to 3633
%     radiation_hourly = xlsread('c:\Research - Flux Towers\Flux Tower Data by Site\MCon\MCon_FLUX_all_2008','lter met data','T3:T1816');
%     for i = 1:3628 % this needs to be the number of original rows in the met data that you are going to use
%         sw_incoming(i) = radiation_hourly(round(i/2));
%     end
%     xlswrite('c:\Research - Flux Towers\Flux Tower Data by Site\MCon\MCon_FLUX_all_2008',sw_incoming','master','ES7:ES3633');
%     
    
% for gland 2007
%     rad_j_cm2 = xlsread('c:\Research - Flux Towers\Flux Tower Data by Site\GLand\GLand_FLUX_all_2007','Deep well met data','U2:U3737');
%     
%     % convert to W per m2
%     rad_W_m2 = rad_j_cm2.*10000./3600; % times 10000 cm2 per m2 and divided by 3600 s per hr
% 
%     for i = 1:7472
%         sw_incoming(i) = rad_W_m2(round(i/2));
%     end
% 
%     xlswrite('c:\Research - Flux Towers\Flux Tower Data by Site\GLand\GLand_FLUX_all_2007',sw_incoming','Master','EQ5:EQ7476');

% for ppine 2008    
%     radiation_hourly = xlsread('c:\Research - Flux Towers\Flux Tower Data by Site\PPine\PPine_FLUX_all_2008','lter met data','T4458:T4552');
%     for i = 1:190 % this needs to be twice the number of original rows in the met data that you are going to use
%         sw_incoming(i) = radiation_hourly(round(i/2));
%     end
%     xlswrite('c:\Research - Flux Towers\Flux Tower Data by Site\PPine\PPine_FLUX_all_2008',sw_incoming','master','ES8917:ES9106');

% for ppine 2007 radiation
%     radiation_hourly_1 = xlsread('c:\Research - Flux Towers\Flux Tower Data by Site\PPine\PPine_FLUX_all_2007','lter met data','T3717:T3747');
%     radiation_hourly_2 = xlsread('c:\Research - Flux Towers\Flux Tower Data by Site\PPine\PPine_FLUX_all_2007','lter met data','T3790:T4239');
%     for i = 1:62 % this needs to be twice the number of original rows in the met data that you are going to use
%         sw_incoming_1(i) = radiation_hourly_1(round(i/2));
%     end
%     for j = 1:898 % this needs to be twice the number of original rows in the met data that you are going to use
%         sw_incoming_2(j) = radiation_hourly_2(round(j/2));
%     end
%     xlswrite('c:\Research - Flux Towers\Flux Tower Data by Site\PPine\PPine_FLUX_all_2007',sw_incoming_1(2:59)','master','ET7426:ET7485');
%     xlswrite('c:\Research - Flux Towers\Flux Tower Data by Site\PPine\PPine_FLUX_all_2007',sw_incoming_2','master','ET7572:ET8469');

%%%%%%%%%%%%%%%%%%% for ppine 2007 temp
    temp_hourly_1 = xlsread('c:\Research - Flux Towers\Flux Tower Data by Site\PPine\PPine_FLUX_all_2007','lter met data','E3717:E3730');
    temp_hourly_2 = xlsread('c:\Research - Flux Towers\Flux Tower Data by Site\PPine\PPine_FLUX_all_2007','lter met data','E3790:E4239');
    for i = 1:28 % this needs to be twice the number of original rows in the met data that you are going to use
        temp_1(i) = temp_hourly_1(round(i/2));
    end
    for j = 1:900 % this needs to be twice the number of original rows in the met data that you are going to use
        temp_2(j) = temp_hourly_2(round(j/2));
    end
    xlswrite('c:\Research - Flux Towers\Flux Tower Data by Site\PPine\PPine_FLUX_all_2007',temp_1(2:27)','master','O7426:O7451');
    xlswrite('c:\Research - Flux Towers\Flux Tower Data by Site\PPine\PPine_FLUX_all_2007',temp_2(2:899)','master','O7572:O8469');

