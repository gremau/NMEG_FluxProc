%This program is a modification of the flux processor program to calculate
%just half-hourly wind values that can be used to calculate the planar
%coefficients needed for the planar rotation.  It outputs dates and times
%along with u,v, and w winds, mean wind speed, and theta.

%It reads in raw ts data, separates into half-hour periods, holds out
%half-hourly periods during calibrations (if the devices are lowered during
%calibration in particular TX sites), despikes the wind variables,
%calculates means, and writes to a site_windspeed file.  Timestamps correspond
%to the end of the half-hour period.

%This version was created by John DeLong and Marcy Litvak Summer 2008
 
function[date,hr]=UNM_planar_processor(year,filename,date,jday,site,sitecode,sitedir)
file=filename;

CR=13; 
LF=10;
COMMA=44;

fid=fopen(file,'r','ieee-le');  %file ID
d=fread(fid,864000,'uchar');

% find Line Feeds and Carriage Returns
icr = find(d==CR);
ilf = find(d==LF);

% find the end of the header
EOH = ilf(5);

% read last line of header to get the file structure
HLine2 = d(ilf(1)+1:ilf(2)-1)';
HLine5 = d(ilf(4)+1:ilf(5)-1)';

begfields = [1 find(HLine5==COMMA)+1];
endfields = [find(HLine5==COMMA)-1 length(HLine5)-1];

begfields2 = [1 find(HLine2==COMMA)+1];
endfields2 = [find(HLine2==COMMA)-1 length(HLine2)-1];

Nfields = length(begfields)

% don't read the quotes at beginning and end of each field
for i=1:Nfields
    FieldName{i} = char(HLine2(begfields2(i)+1:endfields2(i)-1));
    Field{i} = char(HLine5(begfields(i)+1: endfields(i)-1));
end

% Calculate the number of bytes in a record and get the corresponding matlab precision

for i=1:size(Field,2)
    if strcmp(char(Field(i)),'ULONG')
        NBytes(i) = 4;
        MatlabPrec{i} = 'uint32';
    elseif strcmp(char(Field(i)),'IEEE4')
        NBytes(i) = 4;
        MatlabPrec{i} = 'float32';
    elseif strcmp(char(Field(i)),'IEEE4L')
        NBytes(i) = 4;
        MatlabPrec{i} = 'float32';
    end       
end

%%% Start reading the channels
disp('reading data....')
% first position pointer at the end of the header
     fseek(fid,EOH,'bof');   %fseek repositions file position indicator (doc fseek). 'bof' = beginning of file
     ftell(fid);  %position = ftell(fid) returns the location of the file position indicator for the file specified by fid

     BytesPerRecord=sum(NBytes)*ones(size(NBytes)) - NBytes;
     BytesCumulative = [0 cumsum(NBytes(1:length(NBytes)-1))];

%read each column into data matrix:

     for i=1:Nfields
     fseek(fid,EOH+BytesCumulative(i),'bof');   %fseek repositions file position indicator (doc fseek). problem here
     data(:,i) = fread(fid,24*3600*10,char(MatlabPrec(i)),BytesPerRecord);  %reads data into matrix (data, col i)
     end

%assign variable names to columns of data:
if (Nfields==11);   %JSAV, PPINE, TX ....
     time1=(data(:,1));  %seconds since 1990(?)
     time2=(data(:,2));   % nanoseconds
     uin=(data(:,3));
     vin=(data(:,4));
     win=(data(:,5));
     diagsonin=(data(:,10));
elseif (Nfields==12 & (sitecode==1 | sitecode==2 | sitecode==10));  %GLand, SLand. %Sev sites have their columns mixed up. There is no irga diagnositc!  
     time1=(data(:,1));  %seconds since 
     time2=(data(:,2));   % nanoseconds 
     uin=(data(:,3));
     vin=(data(:,4));
     win=(data(:,5));
     diagsonin=(data(:,10));  
elseif (Nfields==12 & ~(sitecode==1 | sitecode==2));
     time1=(data(:,1));  %seconds since 
     time2=(data(:,2));   % nanoseconds
     uin=(data(:,4));
     vin=(data(:,5));
     win=(data(:,6));
     diagsonin=(data(:,11));
elseif (Nfields==14) % TX_forest
     time1=(data(:,1));     
     uin=(data(:,7));
     vin=(data(:,8));
     win=(data(:,9));
     Tin=(data(:,10)+273.15);     
     co2in=(data(:,11))/44;     
     h2oin=(data(:,12))/.018;     
     Pin=(data(:,13));
     diagcsat=(data(:,14));
     diagsonin = zeros(length(diagcsat),1);     
end

%WIND DIRECTION:
if sitecode==7;       %TX
    sonic_orient=146;   %THIS IS WIND DIRECTION (way its going in degrees) & MUST BE CHANGED FOR EVERY SITE.
elseif sitecode==1;   %grassland
    sonic_orient=180;
elseif sitecode==2;   %shrubland
    sonic_orient=180;   %check value
elseif sitecode==3;   %juniper savannah
    sonic_orient=225; 
elseif sitecode==4;   %PJ
    sonic_orient=225;   %NEED VALUE HERE
elseif sitecode==5;   %PPine
    sonic_orient=329;   %%sonic orient number is 320  (magnetic-%probably need declination)-->329
elseif sitecode==6;   %MCON
    sonic_orient=333;   %%%sonic orientation number is 324 (magnetic- probably%need declination)--> 333
elseif sitecode==8;   %TX_forest
    sonic_orient=156;
elseif sitecode==9;   %TX_grassland
    sonic_orient=156;
elseif sitecode==10;   %PJ_girdle
    sonic_orient=224;  
elseif sitecode==11;   %New_GLand
    sonic_orient=180; 
else
end

%convert time numbers to something meaningful
datev = datevec((time1/(60*60*24))+726834);  %convert seconds since 1990 to datestamp
%msec = time2/100000000;  %10 readings/ second-- this gives the number (1-10)

[m,n]=size(data);
hfhrs=m/18000;
hfhr1=floor(hfhrs);
hfhr2=round(hfhrs);

%%%calculate half-hourly values
disp('calculating half-hourly values....')
month_ts = datev(:,2);
day_ts = datev(:,3);
hr_ts = datev(:,4);
min_ts = datev(:,5);
day = day_ts(1);
n = 1;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Start for-loop for 48 half-hour periods  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

for i=1:48  %cycle through all 48 (potential) half-hour time periods
    %calculate hour & minutes for each period (time recorded at the end)
    hr(i)= floor((i-1)/2);
    min_end(i)= (((i)/2)-hr(i))*60;
    if min_end(i)==0
        min_end(i)=60;
    end
    min_beg(i) = min_end(i)-30;
    decimal_day = jday + hr(i)/24 + min_beg(i)/1440;
    
        %find indeces for each half hour period   find((hr_ts==hr(i) & min_beg(i)<=min_ts<=(min_end(i)+1)));
            %this needs to be fixed:
        if size(find((day_ts==day & hr_ts==hr(i) & min_ts>=min_beg(i) & min_ts<min_end(i))),1)> 0  %half-hours with data
            datev_30(i,1:6) = datev(max(find(day_ts==day & hr_ts==hr(i) & min_ts>=min_beg(i) & min_ts<(min_end(i)))),:);  %assign timestamp (end of period)
             n = n+1
             julday(i,1) = jday;
             numdate(i,1) = date;
             
             isdata(i) = 1;
             
             %READ IN DATA FOR THAT HALF-HOUR-- offset by 1 to account for fixed lag:

             if n<hfhr2;
                %sonic measurements:
                u = uin(find((day_ts==day & hr_ts==hr(i) & min_ts>=min_beg(i) & min_ts<(min_end(i)))));
                v = vin(find((day_ts==day & hr_ts==hr(i) & min_ts>=min_beg(i) & min_ts<(min_end(i)))));
                w = win(find((day_ts==day & hr_ts==hr(i) & min_ts>=min_beg(i) & min_ts<(min_end(i)))));
                diagson = diagsonin(find((day_ts==day & hr_ts==hr(i) & min_ts>=min_beg(i) & min_ts<(min_end(i))))); 
                uvw = [u v w];

              elseif n==hfhr2;
                %sonic measurements:
                u = uin(find((day_ts==day & hr_ts==hr(i) & min_ts>=min_beg(i) & min_ts<(min_end(i))))-0);
                v = vin(find((day_ts==day & hr_ts==hr(i) & min_ts>=min_beg(i) & min_ts<(min_end(i))))-0);
                w = win(find((day_ts==day & hr_ts==hr(i) & min_ts>=min_beg(i) & min_ts<(min_end(i))))-0);
                diagson = diagsonin(find((day_ts==day & hr_ts==hr(i) & min_ts>=min_beg(i) & min_ts<(min_end(i))))-0); 
                uvw = [u v w];
              end        

            num = size(find((day_ts==day & hr_ts==hr(i) & min_ts>=min_beg(i) & min_ts<(min_end(i)))),1);

            % call despike
            [iu,removedu] = UNM_despike(uvw(:,1),6,-20,20,'U',5);  uvw(find(~iu),1) = NaN*ones(size(find(~iu))); %puts NaN in for all records that were despiked to 0
            [iv,removedv] = UNM_despike(uvw(:,2),6,-20,20,'V',6);  uvw(find(~iv),2) = NaN*ones(size(find(~iv)));
            [iw,removedw] = UNM_despike(uvw(:,3),6,-20,20,'W',7);  uvw(find(~iw),3) = NaN*ones(size(find(~iw)));

            iuiviw = [iu,iv,iw];

            SONDESPIKE = ones(length(iu),1);
            SONDESPIKE(find(sum(iuiviw,2) < 3)) = 0;
            SONDESPIKE(find(diagson > 0)) = 0;
            SONDIAG = SONDESPIKE;

            uvwmean(i,1:3) = [mean(uvw(find(SONDIAG),1)),mean(uvw(find(SONDIAG),2)),mean(uvw(find(SONDIAG),3))];

            THETA = (-atan2(uvwmean(i,2),uvwmean(i,1)) + pi/2) *180/pi;
            if THETA < 0
                THETA = THETA+360;
            end
            THETA = THETA - 90 + sonic_orient ;
            THETA(find(THETA>360)) = THETA(find(THETA>360))-360;
            THETA(find(THETA < 0)) = THETA(find(THETA < 0))+360;

            theta(i,1) = THETA;
            speed(i,1)=sqrt((uvwmean(i,1).^2) + (uvwmean(i,2).^2) + (uvwmean(i,3).^2));
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % Hold out periods of known calibration  
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%   
    
            if sitecode == 7 & numdate == 30107 & (decimal_day >= 60.4375 & decimal_day < 60.7083) %3/1/2007 10:30 to 17:00
                outputs = 0;
            elseif sitecode == 7 & numdate == 72307 & (decimal_day >= 204.5208 & decimal_day < 204.6458) %7/23/2007 12:30 to 15:30
                outputs = 0;
            elseif sitecode == 7 & numdate == 92707 & (decimal_day >= 270.4583 & decimal_day < 270.5208) %9/27/2007 11:00 to 12:30
                outputs = 0;
            elseif sitecode == 7 & numdate == 100207 & (decimal_day >= 275.4166 & decimal_day < 275.5833) %10/2/2007 10:00 to 14:00
                outputs = 0;
            elseif sitecode == 7 & numdate == 101607 & (decimal_day >= 289.4375 & decimal_day < 289.5625) %10/16/2007 10:30 to 13:30
                outputs = 0;
            elseif sitecode == 7 & numdate == 51607 & (decimal_day >= 136.0097 & decimal_day < 136.7083) %5/16/2007 14:00 to 17:00
                outputs = 0;
            elseif sitecode == 7 & numdate == 80707 & (decimal_day >= 219.4791 & decimal_day < 219.7291) %8/7/2007 11:30 to 17:30
                outputs = 0;
            elseif sitecode == 7 & numdate == 82007 & (decimal_day >= 232.4583 & decimal_day < 232.5416) %8/20/2007 11:00 to 13:00
                outputs = 0;
            elseif sitecode == 7 & numdate == 82107 & (decimal_day >= 233.4375 & decimal_day < 233.4791) %8/21/2007 10:30 to 11:30
                outputs = 0;
            elseif sitecode == 7 & numdate == 40907 & (decimal_day >= 99.6458 & decimal_day < 100) %4/9/2007 15:30 to 24:00
                outputs = 0;
            elseif sitecode == 7 & numdate == 41007 & (decimal_day >= 100 & decimal_day < 100.6041) %4/10/2007 0:00 to 14:30
                outputs = 0;
            elseif sitecode == 7 & numdate == 12406 & (decimal_day >= 24.4583 & decimal_day < 24.5416) %1/24/2006 11:00 to 13:00
                outputs = 0;
            elseif sitecode == 7 & numdate == 21206 & (decimal_day >= 43.3541 & decimal_day < 43.4375) %2/12/2006 8:30 to 10:30
                outputs = 0;
            elseif sitecode == 7 & numdate == 41006 & (decimal_day >= 100.4375 & decimal_day < 100.7291) %4/10/2006 10:30 to 17:30
                outputs = 0;
            elseif sitecode == 7 & numdate == 52206 & (decimal_day >= 142.5833 & decimal_day < 142.6458) %5/22/2006 14:00 to 15:30
                outputs = 0;
            elseif sitecode == 7 & numdate == 63006 & (decimal_day >= 181.5208 & decimal_day < 181.6041) %6/30/2006 12:30 to 14:30
                outputs = 0;
            elseif sitecode == 7 & numdate == 82406 & (decimal_day >= 236.2916 & decimal_day < 236.8541) %8/24/2006 7:00 to 20:30
                outputs = 0;
            elseif sitecode == 7 & numdate == 92906 & (decimal_day >= 272.4166 & decimal_day < 272.5) %9/29/2006 10:00 to 12:00
                outputs = 0;
            elseif sitecode == 7 & numdate == 10306 & (decimal_day >= 276.3958 & decimal_day < 276.4375) %10/3/2006 9:30 to 10:30
                outputs = 0;
            elseif sitecode == 7 & numdate == 103106 & (decimal_day >= 304.4375 & decimal_day < 304.5833) %10/31/2006 10:30 to 14:00
                outputs = 0;
            elseif sitecode == 7 & numdate == 11205 & (decimal_day >= 12.6041 & decimal_day < 12.6666) %1/12/2005 14:30 to 16:00
                outputs = 0;
            elseif sitecode == 7 & numdate == 41305 & (decimal_day >= 103.375) %4/13/2005 9:00 to 24:00
                outputs = 0;
            elseif sitecode == 7 & numdate == 41405 %4/14/2005 all day
                outputs = 0;
            elseif sitecode == 7 & numdate == 41505 & (decimal_day < 105.6666) %4/15/2005 0:00 to 16:00
                outputs = 0;
            elseif sitecode == 7 & numdate == 51905 & (decimal_day >= 139.6041 & decimal_day < 139.6666) %5/19/2005 14:30 to 16:00
                outputs = 0;
            elseif sitecode == 7 & numdate == 61805 & (decimal_day >= 169.4583 & decimal_day < 169.5833) %6/18/2005 11:00 to 14:00
                outputs = 0;
            elseif sitecode == 7 & numdate == 81605 & (decimal_day >= 228.5208 & decimal_day < 228.5833) %8/16/2005 12:30 to 14:00
                outputs = 0;
            elseif sitecode == 7 & numdate == 91205 & (decimal_day >= 255.4375 & decimal_day < 255.5208) %9/12/2005 10:30 to 12:30
                outputs = 0;
            elseif sitecode == 7 & numdate == 92305 & (decimal_day >= 266.5625 & decimal_day < 266.6041) %9/23/2005 13:30 to 14:30
                outputs = 0;
            else
                outputs = 1;
            end

            if outputs == 0
                julday(i,1) = jday;
                numdate(i,1) = date;
                uvwmean(i,1:3) = NaN;
                theta(i,1) = NaN;
                speed(i,1) = NaN;
            end

        elseif size(find(day_ts==day & hr_ts==hr(i) & min_ts>=min_beg(i) & min_ts<min_end(i)),1)== 0  %no data
            datev_30(i,1:6)=[datev(1,1) datev(1,2) datev(1,3) hr(i) min_end(i) 0]; %assign timestamp (end of period)
            julday(i,1) = jday;
            numdate(i,1) = date;
            uvwmean(i,1:3) = NaN;
            theta(i,1) = NaN;
            speed(i,1) = NaN;
            
            isdata(i) = 0;
            
        end 
end

timestamp = datestr(datev_30);
datenumber = datenum(datev_30);

% data for output

y = [datev_30,numdate,julday,uvwmean,theta,speed];
%headertext = {'year','month','day','hour','min','second','date','jday', 'iok','u_mean','v_mean','w_mean'};

% open windspeed file to be used for planar rotations
 
windspeedfile=strcat(sitedir, site,'_windspeeds');
[num text]=xlsread(windspeedfile,'windspeeds','A1:A65500');

disp('preparing to enter data in windspeed file....') 

timestamp2=text(5:size(text,1));

n=1;
time_match1=NaN;
for i=1:48
    if isnan(time_match1)==1 && isdata(i) == 1  %have not yet matched up first row
        timenum=datenum(timestamp2);
        time_match=find(abs(timenum-datenumber(i)) < 1/(48*3))+4;
        if time_match > 4
            y2(n,:)=y(i,:);
            time_match1=time_match; 
            n=n+1;           
        end
    elseif isnan(time_match1)==0 %already have matched up first row & there is more data that day
            y2(n,:)=y(i,:);
            n=n+1;  
    else %no more data
    end  
end

% write out to windspeed file

if isnan(time_match1)==0 && size(time_match1,1)==1;
    xlswrite(windspeedfile,y2,'windspeeds', strcat('B',num2str(time_match1)));
    disp('wrote to windspeed file')
else
    disp('ERROR: FAILED TO WRITE TO FLUX_ALL!!!!!!!!!')
    disp('ERROR: FAILED TO WRITE TO FLUX_ALL!!!!!!!!!')
end
