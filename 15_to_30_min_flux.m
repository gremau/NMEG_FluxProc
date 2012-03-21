% program to average 15-min flux files into 30-min files

clear all; clc;

% TX_forest

data = xlsread('c:\Research_Flux_Towers\Flux_Tower_Data_by_Site\TX_forest\TX_forest_2007_flux','TX_forest_2007_flux','A3:AW33568');
filelength_n = 33566;

new_value = [];
num_bins = round(filelength_n/2);
bins = 1:1:num_bins;
for i = 1:num_bins
    if i == 1
        startbin = 1;
    elseif i >= 2
        startbin = ( (i-1) * 2 + 1);
    end
    
    endbin = 1 + startbin;
    
    new_value(i) = sum(data(startbin:endbin));
    
end

xlswrite('c:\Research_Flux_Towers\Flux_Tower_Data_by_Site\TX_forest\TX_forest_2007_flux',new_value','master','A2:AW33567');