function [FLAG,removed]=UNM_despike(x,nstds,xmin,xmax,signal,var)

%to run as test from despiketest.m, substitute delta_x for removed

FLAG = ones(size(x));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Flag values that are already NaN
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

idum = find(isnan(x));
FLAG(idum) = 0; %sets record value to 0 if it is NaN and retains 1's for good values

if length(find(FLAG)) > 0
   nans = length(idum);
   if nargin > 4
   %fprintf('%-5s%2.0f',['[' signal ']: # NaNs ='],nans);
   else
   %fprintf('%-20s%6.0f','# OF SPIKES FOUND:',nans);
   end
else
    nans = 0;
    %fprintf('\n');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Locate and flag greater than max values
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

idum = find(x > xmax);
maxs = length(idum);
FLAG(idum) = 0; %sets flag value to 0 if x is greater than max allowed
%fprintf('%-5s%2.0f',' ... # >max =',maxs);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Locate and flag less than min values
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

idum = find(x < xmin);
mins = length(idum);
FLAG(idum) = 0; %sets flag value to 0 if x is less than min allowed
%fprintf('%-5s%2.0f',' ... # <min =',mins);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Locate and flag spikes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

delta_x = zeros(1,length(x)); %open an empty vector to fill with delta x's

for i = 2:length(x) % open a loop for that half hour
    delta_x(i-1) = x(i) - x(i-1); %calculate the change in x for successive time periods
end

idum = find(abs(delta_x) > nstds * std(delta_x));
test = find(abs(delta_x(idum + 1)) > nstds * std(delta_x));
uptonow = length(FLAG(find(FLAG ~= 1)));
FLAG(idum(test)+1) = 0;
std_delta_x = std(delta_x);

if std(delta_x(find(FLAG == 1))) < 0.8 * std_delta_x
    while std(delta_x(find(FLAG == 1))) < std_delta_x
        std_delta_x = std(delta_x(find(FLAG == 1)));
        idum = find(abs(delta_x(find(FLAG == 1))) > nstds * std(delta_x(find(FLAG == 1))));
        test = find(abs(delta_x(idum + 1)) > nstds * std(delta_x));
        FLAG(idum(test)+1) = 0;
        sum(FLAG);
    end
else
end

spikes = length(FLAG(find(FLAG ~= 1))) - uptonow;
%fprintf('%-5s%2.0f',' ... # spikes = ',spikes);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Locate windows with unacceptable variance
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if var == 1 || var == 2
    
        stdbin = [];

        for i = 1:floor(length(x)/500)
            if i == 1
                startbin = 1;
            elseif i >= 2
                startbin = (i - 1)*500;
            end
            endbin = 500 + startbin;
            stdbin(i) = std(delta_x(startbin:endbin));
        end

        idum = find(stdbin > 6 * mean(stdbin));

        if length(idum) == 1
            FLAG(1:500) = 0;
        elseif length(idum) > 1
            if idum(1) == 1
                FLAG(1:500) = 0;
                for i = 2:length(idum)
                    FLAG(((idum(i) - 1)*500):(500 + (idum(i) - 1)*500)) = 0;
                end
            elseif idum(1) ~= 1
                for i = 1:length(idum)
                    FLAG(((idum(i) - 1)*500):(500 + (idum(i) - 1)*500)) = 0;
                end        
            end
        end

        badvariance = 500*length(idum);
        %fprintf('%-5s%2.0f',' ... # w/ bad variance = ',badvariance);
else
end

if var == 1
    removed = [nans, maxs, mins, spikes, badvariance];
else
    removed = [nans, maxs, mins, spikes];
end

%fprintf('%-5s%2.0f',' ... Total removed =',length(find(~FLAG))); fprintf('\n');
