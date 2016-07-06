function flux_gC = umolPerSecPerM2_2_gcPerMSq( flux, varargin )
% UMOLPERSECPERM2_2_GCPERMSQ - calculate carbon flux in [ g / m2 / time
% interval ] from flux in [ umol/m2/sec ].  
%
% Default time interval is 30 minutes.
%   
% INPUTS
%    flux: array of CO2 flux values in umol / m2 / sec
% PARAMETER-VALUE PAIRS
%    delta_t: numeric; time interval of the NEE observations in minutes.
%        Default is 30.
%
% OUTPUTS
%    NEE_gC: flux converted to grams carbon per meter squared per time
%        interval.
%
% author: Timothy W. Hilton, UNM, May 2012

% parse user arguments
args = inputParser;
args.addRequired( 'flux', @isnumeric); 
args.addOptional( 'delta_t', 30, @isnumeric );
args.parse( flux, varargin{ : } );

mw_C = 12.0107;  %molecular weight of carbon, grams per mole
n_sec = 60 * args.Results.delta_t; % number of seconds in the time interval
umol_per_mol = 1e-6;  % micromoles per mole

flux_gC = args.Results.flux * mw_C * n_sec * umol_per_mol;


