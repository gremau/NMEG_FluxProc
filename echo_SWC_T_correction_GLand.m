function VWC_Tc = echo_SWC_T_correction_GLand( VWC, T, pcp, tstamp, year, ...
                                               debug_plots )
% echo_SWC_T_correction_GLand: applies temperature correction for ECH2O soil
% water content probes installed at GLand between May 2010 and June 2011.
% For details of the temperature correction, see documentation for
% echo_SWC_T_correction_single_probe, below.
%   
% USAGE: 
%     VWC_Tc = echo_SWC_T_correction_GLand( VWC, T, pcp, tstamp, year, ...
%                                           debug_plots )
%
% INPUTS
%     VWC: NxM dataset array; the echo SWC probe data for M probes
%     T: NxM dataset array; the soil T data for M probes
%     pcp: N-element numeric or dataset arry; precipitation
%     tstamp: N-element numeric or dataset arry; observation timestamps as
%         matlab datenums
%     t_str: a labeling string for progress updates and plots, e.g. the probe ID
%     debug_plots: logical; if true, produce plots showing various terms in
%         the temperature correction.
%
% SEE ALSO
%    dataset
%
% (c) Timothy W. Hilton, UNM, Sep 2012

VWC_varnames = strrep( VWC.Properties.VarNames, 'cs616SWC_', '' );
VWC_varnames = strrep( VWC_varnames, 'cm', '' );
T_varnames = strrep( T.Properties.VarNames, 'soilT_', '' );

%corrected = repmat( NaN, size( VWC ) );
VWC_Tc = VWC;

% determine which rows (i.e. timestamps) need to be corrected
if year == 2011
    idx = repmat( false, size( tstamp ) );
    idx_9jun = DOYidx( datenum( 2011, 6, 9 ) - datenum( 2011, 1, 0 ) );
    idx( 1:idx_9jun ) = true;
    idx( isnan( tstamp ) ) = false;
    idx = find( idx );
    
elseif year == 2010
    idx = find( not( isnan( tstamp ) ) );
end

if isempty( idx )
    keyboard
end

for i = 1:size( VWC, 2 )

    Tcol = find( strcmp( VWC_varnames( i ), T_varnames ) );

    if not( isempty( Tcol ) )
        this_probe = ...
            echo_SWC_T_correction_single_probe( double( VWC( idx, i ) ), ...
                                                double( T( idx, Tcol ) ), ...
                                                pcp( idx ), ...
                                                tstamp( idx ),...
                                                VWC_varnames{ i }, ...
                                                debug_plots );
        
        VWC_Tc( idx, i ) = replacedata( VWC_Tc( idx, i ), this_probe );
    end
end

%--------------------------------------------------
function VWC_Tc = echo_SWC_T_correction_single_probe( VWC, T, pcp, ...
                                                  tstamp, t_str, ...
                                                  debug_plots )
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

fprintf( 'temperature correcting ECH2O soil water: %s\n', t_str );

if all( isnan( VWC ) )
    VWC_Tc = VWC;
    return
end

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

%keyboard
coeff = glmfit( [ VWC, T ], VWC_interp, 'normal' );
VWC_Tc = glmval( coeff, [ VWC, T ], 'identity' );

if debug_plots
    result = echo_T_correct_debug_plot( tstamp, VWC, VWC_interp, ...
                                        idx, int_day, pcp_idx, ...
                                        VWC_Tc, T, t_str );
    waitfor( result );
end



%------------------------------------------------------------
function result = echo_T_correct_debug_plot( tstamp, VWC, VWC_interp, ...
                                             idx, int_day, pcp_idx, VWC_Tc, ...
                                             Tsoil, t_str )
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
title( strrep( t_str, '_', '\_' ) );

ax2 = subplot( 4, 1, 2 );
h1 = plot( int_day, pcp_idx, '.' );
legend( h1, '1: pcp; 0: no pcp', 'Location', 'best' );
xlabel( 'day of year' );
ylabel( 'pcp yes/no' );

ax3 = subplot( 4, 1, 3 );
h1 = plot( tstamp, Tsoil, '.' );
legend( h1, 'Tsoil', 'Location', 'best' );
xlabel( 'day of year' );
ylabel( 'T soil' );

ax4 = subplot( 4, 1, 4 );
h1 = plot( tstamp, VWC, '.k' );
hold on;
h2 = plot( tstamp, VWC_Tc, '-r' );
h3 = plot( tstamp, VWC_interp, '-b' );
legend( [ h1, h2, h3 ], ...
        { 'VWC (obs)', 'VWC (T-corrected)', 'VWC (interp target)' }, ...
        'Location', 'best' );
xlabel( 'Day of year' );
ylabel( 'VWC' );

linkaxes( [ ax1, ax2, ax3, ax4 ], 'x' );

result = hf;