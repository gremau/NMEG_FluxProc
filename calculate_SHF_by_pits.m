function SHF_with_storage = calculate_SHF_by_pits( soilT, ...
                                                  VWC, ...
                                                  SHF_pars, ...
                                                  SHF, ...
                                                  SHF_conv_factor )
% CALCULATE_SHF_BY_PITS - calculates soil heat flux (SHF) with storage at
% multiple pits.  The pits described in soilT and VWC (determined from column
% names; see requirements in INPUTS, below.
%   
% USAGE:
% SHF_with_storage = calculate_SHF_by_pits( soilT, ...
%                                           VWC, ...
%                                           SHF_pars, ...
%                                           SHF, ...
%                                           SHF_conv_factor )
%
% INPUTS:
%    soilT: dataset; one column per soil temperature observation.  Variables
%         must be named with format obs_cover_idx_depth_*, where obs is the
%         measurement (e.g. 'soilT' ), cover is the cover type ('open',
%         'pinon', etc.), depth is the depth in cm (2p5, 12p5, etc.), and * is
%         arbitrary text.
%    VWC: dataset; variable names formatted same as soilT (except obs will be
%         different).
%    SHF_pars: structure; Contains parameters for calculating SHF.  Must have
%         fields wcap, scap, bulk, depth.  Output of define_SHF_pars.
%    SHF: double vector; soil heat flux plate observation.
%    SHF_conv_factor: double scalar: Constant multiplier to convert SHF from
%         mV to W / m2.
%
% OUTPUTS:
%    SHF_with_storage: dataset; soil heat flux including storage calculated
%    for each pit in soilT and VWC.
%
% SEE ALSO
%    dataset
%
% (c) Timothy W. Hilton, UNM, April 2012

soilT_vars = regexp( soilT.Properties.VarNames, '_', 'split' );
soilT_vars = vertcat( soilT_vars{ : } ); 
covers = unique( soilT_vars( :, 2 ) );  %cover is 2nd '_'-delimited field
idx = unique( soilT_vars( :, 3 ) );     %pit idx is 3rd '_'-delimited field
depths = unique( soilT_vars( :, 4 ) );  %depth is 4th '_'-delimited field

VWC_vars = regexp( VWC.Properties.VarNames, '_', 'split' );
VWC_vars = vertcat( VWC_vars{ : } ); 
VWC_covers = unique( VWC_vars( :, 2 ) );  %cover is 2nd '_'-delimited field
VWC_idx = unique( VWC_vars( :, 3 ) );     %pit idx is 3rd '_'-delimited field
VWC_depths = unique( VWC_vars( :, 4 ) );  %depth is 4th '_'-delimited field

% make sure soilT, VWC describe same set of pits
if ( ~all( strcmp( covers, VWC_covers ) )  | ...
     ~all( strcmp( idx, VWC_idx ) ) | ...
     ~all( strcmp( depths, VWC_depths ) ) )
    error( 'soilT and VWC must contain same pit descriptors' );
end

% create containers for output -- one output for each pit
%    variable names
SHF_vars = cell( 1, numel( covers) * numel( idx ) ); 
%    SHF values
SHF_with_storage = repmat( NaN, ...
                           size( soil_data, 1 ), ...
                           numel( SHF_vars ) );

% format inputs into matrices that may be multiplied together element-wise
soilT = double( soilT );
VWC = double( VWC );
deltaT = vertcat( repmat( NaN, 1, size( soilT, 2 ) ), ...
                  diff( soilT ) );
% to make legal matlab variable names decimal points are replaced with 'p's
% (2.5 becomes 2p5).  determine the depth of each pit as a double.
depth = soilT_vars( :, 4 );
depth = str2double( regexprep( depths, '([0-9])p([0-9])', '$1.$2' ) );
depth_m = depth / 100.0;
% depth is now a row vector of depths in meters - repeat depths at each
% timestamp
depth_m = repmat( depth_m, size( soilT, 1 ), 1 );

% calculate one heat flux per pit (i.e. cover-idx pair).
count = 1;
for this_cov = 1:numel( covers )
    for this_idx = 1:numel( idx )           

        cv = ( SHF_pars.bulk_density .* SHF_pars.scap ) + ...
             ( SHF_vars.wcap .* VWC );
        storage_J = delta_T .* cv .* depth_m;  %% storage [ J ]
        storage_wm2 = storage_J / ( 60 * 30 ); %% storage [ W / m2 ]

        SHF_vars{ count } = sprintf( '%s_%s', ...
                                     covers{ this_cov }, ...
                                     idx{ this_idx } );
        count = count + 1;
    end
end

% convert soil heat fluxes to W / m2
shf_wm2 = shf * shf_conv_factor;



avg_soil_data = dataset( { avg_soil_data, avg_soil_data_vars{ : } } );



