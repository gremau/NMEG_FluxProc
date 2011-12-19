%This program cycles through the site codes, calls fluxreader to open up
%each file in turn, assigns variables to the datamatrix, and then produces
%plots

%function [] = fluxflag(days,s)

days=2; s = 2;

clc; clf;

[datamatrix] = fluxreader(s);
size(datamatrix);

%--------------------------------------------------------------------------
%set up variables

timestamp = datamatrix(:,1); %assigning handles to appropriate columns
record_number = datamatrix(:,2);
record = record_number{:}; %converting cell array to vector

if s == 1 || s ==2 %GLand
    %sonic related variables
    ux_avg = datamatrix(:,6); %plotted
    uy_avg = datamatrix(:,7); %plotted
    uz_avg = datamatrix(:,8); %plotted
    ts_mean = datamatrix(:,3); %plotted
    csat_warning = datamatrix(:,15); %flagged to output screen
    %irga related variables
    co2_mean = datamatrix(:,4); %plotted
    h2o_avg = datamatrix(:,5); %plotted
    co2_um_m = datamatrix(:,9); %plotted
    h2o_mm_m = datamatrix(:,10); %plotted
    press_mean = datamatrix(:,11); %plotted
    agc_avg = datamatrix(:,16); %plotted
    %system diagnostics
    panel_temp = datamatrix(:,12); %plotted
    batt_volt = datamatrix(:,13); %range printed to output screen
    n_samples = datamatrix(:,14); %range printed to output screen 
    low12volt = datamatrix(:,17); %%%% DON'T KNOW WHAT THIS LOOKS LIKE
    watchdog = datamatrix(:,18); %range printed to output screen
    %radiation variables
    rad_short_up = datamatrix(:,19); %plotted
    rad_short_down = datamatrix(:,20); %plotted
    rad_long_up = datamatrix(:,21); %plotted
    rad_long_down = datamatrix(:,22); %plotted
    %other variables
    cnr1tc = datamatrix(:,23); %plotted
    par_avg = datamatrix(:,24); %plotted
    t_hmp = datamatrix(:,25); %plotted
    rh_hmp = datamatrix(:,26); %plotted
    rain_tot = datamatrix(:,27); %plotted
    shf1 = datamatrix(:,28); %plotted
    shf2 = datamatrix(:,29);
    tsoil_avg = datamatrix(:,30); %plotted
    soilwater1 = datamatrix(:,31); %plotted
    soilwater2 = datamatrix(:,32); %plotted
    soilwater3 = datamatrix(:,33); %plotted
    soilwater4 = datamatrix(:,34); %plotted
    soilwater5 = datamatrix(:,35); %plotted
    soilwater6 = datamatrix(:,36); %plotted
    soilwater7 = datamatrix(:,37); %plotted
    soilwater8 = datamatrix(:,38); %plotted
    soilwater9 = datamatrix(:,39); %plotted
    soilwater10 = datamatrix(:,40); %plotted
    soilwater11 = datamatrix(:,41); %plotted
    soilwater12 = datamatrix(:,42); %plotted
    soilwater13 = datamatrix(:,43); %plotted
    soilwater14 = datamatrix(:,44); %plotted
    soilwater15 = datamatrix(:,45); %plotted
    soilwater16 = datamatrix(:,46); %plotted
    soilwater17 = datamatrix(:,47); %plotted
    soilwater18 = datamatrix(:,48); %plotted
    soilwater19 = datamatrix(:,49); %plotted
    soilwater20 = datamatrix(:,50); %plotted
    soilwater21 = datamatrix(:,51); %plotted
    soilwater22 = datamatrix(:,52); %plotted
    soilwater23 = datamatrix(:,53); %plotted
elseif s == 3 %JSav
    %sonic related variables
    ux_avg = datamatrix(:,3); %plotted
    uy_avg = datamatrix(:,4); %plotted
    uz_avg = datamatrix(:,5); %plotted    
    ts_mean = datamatrix(:,6); %plotted    
    csat_warning = datamatrix(:,15); %flagged to output screen
    %irga related variables
    co2_mean = datamatrix(:,7); %plotted
    h2o_avg = datamatrix(:,8); %plotted
    co2_um_m = datamatrix(:,9); %plotted
    h2o_mm_m = datamatrix(:,10); %plotted       
    press_mean = datamatrix(:,11); %plotted     
    %system diagnostics    
    panel_temp = datamatrix(:,12); %plotted    
    batt_volt = datamatrix(:,13); %range printed to output screen 
    n_samples = datamatrix(:,14); %range printed to output screen     
    agc_avg = datamatrix(:,16); %plotted  
    low12volt = datamatrix(:,17); %%%% DON'T KNOW WHAT THIS LOOKS LIKE    
    watchdog = datamatrix(:,18); %range printed to output screen    
    %radiation variables
    rad_short_up = datamatrix(:,19); %plotted
    rad_short_down = datamatrix(:,20); %plotted
    rad_long_up = datamatrix(:,21); %plotted
    rad_long_down = datamatrix(:,22); %plotted 
    %other variables
    cnr1tc = datamatrix(:,23); %plotted   
    par_avg1 = datamatrix(:,24); %plotted    
    par_avg2 = datamatrix(:,25); %plotted
    airct1 = datamatrix(:,26); %plotted
    airct2 = datamatrix(:,27); %plotted
    rh1 = datamatrix(:,28); %plotted
    rh2 = datamatrix(:,29); %plotted
    rain_tot = datamatrix(:,30); %plotted
    soilwater1 = datamatrix(:,31); %plotted
    soilwater2 = datamatrix(:,32); %plotted
    soilwater3 = datamatrix(:,33); %plotted
    soilwater4 = datamatrix(:,34); %plotted
    soilwater5 = datamatrix(:,35); %plotted
    soilwater6 = datamatrix(:,36); %plotted
    soilwater7 = datamatrix(:,37); %plotted
    soilwater8 = datamatrix(:,38); %plotted
    soilwater9 = datamatrix(:,39); %plotted
    soilwater10 = datamatrix(:,40); %plotted
    soilwater11 = datamatrix(:,41); %plotted
    soilwater12 = datamatrix(:,42); %plotted
    soilwater13 = datamatrix(:,43); %plotted
    soilwater14 = datamatrix(:,44); %plotted
    soilwater15 = datamatrix(:,45); %plotted
    soilwater16 = datamatrix(:,46); %plotted
    tsoil_avg = datamatrix(:,47); %plotted
    shf1 = datamatrix(:,48); %plotted
    shf2 = datamatrix(:,49); %plotted
elseif s == 4 %PJ
    %sonic related variables
    ux_avg = datamatrix(:,3); %plotted
    uy_avg = datamatrix(:,4); %plotted
    uz_avg = datamatrix(:,5); %plotted    
    ts_mean = datamatrix(:,6); %plotted    
    csat_warning = datamatrix(:,15); %flagged to output screen
    %irga related variables
    co2_mean = datamatrix(:,7); %plotted
    h2o_avg = datamatrix(:,8); %plotted
    co2_um_m = datamatrix(:,9); %plotted
    h2o_mm_m = datamatrix(:,10); %plotted       
    press_mean = datamatrix(:,11); %plotted     
    %system diagnostics    
    panel_temp = datamatrix(:,12); %plotted    
    batt_volt = datamatrix(:,13); %range printed to output screen 
    n_samples = datamatrix(:,14); %range printed to output screen     
    agc_avg = datamatrix(:,16); %plotted  
    low12volt = datamatrix(:,17); %%%% DON'T KNOW WHAT THIS LOOKS LIKE    
    watchdog = datamatrix(:,18); %range printed to output screen    
    %radiation variables
    rad_short_up = datamatrix(:,19); %plotted
    rad_short_down = datamatrix(:,20); %plotted
    rad_long_up = datamatrix(:,21); %plotted
    rad_long_down = datamatrix(:,22); %plotted     
    %other variables
    par_avg = datamatrix(:,23); %plotted     
    airct1 = datamatrix(:,24); %plotted
    airct2 = datamatrix(:,25); %plotted    
    rh1 = datamatrix(:,26); %plotted
    rh2 = datamatrix(:,27); %plotted      
    rain_tot = datamatrix(:,28); %plotted    
    shf_pin = datamatrix(:,29); %plotted
    shf_jun = datamatrix(:,30); %plotted 
%    soilwater1 = datamatrix(:,32); %plotted
%    soilwater2 = datamatrix(:,33); %plotted    
elseif s == 6 || s == 5 %Mcon || PPine
    %sonic related variables
    ux_avg = datamatrix(:,3); %plotted
    uy_avg = datamatrix(:,4); %plotted
    uz_avg = datamatrix(:,5); %plotted
    ts_mean = datamatrix(:,6); %plotted
    csat_warning = datamatrix(:,15); %flagged to output screen
    %irga related variables
    co2_mean = datamatrix(:,7); %plotted
    h2o_avg = datamatrix(:,8); %plotted
    co2_um_m = datamatrix(:,9); %plotted
    h2o_mm_m = datamatrix(:,10); %plotted
    press_mean = datamatrix(:,11); %plotted
    %system diagnostics    
    panel_temp = datamatrix(:,12); %plotted    
    batt_volt = datamatrix(:,13); %range printed to output screen 
    n_samples = datamatrix(:,14); %range printed to output screen     
    agc_avg = datamatrix(:,16); %plotted  
    low12volt = datamatrix(:,17); %%%% DON'T KNOW WHAT THIS LOOKS LIKE    
    watchdog = datamatrix(:,18); %range printed to output screen    
    %radiation variables
    rad_short_up = datamatrix(:,19); %plotted
    rad_short_down = datamatrix(:,20); %plotted
    rad_long_up = datamatrix(:,21); %plotted
    rad_long_down = datamatrix(:,22); %plotted     
    %other variables
    cnr1tc = datamatrix(:,23); %plotted
    airct1 = datamatrix(:,24); %plotted
    airct2 = datamatrix(:,25); %plotted
    rh1 = datamatrix(:,26); %plotted
    rh2 = datamatrix(:,27); %plotted    
    par_avg = datamatrix(:,28); %plotted    
elseif s == 7
    %sonic related variables
    ux_avg = datamatrix(:,3); %plotted
    uy_avg = datamatrix(:,4); %plotted
    uz_avg = datamatrix(:,5); %plotted    
    ts_mean = datamatrix(:,6); %plotted
    csat_warning = datamatrix(:,15); %flagged to output screen    
    %irga related variables    
    co2_mean = datamatrix(:,7); %plotted
    h2o_avg = datamatrix(:,8); %plotted
    co2_um_m = datamatrix(:,9); %plotted
    h2o_mm_m = datamatrix(:,10); %plotted     
    press_mean = datamatrix(:,11); %plotted     
    %system diagnostics    
    panel_temp = datamatrix(:,12); %plotted      
    batt_volt = datamatrix(:,13); %range printed to output screen
    n_samples = datamatrix(:,14); %range printed to output screen     
    agc_avg = datamatrix(:,16); %plotted   
    low12volt = datamatrix(:,17); %%%% DON'T KNOW WHAT THIS LOOKS LIKE
    watchdog = datamatrix(:,18); %range printed to output screen
    %other variables    
    par_avg = datamatrix(:,19); %plotted    
    rain_tot = datamatrix(:,20); %plotted  
    rh1 = datamatrix(:,22); %plotted
    rh2 = datamatrix(:,24); %plotted
    rh3 = datamatrix(:,26); %plotted
    t_hmp1 = datamatrix(:,21); %plotted
    t_hmp2 = datamatrix(:,23); %plotted
    t_hmp3 = datamatrix(:,25); %plotted
    tsoil_avg = datamatrix(:,27); %plotted    
    soilwater1 = datamatrix(:,28); %plotted
    soilwater2 = datamatrix(:,29); %plotted
    soilwater3 = datamatrix(:,30); %plotted
    soilwater4 = datamatrix(:,31); %plotted
    soilwater5 = datamatrix(:,32); %plotted
    soilwater6 = datamatrix(:,33); %plotted
    soilwater7 = datamatrix(:,34); %plotted
    soilwater8 = datamatrix(:,35); %plotted
    soilwater9 = datamatrix(:,36); %plotted  
    cnr1tc = datamatrix(:,41); %plotted    
    %radiation variables
    rad_short_up = datamatrix(:,37); %plotted
    rad_short_down = datamatrix(:,38); %plotted
    rad_long_up = datamatrix(:,39); %plotted
    rad_long_down = datamatrix(:,40); %plotted
   
end

%--------------------------------------------------------------------------

%figure(1);
scrsz = get(0,'ScreenSize');
figure('Position',[10 1 1250 900]);

%Plots for sonic x,y,z directionals
subplot(3,3,1); 
hold on; box on;
plot(record(length(record)-days*48:length(record)-1,:),...
    ux_avg{:}(length(record)-days*48:length(record)-1,:),'r');
plot(record(length(record)-days*48:length(record)-1,:),...
    uy_avg{:}(length(record)-days*48:length(record)-1,:),'g'); 
plot(record(length(record)-days*48:length(record)-1,:),...
    uz_avg{:}(length(record)-days*48:length(record)-1,:),'k');
legend('ux','uy','uz','Location','NorthEastOutside');
xlabel('Record number'); ylabel('m s^{-1}');
title('x, y, and z sonic directionals');
hold off;

%Print to screen the flag variable csat_warning
csat = csat_warning{:}; %converting cell array to vector
if sum(csat(length(record)-days*48:length(record)-1,:))>0
    for i = length(csat)-days*48:length(csat)-1
        if csat(i) > 10
            disp(sprintf('csat_warning = %d',csat(i)));
            disp(timestamp{:}(i));
        else
        end
    end
else
    disp('No csat_warnings');
end

%Plot temperature
subplot(3,3,2);
box on; hold on;
plot(record(length(record)-days*48:length(record)-1,:),...
    ts_mean{:}(length(record)-days*48:length(record)-1,:),'g');
plot(record(length(record)-days*48:length(record)-1,:),...
    panel_temp{:}(length(record)-days*48:length(record)-1,:),'b');
if s == 1 || s == 2
    plot(record(length(record)-days*48:length(record)-1,:),...
    t_hmp{:}(length(record)-days*48:length(record)-1,:),'r');
elseif s == 3 || s == 6 
    plot(record(length(record)-days*48:length(record)-1,:),...
    airct1{:}(length(record)-days*48:length(record)-1,:),'r');
    plot(record(length(record)-days*48:length(record)-1,:),...
    airct2{:}(length(record)-days*48:length(record)-1,:),':r');
elseif s == 4
    plot(record(length(record)-days*48:length(record)-1,:),...
    airct1{:}(length(record)-days*48:length(record)-1,:),'r');
elseif s == 7
    plot(record(length(record)-days*48:length(record)-1,:),...
    t_hmp1{:}(length(record)-days*48:length(record)-1,:),'r');
    plot(record(length(record)-days*48:length(record)-1,:),...
    t_hmp2{:}(length(record)-days*48:length(record)-1,:),'r');
    plot(record(length(record)-days*48:length(record)-1,:),...
    t_hmp3{:}(length(record)-days*48:length(record)-1,:),'r');
end
if s == 1 || s == 2 || s == 3 || s == 7
    plot(record(length(record)-days*48:length(record)-1,:),...
    tsoil_avg{:}(length(record)-days*48:length(record)-1,:),'c');
elseif s == 6
end
if s == 1 || s == 2 || s == 3 || s == 5 || s == 6 || s == 7
    plot(record(length(record)-days*48:length(record)-1,:),...
    cnr1tc{:}(length(record)-days*48:length(record)-1,:),':k');
elseif s == 4
end

if s == 1 || s == 2
    legend('Sonic','Panel','Hmp','Soil','cnr1tc','Location','NorthEastOutside');
elseif s == 3
    legend('Sonic','Panel','Airtc1','Airtc2','Soil','cnr1tc','Location','NorthEastOutside');    
elseif s == 4
    legend('Sonic','Panel','Airtc1','Location','NorthEastOutside');
elseif s == 5
    legend('Sonic','Panel','cnr1tc','Location','NorthEastOutside');
elseif s == 6
    legend('Sonic','Panel','Airtc1','Airtc2','cnr1tc','Location','NorthEastOutside');
elseif s == 7
    legend('Sonic','Panel','Hmp1','Hmp2','Hmp3','Soil','cnr1tc','Location','NorthEastOutside');
end
xlabel('Record number'); ylabel('Degrees C');
title('Temperature');
hold off;

%Plot irga co2 and h2o variables
subplot(3,3,3);
box on; hold on;
plot(record(length(record)-days*48:length(record)-1,:),...
    co2_mean{:}(length(record)-days*48:length(record)-1,:),'r');
plot(record(length(record)-days*48:length(record)-1,:),...
    100*h2o_avg{:}(length(record)-days*48:length(record)-1,:),'b');
plot(record(length(record)-days*48:length(record)-1,:),...
    100*h2o_mm_m{:}(length(record)-days*48:length(record)-1,:),'k');
plot(record(length(record)-days*48:length(record)-1,:),...
    co2_um_m{:}(length(record)-days*48:length(record)-1,:),'g');
legend('co2 (mg/m^3)','h2o (g/m^3*100)','h2o (um/m*100)','co2 (um/m)','Location','NorthEastOutside');
title('irga co2 and h2o variables');
xlabel('Record number');
hold off;

%Plot irga pressure
subplot(3,3,4);
box on; hold on;
plot(record(length(record)-days*48:length(record)-1,:),...
    press_mean{:}(length(record)-days*48:length(record)-1,:),'-r');
plot([record(length(record)-days*48) record(length(record)-1)],...
    [max(press_mean{:}) max(press_mean{:})],'--r');
plot([record(length(record)-days*48) record(length(record)-1)],...
    [min(press_mean{:}) min(press_mean{:})],'--r');
title('Pressure at irga');
xlabel('Record number'); ylabel('kPa');
legend('Pressure','Max recorded pressure','Min recorded pressure','Location','SouthOutside');
hold off;

%Plotting the entire agc_avg variable
subplot(3,3,5);
plot(record(length(record)-days*48:length(record)-1,:),...
    agc_avg{:}(length(record)-days*48:length(record)-1,:));
title('average agc');
xlabel('Record number'); ylabel('Value');

%Plotting the entire rain_tot variable
subplot(3,3,6);
if s == 1 || s == 2 || s == 4 || s == 3 || s == 7
plot(record(length(record)-days*48:length(record)-1,:),...
    rain_tot{:}(length(record)-days*48:length(record)-1,:),'k');
elseif s == 6
end
title('Total rainfall');
xlabel('Record number'); ylabel('mm');

%voltage range
voltage = batt_volt{:};
disp(sprintf('Battery voltage range = %g to %g',min(voltage(length(record)-days*48:length(record)-1,:)),...
    max(voltage(length(record)-days*48:length(record)-1,:))));

%number of samples
samples = n_samples{:};
disp(sprintf('Sample number range = %d to %d',min(samples(length(record)-days*48:length(record)-1,:)),...
    max(samples(length(record)-days*48:length(record)-1,:))));

%watchdog range
watchdog = watchdog{:};
disp(sprintf('Watchdog range = %d to %d',min(watchdog(length(record)-days*48:length(record)-1,:)),...
    max(watchdog(length(record)-days*48:length(record)-1,:))));

%Plotting relative humidity
subplot(3,3,7);
box on; hold on;
if s == 1 || s == 2
    plot(record(length(record)-days*48:length(record)-1,:),...
    rh_hmp{:}(length(record)-days*48:length(record)-1,:),'r');
elseif s == 3 || s == 4 || s == 5 || s == 6
    plot(record(length(record)-days*48:length(record)-1,:),...
    rh1{:}(length(record)-days*48:length(record)-1,:),'-r');
    plot(record(length(record)-days*48:length(record)-1,:),...
    rh2{:}(length(record)-days*48:length(record)-1,:),':r');
elseif s == 7
    plot(record(length(record)-days*48:length(record)-1,:),...
    rh1{:}(length(record)-days*48:length(record)-1,:),'-r');
    plot(record(length(record)-days*48:length(record)-1,:),...
    rh2{:}(length(record)-days*48:length(record)-1,:),':r');
    plot(record(length(record)-days*48:length(record)-1,:),...
    rh3{:}(length(record)-days*48:length(record)-1,:),':r');
end
title('Relative humidity');ylabel('%');
xlabel('Record number');
hold off;

%Plotting radiation variables
subplot(3,3,8);
box on; hold on;
if s == 1 || s == 2 || s == 3 || s == 4 || s == 5 || s == 6 || s == 7
plot(record(length(record)-days*48:length(record)-1,:),...
    rad_short_up{:}(length(record)-days*48:length(record)-1,:),'r');
plot(record(length(record)-days*48:length(record)-1,:),...
    rad_short_down{:}(length(record)-days*48:length(record)-1,:),'b');
plot(record(length(record)-days*48:length(record)-1,:),...
    rad_long_up{:}(length(record)-days*48:length(record)-1,:),'g');
plot(record(length(record)-days*48:length(record)-1,:),...
    rad_long_down{:}(length(record)-days*48:length(record)-1,:),':b');
end
if s == 1 || s == 2 || s == 4 || s == 5 || s == 6 || s == 7 
    plot(record(length(record)-days*48:length(record)-1,:),...
    par_avg{:}(length(record)-days*48:length(record)-1,:),'k');
elseif s == 3
    plot(record(length(record)-days*48:length(record)-1,:),...
    par_avg1{:}(length(record)-days*48:length(record)-1,:),':r');
    plot(record(length(record)-days*48:length(record)-1,:),...
    par_avg2{:}(length(record)-days*48:length(record)-1,:),':c');
end
if s == 1 || s == 2 || s == 3
plot(record(length(record)-days*48:length(record)-1,:),...
    shf1{:}(length(record)-days*48:length(record)-1,:),':r');
plot(record(length(record)-days*48:length(record)-1,:),...
    shf2{:}(length(record)-days*48:length(record)-1,:),'-c');
elseif s == 4 
plot(record(length(record)-days*48:length(record)-1,:),...
    shf_pin{:}(length(record)-days*48:length(record)-1,:),':r');
plot(record(length(record)-days*48:length(record)-1,:),...
    shf_jun{:}(length(record)-days*48:length(record)-1,:),'-c');
elseif s == 5 || s == 6 || s == 7
end
if s == 1 || s == 2
    legend('rsu','rsd','rlu','rld','PAR','shf1','shf2','Location','NorthEastOutside');
elseif s == 3
    legend('rsu','rsd','rlu','rld','par1','par2','shf1','shf2','Location','NorthEastOutside');
elseif s == 4
    legend('rsu','rsd','rlu','rld','PAR','shf-pin','shf-jun','Location','NorthEastOutside');    
elseif s == 5
    legend('rsu','rsd','rlu','rld','PAR','Location','NorthEastOutside');
elseif s == 6 || s == 7
    legend('rsu','rsd','rlu','rld','PAR','Location','NorthEastOutside');
end
title('radiation variables');ylabel('W m^{-2}');
xlabel('Record number');
hold off;

%Plotting soil waters
subplot(3,3,9);
box on; hold on;
if s == 4
%     plot(record(length(record)-days*48:length(record)-1,:),...
%         soilwater1{:}(length(record)-days*48:length(record)-1,:),'*c');
%     plot(record(length(record)-days*48:length(record)-1,:),...
%         soilwater2{:}(length(record)-days*48:length(record)-1,:),'--g');    
elseif s == 5 || s == 6
elseif s == 1 || s == 2
    plot(record(length(record)-days*48:length(record)-1,:),...
        soilwater1{:}(length(record)-days*48:length(record)-1,:),'*c');
    plot(record(length(record)-days*48:length(record)-1,:),...
        soilwater2{:}(length(record)-days*48:length(record)-1,:),'--g');
    plot(record(length(record)-days*48:length(record)-1,:),...
        soilwater3{:}(length(record)-days*48:length(record)-1,:),'-.b');
    plot(record(length(record)-days*48:length(record)-1,:),...
        soilwater4{:}(length(record)-days*48:length(record)-1,:),':r');
    plot(record(length(record)-days*48:length(record)-1,:),...
        soilwater5{:}(length(record)-days*48:length(record)-1,:),'-.b');
    plot(record(length(record)-days*48:length(record)-1,:),...
        soilwater6{:}(length(record)-days*48:length(record)-1,:),'-.b');
    plot(record(length(record)-days*48:length(record)-1,:),...
        soilwater7{:}(length(record)-days*48:length(record)-1,:),'-.b');
    plot(record(length(record)-days*48:length(record)-1,:),...
        soilwater8{:}(length(record)-days*48:length(record)-1,:),'-.b');
    plot(record(length(record)-days*48:length(record)-1,:),...
        soilwater9{:}(length(record)-days*48:length(record)-1,:),'-.b');
    plot(record(length(record)-days*48:length(record)-1,:),...
        soilwater10{:}(length(record)-days*48:length(record)-1,:),'-.b');
    plot(record(length(record)-days*48:length(record)-1,:),...
        soilwater11{:}(length(record)-days*48:length(record)-1,:),'-.b');
    plot(record(length(record)-days*48:length(record)-1,:),...
        soilwater12{:}(length(record)-days*48:length(record)-1,:),'-.b');
    plot(record(length(record)-days*48:length(record)-1,:),...
        soilwater13{:}(length(record)-days*48:length(record)-1,:),'-.b');
    plot(record(length(record)-days*48:length(record)-1,:),...
        soilwater14{:}(length(record)-days*48:length(record)-1,:),'-.b');
    plot(record(length(record)-days*48:length(record)-1,:),...
        soilwater15{:}(length(record)-days*48:length(record)-1,:),'-.b');
    plot(record(length(record)-days*48:length(record)-1,:),...
        soilwater16{:}(length(record)-days*48:length(record)-1,:),'-.b');
    plot(record(length(record)-days*48:length(record)-1,:),...
        soilwater17{:}(length(record)-days*48:length(record)-1,:),'-.b');
    plot(record(length(record)-days*48:length(record)-1,:),...
        soilwater18{:}(length(record)-days*48:length(record)-1,:),'-.b');
    plot(record(length(record)-days*48:length(record)-1,:),...
        soilwater19{:}(length(record)-days*48:length(record)-1,:),'-.b');
    plot(record(length(record)-days*48:length(record)-1,:),...
        soilwater20{:}(length(record)-days*48:length(record)-1,:),'-.b');
    plot(record(length(record)-days*48:length(record)-1,:),...
        soilwater21{:}(length(record)-days*48:length(record)-1,:),'-.b');
    plot(record(length(record)-days*48:length(record)-1,:),...
        soilwater22{:}(length(record)-days*48:length(record)-1,:),'-.b');
    plot(record(length(record)-days*48:length(record)-1,:),...
        soilwater23{:}(length(record)-days*48:length(record)-1,:),'-.b');
elseif s == 3
    plot(record(length(record)-days*48:length(record)-1,:),...
        soilwater1{:}(length(record)-days*48:length(record)-1,:),'*c');
    plot(record(length(record)-days*48:length(record)-1,:),...
        soilwater2{:}(length(record)-days*48:length(record)-1,:),'--g');
    plot(record(length(record)-days*48:length(record)-1,:),...
        soilwater3{:}(length(record)-days*48:length(record)-1,:),'-.b');
    plot(record(length(record)-days*48:length(record)-1,:),...
        soilwater4{:}(length(record)-days*48:length(record)-1,:),':r');
    plot(record(length(record)-days*48:length(record)-1,:),...
        soilwater5{:}(length(record)-days*48:length(record)-1,:),'-.b');
    plot(record(length(record)-days*48:length(record)-1,:),...
        soilwater6{:}(length(record)-days*48:length(record)-1,:),'-.b');
    plot(record(length(record)-days*48:length(record)-1,:),...
        soilwater7{:}(length(record)-days*48:length(record)-1,:),'-.b');
    plot(record(length(record)-days*48:length(record)-1,:),...
        soilwater8{:}(length(record)-days*48:length(record)-1,:),'-.b');
    plot(record(length(record)-days*48:length(record)-1,:),...
        soilwater9{:}(length(record)-days*48:length(record)-1,:),'-.b');
    plot(record(length(record)-days*48:length(record)-1,:),...
        soilwater10{:}(length(record)-days*48:length(record)-1,:),'-.b');
    plot(record(length(record)-days*48:length(record)-1,:),...
        soilwater11{:}(length(record)-days*48:length(record)-1,:),'-.b');
    plot(record(length(record)-days*48:length(record)-1,:),...
        soilwater12{:}(length(record)-days*48:length(record)-1,:),'-.b');
    plot(record(length(record)-days*48:length(record)-1,:),...
        soilwater13{:}(length(record)-days*48:length(record)-1,:),'-.b');
    plot(record(length(record)-days*48:length(record)-1,:),...
        soilwater14{:}(length(record)-days*48:length(record)-1,:),'-.b');
    plot(record(length(record)-days*48:length(record)-1,:),...
        soilwater15{:}(length(record)-days*48:length(record)-1,:),'-.b');
    plot(record(length(record)-days*48:length(record)-1,:),...
        soilwater16{:}(length(record)-days*48:length(record)-1,:),'-.b');
elseif s == 7
    plot(record(length(record)-days*48:length(record)-1,:),...
        soilwater1{:}(length(record)-days*48:length(record)-1,:),'*c');
    plot(record(length(record)-days*48:length(record)-1,:),...
        soilwater2{:}(length(record)-days*48:length(record)-1,:),'--g');
    plot(record(length(record)-days*48:length(record)-1,:),...
        soilwater3{:}(length(record)-days*48:length(record)-1,:),'-.b');
    plot(record(length(record)-days*48:length(record)-1,:),...
        soilwater4{:}(length(record)-days*48:length(record)-1,:),':r');
    plot(record(length(record)-days*48:length(record)-1,:),...
        soilwater5{:}(length(record)-days*48:length(record)-1,:),'-.b');
    plot(record(length(record)-days*48:length(record)-1,:),...
        soilwater6{:}(length(record)-days*48:length(record)-1,:),'-.b');
    plot(record(length(record)-days*48:length(record)-1,:),...
        soilwater7{:}(length(record)-days*48:length(record)-1,:),'-.b');
    plot(record(length(record)-days*48:length(record)-1,:),...
        soilwater8{:}(length(record)-days*48:length(record)-1,:),'-.b');
    plot(record(length(record)-days*48:length(record)-1,:),...
        soilwater9{:}(length(record)-days*48:length(record)-1,:),'-.b');
end
title('Soil water');ylabel('Volume fraction h2o');
xlabel('Record number');
hold off;

%printing to screen the last timestamp
disp('Last data collection = '); disp(timestamp{:}(length(record)));


