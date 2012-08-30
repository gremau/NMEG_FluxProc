function Tsoil = fill_soil_temperature_gaps( Tsoil, pcp, draw_plots )
% FILL_SOIL_TEMPERATURE_GAPS - 
%   

Tsoil_dbl = double( Tsoil );
nan_idx = isnan( Tsoil_dbl );

interp_method = 4;
Tsoil_dbl = column_inpaint_nans( Tsoil_dbl, interp_method );

% locate gaps of more than five days and put NaNs back - linear interpolation
% doesn't do well in those cases
orig_size = size( Tsoil_dbl );
rle_idx = rle( reshape( double( nan_idx ), [], 1 ) );
five_days = 48 * 5;  % five days in units of 30-minute periods
five_day_gaps = find( ( rle_idx{ 1 } == 1 ) & ( rle_idx{ 2 } > five_days ) );
rle_idx{ 1 }( five_day_gaps ) = NaN;
nan_idx = isnan( reshape( rle( rle_idx ), orig_size ) );
Tsoil_dbl( nan_idx ) = NaN;

Tsoil = replacedata( Tsoil, Tsoil_dbl );

if draw_plots
    plot_soil_pit_data( Tsoil, ...
                        nan_idx, ...
                        pcp );
end