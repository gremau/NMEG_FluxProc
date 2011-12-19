% program to average 15-min flux files into 30-min files

clear all; clc;

% TX_forest

% data = xlsread('c:\Research - Flux Towers\Flux Tower Data by Site\TX_grassland\flux\GrasslandFluxAll115FilescombinedAndGapChecked2005.xls','combined115','G2:AX34496');
data = dlmread('c:\Research - Flux Towers\Flux Tower Data by Site\TX_forest\ForestFluxAll115FilescombinedAndGapChecked2005.txt');

filelength_n = size(data,1);

new_values = []; % open vector
num_bins = round(filelength_n/2); % calc no of bins
bins = 1:1:num_bins;
for i = 1:num_bins
    if i == 1
        startbin = 1;
    elseif i >= 2
        startbin = ( (i-1) * 2 + 1); % pick first row to average
    end    
    endbin = 1 + startbin; % identify second row to average
    a = data(startbin,:); % extract first row
    b = data(endbin,:); % extract second row
    rows_to_average = [a;b]; % make new matrix of two rows
    new_values(i,:) = mean(rows_to_average,1); % average and assign as new values
    %new_values(i,1) = b(1);
end

dlmwrite('c:\Research - Flux Towers\Flux Tower Data by Site\TX_forest\2005_half_hour.dat',new_values)


% xlswrite('c:\Research - Flux Towers\Flux Tower Data by Site\TX_grassland\TX_grassland_FLUX_all_2005.xls',new_values,'flux','A2:AW33567');