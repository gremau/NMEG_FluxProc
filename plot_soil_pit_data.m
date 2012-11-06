function [] = plot_soil_pit_data( soil_data, nan_idx_arg, pcp )
% PLOT_SOIL_PIT_DATA - produce pit-by-pit plots of soil data.  Variable
% labels must be in format VARIABLE_COVER_PIT_DEPTH_...
%   

grp_vars = regexp( soil_data.Properties.VarNames, '_', 'split' );
grp_vars = vertcat( grp_vars{ : } );

%pit is 3rd underscore-delimited field,
%cover is 2nd underscore-delimited field
if numel( grp_vars ) == 2
    idx = 1:2;
else
    idx = 2:3;
end
pits = unique( strcat( grp_vars( :, idx( 1 ) ), ...
                       '_', ...
                       grp_vars( :, idx( 2 ) ) ) );

for this_pit = 1:numel( pits )
    [ ~, idx ] = regexp_ds_vars( soil_data, pits( this_pit ) );
    
    nan_idx = nan_idx_arg( :, idx );
    
    h = figure();
    set( h, 'DefaultAxesColorOrder', ...
            cbrewer( 'qual', ...
                     'Dark2', ...
                     max( 3, numel( idx ) ) ) );

    h1 = subplot( 2, 1, 1 );
    plot( pcp, '.k' );
    
    h2 = subplot( 2, 1, 2 );
    this_data = double( soil_data( :, idx ) );
    this_data_filled = this_data;
    this_data( nan_idx ) = NaN;
    this_data_filled( ~nan_idx ) = NaN;
    
    plot_data = this_data;
    plot_data_filled = this_data_filled;
    plot_data_filled( ~nan_idx ) = NaN;
    
    h_probes = plot( plot_data, '.' );
    hold on;
    h_probes_filled = plot( plot_data_filled, 'o' );
    %set( h_probes_filled, 'LineWidth', 2 );
    
    leg_strs = soil_data.Properties.VarNames( idx );
    leg_strs = replace_hex_chars( leg_strs );
    leg_strs = regexprep( leg_strs, '_', '\\_' );

    legend( h_probes_filled, leg_strs, ...
            'location', 'best' );
    linkaxes( [ h1, h2 ], 'x' );
    waitfor( h );
end
