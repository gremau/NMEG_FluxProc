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
%       scap: heat capacity of dry soil [ J/(kg K) ]
%       wcap: heat capacity of moist soil [ J/(kg K) ]
%       depth: depth of heat flux plate [ m ]
%       bulk: bulk density of soil [ kg / m^3 ]
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



% -----
% calculate storage according to eqs 1, 3 in HFT3 heat flux plate manual.
% -----
rho_w = 1000;  % density of water, kg/m^3
Cw = 4.210 * 1000; % specific heat of water, J/(kg K)
% specific heat of moist soil, J/(m^3 K) -- HFT3 manual eq. 1 (page 5)
Cs = ( SHF_pars.bulk * SHF_pars.scap ) + ...
     ( VWC * rho_w * Cw ); 

delta_T = [ NaN; diff( TCAV_Avg ) ];

% storage -- HFT3 manual eq. 3 (page 5)
storage_J = delta_T .* Cs .* SHF_pars.depth;  %% storage [ J/m2 ]
storage_wm2 = storage_J / ( 60 * 30 );   %% storage [ W / m2 ]

% -----
% calculate heat flux plux storage
% -----

% convert soil heat fluxes to W / m2
SHF_wm2 = SHF .* repmat( SHF_conv_factor, nrow, 1 );

% heat flux plus storage -- HFT3 manual eq. 4 (page 5)
SHF_with_storage = shf_wm2 + storage_wm2;






