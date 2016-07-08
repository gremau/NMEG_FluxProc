function [UVW2,UVWMEANROT,UVWTVAR,COVUVWT,USTAR,HBUOYANT,TRANSPORT,hsout]=UNM_csat3_rot(uvwt,SONDIAG,sitecode,rotation)
% processes the measured SONIC outputs from the campbell CSAT 3 (half-hourly data)
%
% INPUTS:
%
% uvwt - NX4 array
%    ROW 1: measured sonic u component
%    ROW 2: measured sonic v component
%    ROW 3: measured sonic w component
%    ROW 4: measured sonic t component
% diagson- sonic diagnostics
% sitecode 
% rotation - 0 for 3d, 1 for planar

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% OUTPUTS: 
%
% UVW2 -NX3 array 
%    for 3D rotation option- rotated sonic components such that mean(v) = mean(w) = 0
%    ROW 1: sonic component rotated into the mean wind direction
%    ROW 2: sonic cross-wind component
%    ROW 3: sonic w component
%    for planar rotation option, NOT rotated
%
% SONDIAG - NX1 -diagnostic vector for sonic for each sample contains a 1 if the 
%    measurement was good or a 0 if there was a spike
%
% UVWTMEAN - 4X1 - mean values for (despiked) sonic measurements in measured (not rotated) coordinates
%    ROW 1: mean measured u component
%    ROW 2: mean measured v component
%    ROW 3: mean measured w component
%    ROW 4: mean measured sonic temperature
%
% THETA: - 1X1 - meteorological mean wind angle - it is the compass angle in degrees that 
%        the wind is blowing FROM (0 = North, 90 = east, etc)
%
% UVWTVAR - 4X1 -  variances of ROTATED wind components and the sonic temperature
%    ROW 1: along-wind velocity variance
%    ROW 2: cross-wind velocity variance
%    ROW 3: vertical-wind velocity variance
%    ROW 4: sonic temperature variance
%
% COVUVWT - 6X1 - covariances of ROTATED wind components and the sonic temperature
%    ROW 1: uw co-variance
%    ROW 2: vw co-variance
%    ROW 3: uv co-variance
%    ROW 4: ut co-variance
%    ROW 5: vt co-variance
%    ROW 6: wt co-variance
%
% USTAR - NX1 friction velocity (m/s)  (based on rotated)
%
% if nargin<4 
%     
%     rotation='double';
%     
% elseif isempty(rotation)
%     
%     rotation='double';
%     params=[];
% end

% Pretty sure this is deprecated (its not called by any other functions)
% - see UNM_csat3.m
error('This function is deprecated!');

    % calculate statistics that require all channels are despiked
    % rotate the measured wind vector. 
    % need to rotate
    % if findstr(rotation,'double')
    
    wantfigs=0; %change to 1 to view figures 
    if wantfigs==1;
        figure(1);clf

        subplot(321)
        plot(UVWROT(:,find(SONDIAG))');
        set(gca,'xlim',[0 size(UVWROT,2)]);
        title('U (bl), V (gr), W (r)')

        subplot(522)
        plot(uvwt(4,find(SONDIAG))');
        set(gca,'xlim',[0 size(UVWROT,2)]);
        title(['Ts']);
        drawnow
    else
    end

return
