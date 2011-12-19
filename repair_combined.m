

fid = fopen('C:\Research - Flux Towers\Flux Tower Data by Site\TX_forest\2005\problem1\combined.dat');
data = fread(fid);

timestamp = data(:,1);
day = data(:,3);
hour_minute = data(:,4);
seconds = data(:,5);

Y = 2005;
MO = 1;
D = day;
%H = 
%vec = [Y,MO,D,H,MI,S];


%TOACI1,CR23X,105,,,,,,,,,,
%TMSTAMP,RECNBR,Day_RTM,Hour_Minute_RTM,Seconds_RTM,Ux,Uy,Uz,Ts,co2,h2o,press,diag_csat

data_to_write = data(1:10,:);

fwrite('C:\Research - Flux Towers\Flux Tower Data by Site\TX_forest\2005\problem1\combined2.dat','data_to_write');

% 1/1/2005,120252192,1,159,59.5,0.86425,0.96,0.0895,18.353,675.58,16.267,99.104,1
% 1/1/2005,120252193,1,159,59.6,0.87175,0.83775,0.03425,18.296,675.25,16.307,99.069,1
% 1/1/2005,120252194,1,159,59.7,0.907,0.87125,0.027,18.331,674.96,16.296,99.069,1
% 1/1/2005,120252195,1,159,59.8,0.92,0.94825,-0.0665,18.28,675.25,16.286,99.069,1
% 1/1/2005,120252196,1,159,59.9,0.8465,1.0522,-0.0325,18.287,675.14,16.301,99.069,1