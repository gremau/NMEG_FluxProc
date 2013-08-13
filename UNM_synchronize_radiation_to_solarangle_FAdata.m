function [ data ] = ...
    UNM_synchronize_radiation_to_solarangle_FAdata( sitecode, ...
                                                  year, ...
                                                  data, ...
                                                  headertext, ...
                                                  timestamp )
% UNM_SYNCHRONIZE_RADIATION_TO_SOLARANGLE_FADATA - adjust timestamps of parsed
% FluxAll (FA) data so that observed sunrise (as deterimined by Rg or PAR)
% corresponds to calculated solar angle for each day of a calendar year.
%
% This seems like a good idea in concept, but in practice seems to increase
% errors about as frequently as it reduces errors.  I am therefore consigning
% this code to the repository historical record as of Aug 2013 -- TWH
%
% Uses match_solarangle_radiation to determine the optimal offset to make the
% daily cycle of Rg most closely match the daily cycle of calculated solar angle
% for each day of a year, and applies these shifts to each day using shift_data.
% Where Rg observations are not available but PAR observations are, PAR is used
% instead.
%
% Rg column within data is identified by searching for 'Rad_short_Up_Avg' or
% 'pyrr_incoming_Avg' within headertext.  PAR column is identified by searching
% for one of 'par_correct_Avg', 'par_Avg(1)', 'par_Avg_1', 'par_Avg',
% 'par_up_Avg', 'par_face_up_Avg', 'par_incoming_Avg', or 'par_lite_Avg'.
%
% USAGE
%    [ data ] = ...
%       UNM_synchronize_radiation_to_solarangle_FAdata( sitecode, ...
%                                                     year, ...
%                                                     data, ...
%                                                     headertext, ...
%                                                     timestamp );
%
% INPUTS
%     sitecode: UNM_sites object; specifies the site
%     year: four digit year: specifies the year
%     data: NxM numeric; a data array with observations in columns and time in
%         rows that includes Rg and PAR.  This would usually be a parsed fluxall
%         file.
%     headertext: cell array of strings; variable names for columns of data
%     timestamp: 1xN serial datenumber vector; timestamps for rows of data
%
% OUTPUTS
%     data: NxM numerical array; input argument data, with the timestamps
%         shifted as described above. 
%
% SEE ALSO
%     UNM_sites, datenum, match_solarangle_radiation, shift_data
%
% author: Timothy W. Hilton, UNM, May 2013


debug = true;  % if true, draw some diagnostic plots
save_figs = false;  % if true, save figures to eps files

% -----
% identify Rg and PAR columns from data
Rg_col = find( strcmp('Rad_short_Up_Avg', headertext) | ...
               strcmp('pyrr_incoming_Avg', headertext) ) - 1;

PAR_col = find( strcmp('par_correct_Avg', headertext )  | ...
                strcmp('par_Avg(1)', headertext ) | ...
                strcmp('par_Avg_1', headertext ) | ...
                strcmp('par_Avg', headertext ) | ...
                strcmp('par_up_Avg', headertext ) | ...        
                strcmp('par_face_up_Avg', headertext ) | ...
                strcmp('par_incoming_Avg', headertext ) | ...
                strcmp('par_lite_Avg', headertext ) ) - 1;

Rg = data( :, Rg_col );
PAR = data( :, PAR_col );
% -----

% calculate solar angle
sol_ang = get_solar_elevation( sitecode, timestamp );

% how many days are in this year?
n_days = 365 + isleapyear( year );

opt_off_Rg = repmat( NaN, 1, numel( 1:n_days ) );
opt_off_PAR = repmat( NaN, 1, numel( 1:n_days ) );
for doy = 1:n_days
    debug_flag = false;
    opt_off_Rg( doy ) = match_solarangle_radiation( Rg, ...
                                                    sol_ang, ...
                                                    timestamp, ...
                                                    doy, year, debug_flag );
    opt_off_PAR( doy ) = match_solarangle_radiation( PAR, ...
                                                     sol_ang, ...
                                                     timestamp, ...
                                                     doy, year, debug_flag );
end

if debug
    DTIME = timestamp - datenum( year, 1, 0 );
    [ hfig, ~ ] = plot_fingerprint( DTIME, ...
                                    data( :, Rg_col ), ...
                                    sprintf( '%s %d Rg before', ...
                                             char( sitecode ), year ), ...
                                    'clim', [ 0, 20 ], ...
                                    'fig_visible', true  );
    if save_figs
        figure_2_eps( hfig, ...
                      fullfile( getenv( 'PLOTS' ), 'Rad_Fingerprints', ...
                                sprintf( '%s_%d_Rg_before.eps', ...
                                         char( sitecode ), year ) ) );
    end
    hfig = figure( 'Visible', 'on' );
    plot( 1:n_days, opt_off_Rg, '.' );
    xlabel( 'DOY' );
    ylabel( 'Rg offset, hours' );
    if save_figs
        figure_2_eps( hfig, ...
                      fullfile( getenv( 'PLOTS' ), 'Rad_Fingerprints', ...
                                sprintf( '%s_%d_Rg_offset.eps', ...
                                         char( sitecode ), year ) ) );
    end
end

% use Rg-based offset where available, fill in with PAR
opt_off = opt_off_Rg;
idx = isnan( opt_off );
opt_off( idx ) = opt_off_PAR( idx );

% use run length encoding to gather consecutive days with the same radiation
% offset
idx_rle = rle( opt_off );
% the cumulative sums of the indices of the beginning of each change in
% radiation offset provides the DOY that each period of equal offset (i.e.,
% "chunk") begins
DOY_chunk_start = cumsum( idx_rle{ 2 } );
DOY_chunk_start = [ 1, DOY_chunk_start( 1:end-1 ) + 1 ];
chunk_ndays = idx_rle{ 2 };
chunk_offset = idx_rle{ 1 };
data_nrow = size( data, 1 );

%disp( [ DOY_chunk_start', chunk_ndays', chunk_offset' ] )

for i = 1:numel( chunk_offset )
    if not( isnan( chunk_offset( i ) ) )
        idx0 = DOYidx( DOY_chunk_start( i ) );
        idx1 = DOYidx( DOY_chunk_start( i ) + chunk_ndays( i ) );
        if ( ( idx0 > 0 ) & ( idx0 <= data_nrow ) & ...
             ( idx1 > 0 ) & ( idx1 <= data_nrow ) )
            data( idx0:idx1, : ) = shift_data( data( idx0:idx1, : ), ...
                                               chunk_offset( i ), ...
                                               'cols_to_shift', ...
                                               1:size( data, 2 ) );
        end
    end
end

if debug
    [ hfig, ~ ] = plot_fingerprint( DTIME, ...
                                    data( :, Rg_col ), ...
                                    sprintf( '%s %d Rg after', ...
                                             char( sitecode ), year ), ...
                                    'clim', [ 0, 20 ], ...
                                    'fig_visible', true );
    if save_figs
        figure_2_eps( hfig, ...
                      fullfile( getenv( 'PLOTS' ), 'Rad_Fingerprints', ...
                                sprintf( '%s_%d_Rg_after.eps', ...
                                         char( sitecode ), year ) ) );...
    end
end

