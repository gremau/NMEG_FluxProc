function hf = calculate_heat_flux( TCAV_Avg, ...
                                   swc_25mm,...
                                   bulk_density, ...
                                   scap, ...
                                   wcap, ...
                                   depth,...
                                   shf_ds, ...
                                   shf_conv_factor )
% CALCULATE_HEAT_FLUX - calculates total soil heat flux by adding storage term
% to flux measured by plate.
%   
% INPUTS:
%   TCAV_Avg: N x 1 matrix; soil temperature measurement from TCAV; [ C ]
%   swc_25mm: N x 1 matrix; soil water content at 25 mm
%   bulk_density; scalar, soil density (?); [ g / m2 ]?
%   scap: double; ?
%   wcap: double; ?
%   depth: depth for heat flux calculation; [ m ]
%   shf_ds: N x M dataset containing soil heat flux measurements, one column
%           per pit; [ mV ]
%   shf_conv_factor: 1 x M matrix; conversion factors to convert soil heat
%   fluxes from mV to  W / m2.  [ W / m2 / mV ]
%
% OUTPUTS:
%    hf: N x M dataset; total heat flux.  Has same column labels and order as
%        shf input; [ W / m2 ]
%
% (c) Timothy W. Hilton, UNM, Dec 2011

% how many timestamps are there (nrow) and how many separate heat flux
% observations are there (ncol)?
[ nrow, ncol ] = size( shf_ds );

% heat flux vars are named soil_heat_flux_xyz -- pull off the xyz suffix so
% we can name the output variables "SHF_xyz"
shf_vars = shf_ds.Properties.VarNames;
suf_idx = regexp( shf_vars, 'soil_heat_flux', 'end' );
suf = cellfun( @(str, idx) str( (idx + 1) : end ), ...
               shf_vars, suf_idx, ...
               'UniformOutput', false );
SHF_out_names = strcat( 'SHF', suf );

% now to the actual heat flux calculation
delta_T = [ NaN; diff( TCAV_Avg ) ];

% convert soil heat fluxes to W / m2
shf_wm2 = double( shf_ds ) .* repmat( shf_conv_factor, nrow, 1 );

cv = ( bulk_density .* scap ) + ( wcap .* swc_25mm );
storage_J = delta_T .* cv .* depth;  %% storage [ J ]
storage_wm2 = storage_J / ( 60 * 30 );   %% storage [ W / m2 ]

hf = shf_wm2 + repmat( storage_wm2, 1, ncol );

hf = dataset( { hf, SHF_out_names{:} } );




