function [ vwc, vwc_Tc ] = cs616_period2vwc( raw_swc, T_soil, varargin )
% CS616_PERIOD2VWC - apply Campbell Scientific CS616 conversion equation to
% convert cs616 period (in microseconds) to volumetric water content
% (fraction).  Returns temperature-corrected and non-temperature-corrected
% VWC. 
%
% USAGE:
%    [ vwc, vwc_Tc ] = cs616_period2vwc( raw_swc, T_soil )
%    [ vwc, vwc_Tc ] = cs616_period2vwc( raw_swc, T_soil, draw_plots )
% INPUTS:
%    raw_swc: N by M matrix of soil water content raw data (microseconds)
%    T_soil: N by 1 matrix of soil temperature (C -- check this TWH )
% OUTPUTS:
%    vwc: N by M matrix of non-temperature-corrected SWC
%    vwc_Tc: N by M matrix of temperature-corrected SWC
%
% (c) Timothy W. Hilton, UNM, Apr 2012


% -----
% define optional inputs, with defaults and typechecking
% -----
args = inputParser;
args.addRequired( 'raw_swc', @(x) isnumeric(x) | isa( x, 'dataset' ) );
args.addRequired( 'T_soil',  @(x) isnumeric(x) | isa( x, 'dataset' ) );
args.addParamValue( 'draw_plots', true, @islogical );
args.addParamValue( 'save_plots', false, @islogical );

% parse optional inputs
args.parse( raw_swc, T_soil, varargin{ : } );
raw_swc = args.Results.raw_swc;
T_soil = args.Results.T_soil;

% -----
% convert arguments to double arrays if they were provided as dataset objects
% -----
swc_is_ds = isa( raw_swc, 'dataset' );
if swc_is_ds
    raw_swc_input = raw_swc;
    raw_swc = double( raw_swc );
end

% make sure T_soil is an array of doubles
T_soil = double( T_soil );

% -----
% perform the conversion and temperature correction
% -----

% some fluxall files have echo SWC (already VWC) and cs616 SWC (cs616 period, in
% microseconds) in the same column.  Valid cs616 periods are larger than about
% 15 microseconds (see cs616 manual figure 4).  This is an approximate filter
% so that we don't apply the cs616 calibration to echo data.
is_cs616 = ( raw_swc > 14.0 );

% non-temperature corrected: apply quadratic form of calibration equation
% (section 6.3, p. 29, CS616 manual)
pd2vwc = @( pd ) repmat( -0.0663, size( pd ) ) - ...
         ( 0.0063 .* pd ) + ...
         ( 0.0007 .* ( pd .* pd ) );

vwc = raw_swc;
vwc( is_cs616 ) = pd2vwc( raw_swc( is_cs616 ) );

% perform temperature correction described in cs616 manual section 6.6 (p 33 )
cs616_period_Tcorrect = @( pd, T )  pd +  ( ( 20 - T ) .* ...
                                            ( 0.526 - ( 0.052 .* pd ) + ...
                                              ( 0.00136 .* pd .* pd ) ) );

vwc_Tc = raw_swc;
vwc_Tc( is_cs616 ) = cs616_period_Tcorrect( raw_swc( is_cs616 ), ...
                                            T_soil( is_cs616 ) );
vwc_Tc( is_cs616 ) = pd2vwc( vwc_Tc( is_cs616 ) );

% Remove any negative SWC values
vwc( vwc < 0 ) = nan;
vwc( vwc > 1 ) = nan;
vwc_Tc( vwc_Tc < 0 ) = nan;
vwc_Tc( vwc_Tc > 1 ) = nan;


% if inputs were datasets, keep the same variable names an replace the values
% with the VWC and T-corrected VWC
if swc_is_ds
    vwc = replacedata( raw_swc_input, vwc );
    vwc_Tc = replacedata( raw_swc_input, vwc_Tc );
end

if args.Results.draw_plots
    nrow = size( raw_swc, 1 );
    doy = ( 0:nrow-1 ) / 48;
    n_locations = size( raw_swc, 2 );  %how many measurment locations?
    
    for  i = 1:n_locations
        h = figure( 'Name', 'SWC T corrections', ...
                    'Units', 'Inches', ...
                    'Position', [ 0, 0, 8.5, 11 ] );
        ax = subplot( 4, 1, 1 );
        h_vwc = plot( doy, vwc( :, i ), '.b' );
        hold on
        h_vwc_tc = plot( doy, vwc_Tc( :, i ), 'ok' );
        cov_num_depth = regexp( raw_swc_input.Properties.VarNames{ i }, ...
                                '_', 'split' );
        cov_num_depth = sprintf( 'VWC\\_%s\\_%s\\_%s', ...
                                 cov_num_depth{ 2 }, ...
                                 cov_num_depth{ 3 }, ...
                                 cov_num_depth{ 4 } );
        cov_num_depth = regexprep( cov_num_depth, '([0-9])p([0-9])', '$1.$2' );
        ylabel( 'VWC' );
        legend( [ h_vwc, h_vwc_tc ], 'not corrected', 'T-corrected', ...
                'Location', 'best' );
        title( cov_num_depth );
        % % if all is well, all VWC values should be in range [0, 1].  Make the
        % % y-limits of the plot at least this big
        % y_lim = get( ax, 'YLim' );
        % if ( y_lim( 1 ) > 0 )
        %     y_lim( 1 )  = 0;
        % end
        % if ( y_lim( 2 ) < 1.0 )
        %     y_lim( 2 ) = 1.0;
        % end
        % set( ax, 'YLim', y_lim );
        
        subplot( 4, 1, 2 );
        plot( doy, ...
              double( vwc( :, i ) ) - double( vwc_Tc( :, i ) ), ...
              '.k' );
        ylabel( 'VWC - VWC\_Tc' );
        
        subplot( 4, 1, 3 );
        plot( doy, T_soil( :, i ), '.' );
        ylabel( 'Tsoil' );

        subplot( 4, 1, 4 );
        plot( doy, raw_swc( :, i ), '.' );
        ylabel( 'raw SWC' );
        xlabel( 'day of year' )
        
    end
end