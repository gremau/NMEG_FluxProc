function swc = fill_soil_water_gaps( swc, pcp, draw_plots )
% FILL_SOIL_WATER_GAPS - fills gaps in soil water content time series.  Gaps are
% filled by linear interpolation where no precipitation occurred during the gap.
% Where precipitation occured during the gap, the last valid soil water content
% observation before the gap is filled forward to the beginning of the first
% precipitation event, and the first valid soil water content observation after
% the gap is filled backward to the end of the first precipitation event during
% the gap.  During the first preciptiation event soil water content is then
% filled by linear interpolation.  A precipitation event is defined to begin at
% the first detection of precipitation and end at the beginning of the first
% subsequent 1.5 hour period without precipitation.
%
% USAGE
%
% swc_filled = fill_soil_water_gaps( swc, pcp )
%
% INPUTS
%   swc: MxN numeric array; SWC data -- each column represents one probe
%   pcp: 1xN numeric array; precipitation observations
%
% OUTPUTS
%   swc_filled: MxN numeric array; swc input argument with gaps filled as
%       described above.
%
% (c) Timothy W. Hilton, UNM, Aug 2012

swc_dbl = double( swc );

pcp_yes_no = pcp > 0;
% use run length encoding to detect precip "events": periods containing no 
%  1.5 consecutive hour periods without pcp detected 
minutes_90 = 3; % data are half hourly; therefore three elements span 90 mins
pcp_runs = rle( pcp_yes_no );
idx = ( pcp_runs{ 1 } == false ) & ( pcp_runs{ 2 } <= minutes_90 );
pcp_runs{ 1 }( idx ) = true;
pcp_events = rle( pcp_runs );

nan_idx = isnan( swc_dbl );

for this_col = 1:size( swc_dbl, 2 )
    % if strcmp( swc.Properties.VarNames( this_col ), ...
    %            'cs616SWC_grass_1_12p5cm' )
    %     keyboard
    % end
    swc_dbl( :, this_col ) = fill_one_probe( swc_dbl( :, this_col ), ...
                                             pcp_events );
end

swc = replacedata( swc, swc_dbl );

if draw_plots
    plot_soil_pit_data( swc, nan_idx, pcp );
end
    
%-----------------------------------------------------------------
function swc_probe = fill_one_probe( swc_probe, pcp )
% fill a single soil water probe time series.  Helper function for
% fill_soil_water_gaps
%   
% INPUTS
%    swc_probe: 1xN numeric array; time series from one soil water content probe
%    pcp: 1xN numeric array; time series of precipitation data
%
% OUTPUTS
%    swc_probe: input data with gaps filled
%

if all( isnan( swc_probe ) )
    return
end

if isnan( swc_probe( 1 ) ) 
    leading_nans = 1:find( not( isnan( swc_probe ) ), 1, 'first' );
else
    leading_nans = [];
end
    
% find beginnign and end of all SWC gaps in the record
d_nan = diff( isnan( swc_probe ) );
gap_start = find( d_nan == 1 );
gap_end = find( d_nan == -1 );

% if the time series starts with NaNs ignore the first gap_end found
if ( gap_end( 1 ) < gap_start( 1 ) )
    gap_end = gap_end( 2:end );
end
    
% fill each gap
for i = 1:numel( gap_start )
    if ( i <= numel( gap_end ) )
        last_valid = swc_probe( gap_start( i ) );
        next_valid = swc_probe( gap_end( i ) + 1 );
        
        swc_probe( gap_start( i ):gap_end( i ) ) = ...
            fill_one_swc_gap( swc_probe( gap_start( i ):gap_end( i ) ), ...
                              pcp( gap_start( i ):gap_end( i ) ), ...
                              last_valid, ...
                              next_valid );
    end
end

swc_probe = inpaint_nans( swc_probe, 4 );

if not( isempty( leading_nans ) )
    swc_probe( leading_nans ) = NaN;
end

%--------------------------------------------------
function swc = fill_one_swc_gap( swc, pcp, last_valid, next_valid )
% FILL_ONE_SWC_GAP: fill a single gap in a soil water content probe time
% series.  Helper function for fill_one_probe.
%   
% INPUTS
%    swc: 1xN numeric array: data of NaNs representing a single gap in one SWC
%        probe record
%    pcp: 1xN numeric array: the pcp record corresponding to swc
%    last_valid: the value of that last valid SWC observation before the gap
%    next_vald: the value of that first valid SWC observation after the gap
%
% OUTPUTS
%    swc: input argument with the gap filled as described in the
%        documentation for fill_soil_water_gaps 

% find index beginning and end of first prepipitation event during the SWC gap.
if pcp( 1 ) == 1 
    pcp_start = 1;
else
    pcp_start = min( find( diff( pcp ) == 1 ) );
end

pcp_end = min( find( diff( pcp ) == -1 ) );

% if any pcp occured during the gap, place the most recent valid SWC observation
% in the slot corresponding to the beginning of precip, and the next valid SWC
% observation after the gap in the slot corresponding to the end of the first
% pcp event
if not( isempty( pcp_start ) )
    swc( pcp_start ) = last_valid;
end

if not( isempty( pcp_end ) )
    swc( pcp_end ) = next_valid;
end

