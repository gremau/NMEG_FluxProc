function hf_site = calculate_site_average_heat_flux(hf_by_cover)
% CALCULATE_SITE_AVERAGE_HEAT_FLUX - calculates average heat flux by ground cover type, and a site-wide average
%   
    
%   hf_by_cover: N x M dataset containing soil heat flux measurements.  Each
%        variable must be labeled in the format COVER_NUM_remainder, where COVER
%        is the cover type (e.g. grass, open, pinon, etc.) and NUM is the pit
%        number (integer).  remainder may be arbitrary text; Calculates average,
%        so units are irrelevant.
%
% SEE ALSO
%    dataset
%
% get unique cover types and their indices from the variable names
    pit_names = hf_by_cover.Properties.VarNames;
    cover_str = regexp( pit_names, '_', 'split' );
    cover_str = cellfun( @(x) x{ 1 }, cover_str, 'UniformOutput', false);
    [ cover_str, discard, cover_n ] = unique( hf_by_cover.Properties.VarNames );
    
    % create a matrix to hold the averaged values for each cover type, as
    % well as the site average
    hf_site = zeros( size( hf_by_cover, 1 ), length( cover_str ) + 1 );
    
    % calculate the means by cover type
    for i = 1:length( cover_str )
        idx = find( cover_n == i );
        hf_site( :, i ) = mean( double( hf_by_cover ), 1 );
    end
    
    % place the site-wide mean in the last column
    hf_site( :, end ) = mean( hf_site( :, end - 1 ), 1 );
    
    % turn the matrix of means into a dataset
    hf_site = dataset( { hf_site, cover_str{ : } } );
        
        