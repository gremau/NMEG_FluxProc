%% from http://groups.google.com/group/comp.soft-sys.matlab/browse_thread/thread/97880400c955971b/9d24454a47f067f0?hl=en&lnk=gst&q=dataset+join#9d24454a47f067f0

%% Generate some data and place it into a dataset array
clear all
clc

Time(1,:) = [2009,  10,  24,  12,  45, 00];

 for i = 1 : 99

     Time(i+1,:) = Time(i,:) + [0,  0,  0,  0,  0, 2];

 end

Time = datestr(Time, 'mmmm dd, yyyy HH:MM:SS');
Time = cellstr(Time(:,:));

Dataset1 = dataset(Time);
Dataset1.AirSpeed = linspace(8451, 8550, 100)';

clear Time
%% Create dataset 2

clc

Time(1,:) = [2009,  10,  24,  12,  45, 00];

 for i = 1 : 66

     Time(i+1,:) = Time(i,:) + [0,  0,  0,  0,  0, 3];

 end

Time = datestr(Time, 'mmmm dd, yyyy HH:MM:SS');
Time = cellstr(Time(:,:));

Dataset2 = dataset(Time);
Dataset2.Altitude = linspace(600, 501, 67)';
Dataset2.Pressure = linspace(1050, 900, 67)';

% Both datasets share 'Time' as a common variable
% The two datasets are sampled at different rates

Dataset1(1:10,:)
Dataset2(1:10,:)

%% Show a join

% All rows that share a common time stamp are
%copied to a new dataset array

Dataset3 = join(Dataset1, Dataset2, 'Type', 'full');
Dataset3(1:10,:)

%% Clean up
% Combine Time Variables
index = isnan(Dataset3.AirSpeed);
Dataset3.Time_left(index) = Dataset3.Time_right(index);
Dataset3.Time_right = [];
Dataset3.Properties.VarNames(1) = {'Time'};
Time_numeric = datenum(Dataset3.Time);

% Use Interpolation to predict AirSpeed
AirSpeed_interp = fit(Time_numeric(~index),...
    Dataset3.AirSpeed(~index),'linearinterp');
Dataset3.AirSpeed(index) = AirSpeed_interp...
    (Time_numeric(index));

% Use Interpolation to predict Altitude and Pressure
index = isnan(Dataset3.Altitude);

Altitude_interp = fit(Time_numeric(~index),...
    Dataset3.Altitude(~index),'linearinterp');
Dataset3.Altitude(index) = Altitude_interp...
    (Time_numeric(index));

Pressure_interp = fit(Time_numeric(~index),...
    Dataset3.Pressure(~index),'linearinterp');
Dataset3.Pressure(index) = Pressure_interp...
    (Time_numeric(index));

Dataset3(1:10,:)

%% Show an Inner join

clc
Dataset1(1:10,:)
Dataset2(1:10,:)

% Inner Join
% All rows that share a common time stamp
% are copied to a new dataset array

Dataset4 = join(Dataset1, Dataset2, 'Type', 'inner');
Dataset4.Properties.VarNames(1) = {'Time'};
Dataset4.Time_right = [];
Dataset4(1:10,:)

%% Show a Full join

clc
Dataset1(1:10,:)
Dataset2(1:10,:)

% Full join
% All rows that share a common time stamp are
% copied to a new dataset array

Dataset5 = join(Dataset1, Dataset2, 'Type', 'full');
Dataset5(1:10,:)

%%  Show a Right Outer Join

clc
Dataset6 = join(Dataset1, Dataset2, 'Type', 'rightouter');
Dataset6(1:10,:) 