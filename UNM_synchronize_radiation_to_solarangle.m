function [ QC, fgf ] = ...
    UNM_synchronize_radiation_to_solarangle( sitecode, year, ...
                                             QC, fgf, timestamp )
% UNM_SYNCHRONIZE_RADIATION_TO_SOLARANGLE - adjust timestamps of parsed
% fluxall_QC and for-gapfiller (fgf) data so that observed sunrise (as
% deterimined by Rg or PAR) corresponds to calculated solar angle for each day
% of a calendar year.
%
% This seems like a good idea in concept, but in practice seems to increase
% errors about as frequently as it reduces errors.  I am therefore consigning
% this code to the repository historical record as of Aug 2013 -- TWH
%
% Uses match_solarangle_radiation to determine the optimal offset to make the
% daily cycle of Rg most closely match the daily cycle of calculated solar angle
% for each day of a year, and applies these shifts to each day using shift_data.
% Where Rg is used for fgf data, PAR for QC data.
%
% USAGE
%    [ data ] = ...
%       UNM_synchronize_radiation_to_solarangle( sitecode, ...
%                                                year, ...
%                                                QC, ...
%                                                fgf, ...
%                                                timestamp );
%
% INPUTS
%     sitecode: UNM_sites object; specifies the site
%     year: four digit year: specifies the year
%     QC: NxM dataset array; parsed fluxall QC data.  Must contain a variable
%         "Par_Avg" 
%     fgf: NxL dataset array; parsed fluxall QC data.  Must contain a variable
%         "Rg".  Typically the output of parse_forgapfilling_file.
%     timestamp: 1xN serial datenumber vector; timestamps for fgf and QC
%
% OUTPUTS
%     QC, fgf: NxM dataset arrays; input arguments, with the timestamps shifted
%         as described above.
%
% SEE ALSO
%     UNM_sites, dataset, datenum, UNM_parse_QC_txt_file,
%     UNM_parse_QC_txt_file, match_solarangle_radiation, shift_data
%
% author: Timothy W. Hilton, UNM, May 2013

debug = true;  % if true, draw some diagnostic plots

sol_ang = get_solar_elevation( sitecode, timestamp );

n_days = 365;
if isleapyear( year )
    n_days = 366;
end

opt_off_Rg = repmat( NaN, 1, numel( 1:n_days ) );
opt_off_PAR = repmat( NaN, 1, numel( 1:n_days ) );
for doy = 1:n_days
    debug_flag = false;
    opt_off_Rg( doy ) = match_solarangle_radiation( fgf.Rg, ...
                                                    sol_ang, ...
                                                    timestamp, ...
                                                    doy, year, debug_flag );
    opt_off_PAR( doy ) = match_solarangle_radiation( QC.Par_Avg, ...
                                                     sol_ang, ...
                                                     timestamp, ...
                                                     doy, year, debug_flag );
end

if debug
    DTIME = timestamp - datenum( year, 1, 0 );
    plot_fingerprint( DTIME, ...
                      QC.sw_incoming, ...
                      'Rg before', ...
                      'clim', [ 0, 20 ] );
    figure();
    plot( 1:n_days, opt_off_Rg, '.' );
    xlabel( 'DOY' );
    ylabel( 'Rg offset, 0.5 hours' );
end

% use Rg-based offset where available, fill in with PAR
opt_off = opt_off_Rg;
idx = isnan( opt_off );
opt_off( idx ) = opt_off_PAR( idx );

% convert QC, fgf to double arrays to apply the shift
QC_names = QC.Properties.VarNames;
fgf_names = fgf.Properties.VarNames;
QC = double( QC );
fgf = double( fgf );

% use run length encoding to gather consecutive days with the same radiation
% offset
idx_rle = rle( opt_off );
% the cumulative sums of the indices of the beginning of each change in
% radiation offset provides the DOY that each period of equal offset (i.e.,
% "chunk") begins
DOY_chunk_start = cumsum( idx_rle{ 2 } );
chunk_ndays = idx_rle{ 2 };
chunk_offset = idx_rle{ 1 };
data_nrow = size( QC, 1 );
for i = 1:numel( chunk_offset )
    if not( isnan( chunk_offset( i ) ) )
        idx0 = DOYidx( DOY_chunk_start( i ) );
        idx1 = DOYidx( DOY_chunk_start( i ) + chunk_ndays( i ) );
        if ( ( idx0 > 0 ) & ( idx0 <= data_nrow ) & ...
             ( idx1 > 0 ) & ( idx1 <= data_nrow ) )
            QC( idx0:idx1, : ) = shift_data( QC( idx0:idx1, : ), ...
                                             chunk_offset( i ), ...
                                             'cols_to_shift', ...
                                             1:size( QC, 2 ) );
            fgf( idx0:idx1, : ) = shift_data( fgf( idx0:idx1, : ), ...
                                              chunk_offset( i ), ...
                                              'cols_to_shift', ...
                                              1:size( fgf, 2 ) );
        end
    end
end

% convert the shifted arrays back to dataset arrays
QC = dataset( { QC, QC_names{ : } } );
fgf = dataset( { fgf, fgf_names{ : } } );

if debug
    plot_fingerprint( DTIME, ...
                      QC.sw_incoming, ...
                      'Rg after', ...
                      'clim', [ 0, 20 ] );
end

