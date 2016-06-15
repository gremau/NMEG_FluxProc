function [ NR_sw, NR_lw, NR_tot ] = ...
    UNM_RBD_calculate_net_radiation( sitecode, year_arg, ...
                                     sw_incoming, sw_outgoing, ...
                                     lw_incoming, lw_outgoing, ...
                                     NR_tot, wnd_spd, decimal_day )
% CALCULATE_NET_RADIATION - calculate net radition from incoming and outgoing
% radiation.  
%
% This is a helper function for UNM_RemoveBadData.  It is not intended to be
% called on its own.  Input and output arguments are defined in
% UNM_RemoveBadData.
%   
% USAGE
%    [ NR_sw, NR_lw, NR_tot ] = ...
%      UNM_RBD_calculate_net_radiation( sitecode, year_arg, ...
%                                       sw_incoming, sw_outgoing, ...
%                                       lw_incoming, lw_outgoing, ...
%                                       NR_tot, wnd_spd, decimal_day );
%
% author: Timothy W. Hilton, UNM, 2013

% calculate new net radiation values
NR_lw = lw_incoming - lw_outgoing; % calculate new net long wave
NR_sw = sw_incoming - sw_outgoing; % calculate new net short wave

if ( sitecode == UNM_sites.PJ ) &  ( year_arg == 2008 ) 
    % calculate new net radiation values
    NR_tot(find(decimal_day > 171.5)) = NR_lw(find(decimal_day > 171.5)) + NR_sw(find(decimal_day > 171.5));    
    
elseif ( sitecode == UNM_sites.GLand ) & ( year_arg == 2007 )
    % this is the wind correction factor for the Q*7 used before ??/??
    % Not working - GEM
%     for i = 1:5766
%         if NR_tot(1) < 0
%             NR_tot(i) = NR_tot(i)*11.42*((0.00174*wnd_spd(i)) + 0.99755);
%         elseif NR_tot(1) > 0
%             NR_tot(i) = NR_tot(i)*8.99*(1 + (0.066*0.2*wnd_spd(i))/(0.066 + (0.2*wnd_spd(i))));
%         end
%     end
    % Its a little off compared to the later sensor, scale it
    NR_tot( 1:5766 ) = NR_tot( 1:5766 ) * 0.95 - 30;
    % Later sensor ok, recalculate NR_Tot
    NR_tot( (5767):end ) =  NR_lw( (5767):end ) + NR_sw( (5767):end );
    
elseif (sitecode == UNM_sites.SLand ) & ( year_arg == 2007 )
    % was this a Q*7 through the big change on 5/30/07? need updated
    % calibration
    % Not working - GEM
    may30 = 48 * ( datenum( 2007, 5, 30 ) - datenum( 2007, 1, 1 ) );
%     for i = 1:may30
%         %for i = 1:6816
%         if NR_tot(1) < 0
%             NR_tot(i) = NR_tot(i)*10.74*((0.00174*wnd_spd(i)) + 0.99755);
%         elseif NR_tot(1) > 0
%             NR_tot(i) = NR_tot(i)*8.65*(1 + (0.066*0.2*wnd_spd(i))/(0.066 + (0.2*wnd_spd(i))));
%         end
%     end
    % Its a little off compared to the later sensor, scale it
    NR_tot( 1:may30 ) = NR_tot( 1:may30 ) * 0.95 - 30;
    % Remove an outlier
    NR_tot( NR_tot( 1:may30 ) > 620 ) = nan;
    % Later sensor ok, recalculate NR_Tot
    NR_tot( (may30+1):end ) =  NR_lw( (may30+1):end ) + NR_sw( (may30+1):end );
    
else
    
    % all site-years but PJ 2007-08 and GLand 2007
    NR_tot = NR_lw + NR_sw;
end

% make sure net radiation is less than incoming shortwave
% added 13 May 2013 in response to problems noted by Bai Yang
NR_tot( NR_tot > sw_incoming ) = NaN;
