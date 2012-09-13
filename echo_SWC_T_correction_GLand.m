function VWC_Tc = echo_SWC_T_correction( VWC, T, pcp, tstamp )
% ECHO_SWC_T_CORRECTION - 
%   

VWC_varnames = strrep( VWC.Properties.VarNames, 'echoSWC_', '' );
VWC_varnames = strrep( VWC_varnames, 'cm_Avg', '' );
T_varnames = strrep( T.Properties.VarNames, 'soilT_', '' );

%VWC_Tc = repmat( NaN, size( VWC ) );

for i = 1:size( VWC, 2 )
    Tcol = find( strcmp( VWC_varnames( i ), T_varnames ) );
    if not( isempty( Tcol ) )
        this_probe = ...
            echo_SWC_T_correction_single_probe( double( VWC( :, i ) ), ...
                                                double( T( :, Tcol ) ), ...
                                                pcp, ...
                                                tstamp,...
                                                VWC_varnames{ i } );
        
        corrected( :, i ) = this_probe;
    else
        corrected( :, i ) = NaN;
    end

end

VWC_Tc = replacedata( VWC, corrected );

%--------------------------------------------------
% function VWC_Tc = echo_SWC_T_correction( )
% % ECHO_SWC_T_CORRECTION - demonstrates the decagon application note example

% data = dlmread( 'ec5_T_Correction_example.csv' );
% VWC_interp = data( :, 3 );
% VWC_obs = data( :, 1 );
% T = data( :, 2 );
% pcp = zeros( size( T ) );
% tstamp =  1:(1/24):5;
% tstamp = tstamp( 1: numel( T ) )';
% t_str = 'Decagon application note example';

% VWC_Tc = echo_SWC_T_correction_single_probe( VWC_obs, T, pcp, tstamp, t_str )

%--------------------------------------------------
function VWC_Tc = echo_SWC_T_correction_single_probe( VWC, T, pcp, tstamp, t_str )
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

idx = find( isnan( tstamp ) );
VWC( idx ) = [];
T( idx ) = [];
pcp( idx ) = [];
tstamp( idx ) = [];

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

fprintf( '%s coefficients:', t_str); disp( coeff' );

result = echo_T_correct_debug_plot( tstamp, VWC, VWC_interp, ...
                                    idx, int_day, pcp_idx, VWC_Tc, T, t_str );
%waitfor( result );


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