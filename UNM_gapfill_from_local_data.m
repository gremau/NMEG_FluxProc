function varargout =  UNM_gapfill_from_local_data( sitecode, ...
                                                   year, ...
                                                   ds_for_gapfill )
% UNM_GAPFILL_FROM_LOCAL_DATA - Performs gapfilling for specified sites, date
% ranges from other UNM sites.  This is intended to address periods where the
% online gapfiller produces poor modeled fluxes and we believe that filling
% in from other UNM sites will perform better.  The first output variable
% contains the indices at the specified site-year where we wish to override
% the online gapfiller.  The second (optional) output contains the input data
% with the data from the nearby UNM site added.  This needs to be run twice
% -- once in UNM_RemoveBadData to actually replace the data prior to
% gapfilling, and once in UNM_Ameriflux_file_builder to set the "filled"
% flags to filled.
%
% USAGE
% [ idx_filled ] = UNM_gapfill_from_local_data( sitecode, ...
%                                               year, ...
%                                               ds_for_gapfill )
% [ idx_filled, ds_for_gapfill ] = UNM_gapfill_from_local_data( sitecode, ...
%                                                               year, ...
%                                                               ds_for_gapfill )
% (c) Timothy W. Hilton, UNM, 2012
obs_per_day = 48;

%----------
% JSav 2009
if ( sitecode == 3 ) & ( year == 2009 )
    % JSav has no flux data for roughly 1 Dec 2008 to 1 Mar 2009.  The
    % gapfiller has trouble with this large gap at the beginning of 2009, so
    % here we fill the first 21 days with JSav 2008 data.  Hopefully the
    % gapfiller can "calibrate" from these data and produce a better fit for
    % the remaining gap.
    
    filled_idx = 1 : ( obs_per_day * 21 ); %first 21 days of the year

    % if caller only requested the indices to be filled, don't bother
    % processng the data
    if nargout == 2
        jsav08 = parse_forgapfilling_file( 3, 2008, '' );
        % fill NEE, LE, and H for 1 to 21 Jan 2009 from 1 to 21 Jan 2008
        ds_for_gapfill.NEE( filled_idx ) = jsav08.NEE( filled_idx );
        ds_for_gapfill.qcNEE( filled_idx ) = ...
            isnan( jsav08.NEE( filled_idx ) ) + 1; % 2 for bad data, 1 for good
        ds_for_gapfill.LE( filled_idx ) = jsav08.LE( filled_idx );
        ds_for_gapfill.H( filled_idx ) = jsav08.H( filled_idx );
    end
end

% create output arguments based on whether the user requested the filled 
if nargout <= 1
    varargout = { filled_idx };
elseif nargout == 2
    varargout = { filled_idx, ds_for_gapfill };
else
    error( 'too many output arguments' );
end