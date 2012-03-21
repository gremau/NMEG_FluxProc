function hf_out = calculate_heat_flux( TCAV_Avg, ...
                                       swc_25mm,...
                                       bulk_density, ...
                                       scap, ...
                                       wcap, ...
                                       depth,...
                                       shf, ...
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
%   shf_ds: N x 1 matrix; soil heat flux measurements for one pit; [ mV ]
%   shf_conv_factor: 1 x M matrix; conversion factors to convert soil heat
%   fluxes from mV to  W / m2.  [ W / m2 / mV ]
%
% OUTPUTS:
%    hf: N x M dataset; total heat flux.  Has same column labels and order as
%        shf input; [ W / m2 ]
%
% (c) Timothy W. Hilton, UNM, Dec 2011

nrow = size( TCAV_Avg, 1 );

% now to the actual heat flux calculation
delta_T = [ NaN; diff( TCAV_Avg ) ];

% convert soil heat fluxes to W / m2
shf_wm2 = shf .* repmat( shf_conv_factor, nrow, 1 );

cv = ( bulk_density .* scap ) + ( wcap .* swc_25mm );
storage_J = delta_T .* cv .* depth;  %% storage [ J ]
storage_wm2 = storage_J / ( 60 * 30 );   %% storage [ W / m2 ]

hf_out = shf_wm2 + storage_wm2;






