function SHF_with_storage = calculate_heat_flux( TCAV_Avg, ...
                                                 VWC, ...
                                                 SHF_pars, ...
                                                 SHF, ...
                                                 SHF_conv_factor )
% CALCULATE_HEAT_FLUX - calculates total soil heat flux by adding storage term
% to flux measured by plate.
% 
% USAGE:
%
%    SHF_with_storage = calculate_heat_flux( TCAV_Avg, ...
%                                                     VWC, ...
%                                                     SHF_pars, ...
%                                                     SHF, ...
%                                                     SHF_conv_factor )
%   
% INPUTS:
%
%   TCAV_Avg: N x M matrix; soil temperature measurement from TCAV; [ C ]
%   VWC: N x M matrix; soil volumetric water content
%   SHF_pars: structure with fields scap, wcap, depth, bulk
%   SHF: N x M matrix; soil heat flux measurements for one pit; [ mV ]
%   SHF_conv_factor: 1 x M matrix; conversion factors to convert soil heat
%       fluxes from mV to  W / m2.  [ W / m2 / mV ]
%
%   M is the number of [heat flux plate - TCAV] pairs
%
% OUTPUTS:
%
%    SHF_with_storage: N x M dataset; heat flux plus storage.  Has same column
%        labels and order as shf input; [ W / m2 ]
%
% (c) Timothy W. Hilton, UNM, Dec 2011

nrow = size( TCAV_Avg, 1 );

% now to the actual heat flux calculation
delta_T = [ NaN; diff( TCAV_Avg ) ];

% convert soil heat fluxes to W / m2
SHF_wm2 = SHF .* repmat( shf_conv_factor, nrow, 1 );

cv = ( SHF_pars.bulk .* SHF_pars.scap ) + ( SHF_pars.wcap .* swc );
storage_J = delta_T .* cv .* SHF_pars.depth;  %% storage [ J ]
storage_wm2 = storage_J / ( 60 * 30 );   %% storage [ W / m2 ]

shf_with_storage = shf_wm2 + storage_wm2;






