function coeff = regress_GLand_2011_SWC_probes( data, varargin )
% REGRESS_GLAND_2011_SWC_PROBES - calculates regression equations for burned
% grass soil water probes for 2011.
%
% calculates a regression for echo soil water content probes as a linear
% function of CS616 swc probes for the period in 2011 when GLand had both types
% of probes (after June).  This allows the echo probes to be adjusted for May
% 2010 to June 2011 when there were no CS616 probes at GLand.
%
% USAGE
%    coeff = regress_GLand_2011_SWC_probes( data )
%    coeff = regress_GLand_2011_SWC_probes( data, draw_plots )
%
% INPUTS
%    data: matlab datset array containing the 2011 GLand Fluxall data with
%        columns relabeled descriptively (UNM_assign_soil_data_labels)
%    draw_plots: optional; draw some diagnostic plots if true 
%
% OUTPUTS
%    coeff: slope and intercept of linear regression
%
% SEE ALSO
%    dataset
% 
% author: Timothy W. Hilton, UNM, Sep 2012

% -----
% define optional inputs, with defaults and typechecking
% -----
args = inputParser;
args.addRequired( 'data',  @(x) isa( x, 'dataset' ) );
args.addParamValue( 'draw_plots', true, @islogical );

% parse optional inputs
args.parse( data, varargin{ : } );
%-----

[ echo_varnames, echo_idx ] = regexp_header_vars( data, '^echo.*' );
cs616_varnames = strrep( echo_varnames, 'echoSWC_', 'cs616SWC_' );
cs616_varnames = strrep( cs616_varnames, '_Avg', '' );
Tsoil_varnames = strrep( cs616_varnames, 'cs616SWC_', 'soilT_' );

echo_data = double( data( :, echo_varnames ) );
%echo_data = reshape( echo_data, [], 1 );

cs616_data = double( data( :, cs616_varnames ) );
orig_size = size( cs616_data );
%cs616_data = reshape( cs616_data, [], 1 );

Tsoil_data = double( data( :, cs616_varnames ) );
%Tsoil_data = reshape( Tsoil_data, [], 1 );

cs616_data = cs616_period2vwc( double( cs616_data ), ...
                               double( Tsoil_data ), ...
                               'draw_plots', false );

coeff = repmat( NaN, size( echo_data, 2 ), 2 );

for i = 1:size( echo_data, 2 )
    linear = 1;  % degree of polynomial to fit
    valid_idx = ( not( isnan( cs616_data( :, i ) ) ) & ...
                  not( isnan( echo_data( :, i ) ) ) );
    coeff( i, : ) = polyfit( echo_data( valid_idx, i ), ...
                             cs616_data( valid_idx, i ), ...
                             linear );
end

if args.Results.draw_plots

    pal = cbrewer( 'qual', 'Dark2', 3 );
    
    echo_data = reshape( echo_data, orig_size );
    cs616_data = reshape( cs616_data, orig_size );

    figure();
    plot( echo_data, cs616_data, '.' );

    echo_data_adj = ( echo_data * coeff( i, 1 ) ) + coeff( i, 2 );

    for i = 1:size( echo_data, 2 ) 
        h = figure();
        h_echo = plot( echo_data( :, i ), 'Marker', 's', 'Color', pal( 1, : ) );
        hold on;
        h_echo_adj = plot( echo_data_adj( :, i ), 'Marker', '+', ...
                           'Color', pal( 3, : )  );
        h_cs616 = plot( cs616_data( :, i ), 'Marker', '.', 'Color', ...
                        pal( 2, : ) );
        legend( [ h_echo, h_echo_adj, h_cs616 ], ...
                { 'echo', 'echo adj.', 'CS616' } );
        title( strrep( echo_varnames( i ), '_', '\_' ) );
        waitfor( h );
    end
end
