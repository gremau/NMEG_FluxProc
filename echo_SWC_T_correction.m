function VWC_Tc = echo_SWC_T_correction( VWC, T, pcp, tstamp )
% ECHO_SWC_T_CORRECTION - Implements the temperature correction method for ECH2O
%   soil water probes described in the Decagon Devices application note entitled
%   "Correcting temperature sensitivity of ECHO soil moisture sensors", by Doug
%   Cobos and Colin Campbell of Decagon Devices.
%
% USAGE
%     VWC_Tc = echo_SWC_T_correction( VWC, T, pcp)
%
% INPUTS
%     VWC: Nx1 numeric; non T-corrected ECHO volumetric water content
%     T: Nx1 numeric; soil temperature (co-located with ECHO probe)
%     pcp: Nx1 numeric; precipitation
%     tstamp: Nx1 numeric; time stamp in decimal day of year
%
% OUTPUTS
%     VWC_Tc: temperature-corrected volumetric water content
%
% (c) Timothy W. Hilton, UNM, Sep 2012

% identify 24-hour periods with no precipitation
int_day = floor( tstamp );
daily_pcp = accumarray( int_day, pcp );  %daily total pcp
pcp_idx = ismember( int_day, find( daily_pcp > 0 ) ); 

VWC( pcp_idx ) = NaN;

% set idx to true at each midnight
idx = ( tstamp - floor( tstamp ) ) < 1e-6;
% set idx to true at the last timestamp before midnight of a day containing pcp
idx( find( diff( pcp_idx ) == 1 ) ) = true;
% don't interpolate missing VWC observations
idx( isnan( VWC ) ) = false;
tstamp( isnan( VWC ) ) = NaN;

VWC_interp = interp1( tstamp( idx ), VWC( idx ), tstamp, 'linear' );

coeff = glmfit( [ VWC, T ], VWC_interp, 'normal' );
VWC_Tc = glmval( coeff, [ VWC, T ], 'identity' );

result = echo_T_correct_debug_plot( tstamp, VWC, VWC_interp, ...
                                    idx, int_day, pcp_idx, VWC_Tc, T)


%------------------------------------------------------------
function result = echo_T_correct_debug_plot( tstamp, VWC, VWC_interp, ...
                                             idx, int_day, pcp_idx, VWC_Tc, ...
                                             Tsoil )
% ECHO_T_CORRECT_DEBUG_PLOT - plots out the interpolation in 24-hour periods of
% the observed VWC data.  Helper function for echo_SWC_T_correction.  Returns
% handle to figure on success, -1 on failure.
%   

result = -1;

hf = figure();
ax1 = subplot( 4, 1, 1 );
h1 = plot( tstamp, VWC, '.k' );
hold on;
h2 = plot( tstamp, VWC_interp, '.r', 'MarkerSize', 3 );
h3 = plot( tstamp( idx ), VWC_interp( idx ), '*r' );
legend( [ h1, h2, h3 ], ...
        { 'VWC (obs)', 'VWC (interp)', 'interp endpoints' }, ...
        'Location', 'best' );
xlabel( 'Day of year' );
ylabel( 'VWC' );

ax2 = subplot( 4, 1, 2 );
h1 = plot( tstamp, VWC, '.k' );
hold on;
h2 = plot( tstamp, VWC_Tc, '-r' );
legend( [ h1, h2 ], ...
        { 'VWC (obs)', 'VWC (T-corrected)' }, ...
        'Location', 'best' );
xlabel( 'Day of year' );
ylabel( 'VWC' );

ax3 = subplot( 4, 1, 3 );
h1 = plot( int_day, pcp_idx, '.' );
legend( h1, '1: pcp; 0: no pcp', 'Location', 'best' );
xlabel( 'day of year' );

ax4 = subplot( 4, 1, 4 );
h1 = plot( tstamp, Tsoil, '.' );
legend( h1, 'Tsoil', 'Location', 'best' );
xlabel( 'day of year' );

linkaxes( [ ax1, ax2, ax3, ax4 ], 'x' );


result = hf;