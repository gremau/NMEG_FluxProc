function varargout =  UNM_gapfill_from_local_data( sitecode, ...
                                                   year, ...
                                                   ds_for_gapfill )
% UNM_GAPFILL_FROM_LOCAL_DATA - Performs gapfilling for specified sites and date
% ranges from other UNM sites.  
%
% This is intended to address periods where the online gapfiller produces poor
% modeled fluxes and we believe that filling in from other UNM sites will
% perform better.  The first output variable contains the indices at the
% specified site-year where we wish to override the online gapfiller.  The
% second (optional) output contains the input data with the data from the nearby
% UNM site added.  This needs to be run twice -- once in UNM_RemoveBadData to
% actually replace the data prior to gapfilling, and once in
% UNM_Ameriflux_file_builder to set the "filled" flags to filled.
%
% USAGE
% [ idx_filled ] = UNM_gapfill_from_local_data( sitecode, ...
%                                               year, ...
%                                               ds_for_gapfill )
% [ idx_filled, ds_for_gapfill ] = UNM_gapfill_from_local_data( sitecode, ...
%                                                               year, ...
%                                                               ds_for_gapfill )
% INPUTS
%    sitecode: UNM_sites object; specifies the site to show
%    year: four-digit year: specifies the year to show
%    ds_for_gapfill: NxM dataset array; the data (for the gapfiller) to be
%        "pre-filled" 
%
% OUTPUTS
%    idx_filled: 1xM logical array; true for timestamps in which filling was
%        performed 
%    ds_for_gapfill: dataset array (optional): the input data with filling
%        performed. 
%
% SEE ALSO
%    dataset

% author: Timothy W. Hilton, UNM, March 2012

obs_per_day = 48;

filled_idx = [];  %initialize to no gapfilling performed

%----------
% GLand 2010
if ( sitecode == 1 ) & ( year == 2010 )

    % GLand 2009 has a gap between DOY 295 and DOY 328 which the online
    % gapfiller fills poorly.  Fill with a linear regression using observed
    % NEE at New_GLand 2009 between DOY 280 and DOY 295.
    
    filled_idx = ( obs_per_day * 295 ) : ( obs_per_day * 328 );

    if nargout == 2
        regress_idx = [ (obs_per_day * 280 ) : ( obs_per_day * 295 ), ...
                        ( obs_per_day * 228 ) : ( obs_per_day * 238 ) ];

        newgland10 = parse_forgapfilling_file( 10, 2010 );
        regress_data = [ newgland10.NEE( regress_idx ), ...
                         ds_for_gapfill.NEE( regress_idx ) ];
        regress_data = replace_badvals( regress_data, [ -9999 ], 1e-6 );
        nan_idx = any( isnan( regress_data ), 2 );
        linfit = polyfit( regress_data( ~nan_idx, 1 ), ...
                          regress_data( ~nan_idx, 2 ), 1 );
        
        figure( 'NumberTitle', 'Off', ...
                'Name', 'GLand 2010 linear fit' );
        ax1 = subplot( 2, 1, 1 );
        plot( regress_data( ~nan_idx, 1 ), ...
              regress_data( ~nan_idx, 2 ), ...
              '.k' );
        h = refline( linfit );
        set( h , 'Color', 'blue' );
        xlabel( 'unburned gland 2010' );
        ylabel( 'burned gland 2010' );
        set( ax1, 'YLim', get( ax1, 'XLim' ) );

        newglandNEE = replace_badvals( double( newgland10.NEE( filled_idx ) ), ...
                                       [ -9999 ], 1e-6 );
        newglandNEE = ( newglandNEE * linfit( 1 ) ) +  linfit( 2 ) + 0.5;
        newglandNEE( isnan( newglandNEE ) ) = -9999.0;
        orig_gland_NEE = ds_for_gapfill.NEE;
        ds_for_gapfill.NEE( filled_idx ) = newglandNEE;

        ax2 = subplot( 2, 1, 2 );
        h_orig = plot( orig_gland_NEE, 'ok' );
        hold on;
        h_new = plot( filled_idx, ds_for_gapfill.NEE( filled_idx ), '.r' );
        ylim( [ -10, 10 ] );
        legend( [ h_orig, h_new ], 'original', 'linear fit' );
    end
end

if ( sitecode == 5 ) & ( year == 2012 )

    filled_idx = fix_PPine_2012_forgapfilling();
    
end
    
% %----------
% % JSav 2009
% if ( sitecode == 3 ) & ( year == 2009 )
%     % JSav has no flux data for roughly 1 Dec 2008 to 1 Mar 2009.  The
%     % gapfiller has trouble with this large gap at the beginning of 2009, so
%     % here we fill the first 21 days with JSav 2008 data.  Hopefully the
%     % gapfiller can "calibrate" from these data and produce a better fit for
%     % the remaining gap.
    
%     filled_idx = 1 : ( obs_per_day * 21 ); %first 21 days of the year

%     % if caller only requested the indices to be filled, don't bother
%     % processng the data
%     if nargout == 2
%         jsav08 = parse_forgapfilling_file( 3, 2008 );
%         % fill NEE, LE, and H for 1 to 21 Jan 2009 from 1 to 21 Jan 2008
%         ds_for_gapfill.NEE( filled_idx ) = jsav08.NEE( filled_idx );
%         ds_for_gapfill.qcNEE( filled_idx ) = ...
%             isnan( jsav08.NEE( filled_idx ) ) + 1; % 2 for bad data, 1 for good
%         ds_for_gapfill.LE( filled_idx ) = jsav08.LE( filled_idx );
%         ds_for_gapfill.H( filled_idx ) = jsav08.H( filled_idx );
%     end
% end

%----------
% create output arguments based on whether the user requested the filled 
if nargout <= 1
    varargout = { filled_idx };
elseif nargout == 2
    varargout = { filled_idx, ds_for_gapfill };
else
    error( 'too many output arguments' );
end