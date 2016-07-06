function dataTableShifted = UNM_fix_datalogger_timestamps( sitecode, year, ...
    dataTable, ...
    varargin )
% UNM_FIX_DATALOGGER_TIMESTAMPS - corrects shifts in the timestamps for
% particular periods.
%
% Called from UNM_RemoveBadData to correct shifts in the timestamps for
% particular periods.  This file simply contains the periods that need 
% to be shifted. If asked it will produce diagnostic plots that can be
% used to determine the time shifts to be applied to the data. Script calls
% shift_data to make the data shifts.
%
% INPUTS
%    sitecode: UNM_sites object; specifies the site to show
%    year: four-digit year: specifies the year to show
%    dataTable: NxM matlab table: the data to be fixed
% PARAMETER-VALUE PAIRS
%    debug: {true}|false; if true, several before & after correction plots
%        are drawn to the screen
%    save_figs: {true}|false; if true, the debug plots are saved to
%        $PLOTS/Rad_Fingerprints/SITE_YEAR_Rg_fingerprints.eps.
%        $PLOTS/Rad_Fingerprints is created if it does not exist.
%
% SEE ALSO
%    UNM_sites, dataset, UNM_site_plot_fullyear_time_offsets, shift_data,
%    plot_fixed_datalogger_timestamps
%
% author: Timothy W. Hilton, UNM, June 2012
% modified by: Gregory E. Maurer, UNM, February 2015

[ this_year, ~, ~ ] = datevec( now );

% -----
% define optional inputs, with defaults and typechecking
% -----
args = inputParser;
args.addRequired( 'sitecode', @(x) ( isintval( x ) | isa( x, 'UNM_sites' ) ) );
args.addRequired( 'year', @(x) ( isintval( x ) & ( x >= 2006 ) & ...
    ( x <= this_year ) ) );
args.addRequired( 'dataTable', @istable );
args.addParameter( 'debug', true, @islogical );

% parse optional inputs
args.parse( sitecode, year, dataTable, varargin{ : } );

sitecode = args.Results.sitecode;
year = args.Results.year;
dataTable = args.Results.dataTable;
debug = args.Results.debug;

% Get data dimensions and headers
[ nRows, nCols ] = size( dataTable );
colHeaders = dataTable.Properties.VariableNames;

% Determine column locations of 10hz and 30min data
first10hzCol = find( strcmp( 'iok', colHeaders ));
first30MinCol = find( strcmp( 'Fc_wpl', colHeaders ));
timestampCol = find( strcmp( 'timestamp', colHeaders ));
% Check for other timestamps in the file
otherTimestamps = cellfun(@(x) ~isempty( regexpi( x, 'timestamp' )), ...
    colHeaders( : ));
if sum( otherTimestamps > 1 );
    warning( ' Multiple timestamp columns exist in this FLUXALL file! ' );
end

% Get column indices for 10 hz ("matlab") data
all10hzCols = first10hzCol:first30MinCol - 1;
if ismember( nCols, timestampCol );
    all30MinCols = first30MinCol:nCols - 1; % Exclude last timestamp column
    allCols = first10hzCol:nCols - 1;
elseif timestampCol < first10hzCol
    all30MinCols = first30MinCol:nCols; % Don't exclude last column
    allCols = first10hzCol:nCols;
else
    error(' Timestamp column is misplaced in this FLUXALL data! ');
end

%--------------------------------------------------------------------------

% Extract the numeric data from the table (shift_data.m requires this)
data = table2array( dataTable );

% ============================= SHIFT DATA ================================
% Go through each site and shift the data in 'data'
switch sitecode
    case UNM_sites.GLand
        switch year
            case 2007
                % This is for old (pre-Litvak) fluxall data
                clockSet1 = 1 : DOYidx( 156.73 );
                data( clockSet1, : ) = ...
                    shift_data( data( clockSet1, : ), -0.5, allCols );
                % After site revamp data
                clockSet2 = DOYidx( 156.75 ) : DOYidx( 308.17 );
                data( clockSet2, : ) = ...
                    shift_data( data( clockSet2, : ), 1.5, allCols );
                % Data for rest of year need to be shifted 0.5 hours
                clockSet3 = DOYidx( 308.19 ) : size( data, 1 );
                data( clockSet3, : ) = ...
                    shift_data( data( clockSet3, : ), 0.5, allCols );

            case 2008
                clockSet1 = 1 : DOYidx( 74.56 );
                data( clockSet1, : ) = ...
                    shift_data( data( clockSet1, : ), 0.5, allCols );
                clockSet2 = DOYidx( 74.58 ) : DOYidx( 307.17 );
                data( clockSet2, : ) = ...
                    shift_data( data( clockSet2, : ), 1.5, allCols );
                % Data for rest of year need to be shifted 0.5 hours
                clockSet3 = DOYidx( 307.17 ) : size( data, 1 );
                data( clockSet3, : ) = ...
                    shift_data( data( clockSet3, : ), 0.5, allCols );
                
            case 2009
                % There was a .5 hour shift and then it looks like clock
                % was set to DST on day 66
                preClockSet = 1 : DOYidx( 66.57 );
                data( preClockSet, : ) = ...
                    shift_data( data( preClockSet, : ), 0.5, allCols );
                % Data for rest of year need to be shifted 1.5 hours
                postClockSet = DOYidx( 66.58 ) : size( data, 1 );
                data( postClockSet, : ) = ...
                    shift_data( data( postClockSet, : ), 1.5, allCols );
                
            case { 2010, 2011 }
                data = shift_data( data, 1.5, allCols );

            case 2012
                % Clock change on Dec 07 at 12:55
                clockSet = datenum( 2012, 12, 7, 12, 55, 0 ) - ...
                    datenum( 2012, 1, 0 );
                idx = 1 : DOYidx( clockSet  );
                data( idx, : ) = shift_data( data( idx, : ), 1.0, allCols );
                % The entire year must shift an additional 0.5 hours
                data = shift_data( data, 0.5, allCols );
            case { 2013, 2014, 2015 }
                data = shift_data( data, 0.5, allCols );
        end
        
    case UNM_sites.SLand
        switch year
            case 2007
                % This is for old (pre-Litvak) fluxall data
                clockSet1 = 1 : DOYidx( 150.73 );
                data( clockSet1, : ) = ...
                    shift_data( data( clockSet1, : ), 0.5, all10hzCols );
                data( clockSet1, : ) = ...
                    shift_data( data( clockSet1, : ), 0.5, allCols );
                % After site revamp
                clockSet2 = DOYidx( 150.75 ) : DOYidx( 308.17 );
                data( clockSet2, : ) = shift_data( ...
                    data( clockSet2, : ), 1.5, allCols );
                clockSet3 = DOYidx( 308.19 ) : size( data, 1 );
                data( clockSet3, : ) = shift_data( ...
                    data( clockSet3, : ), 0.5, allCols );

            case { 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015 }
                data = shift_data( data, 0.5, allCols );

        end
        
    case UNM_sites.JSav
        switch year
            case 2007
                clockSet1 = 1 : DOYidx( 152.5 );
                data( clockSet1, : ) = shift_data( ...
                    data( clockSet1, : ), 0.5, allCols );
                
                clockSet2 = DOYidx( 152.52 ) : DOYidx( 334.5 );
                data( clockSet2, : ) = shift_data( ...
                    data( clockSet2, : ), 1.5, allCols );
                
                clockSet3 = DOYidx( 334.52 ) : DOYidx( 347.65 );
                data( clockSet3, : ) = shift_data( ...
                    data( clockSet3, : ), 0.5, allCols );
                
                clockSet4 = DOYidx( 347.67 ) : size( data, 1 );
                data( clockSet4, : ) = shift_data( ...
                    data( clockSet4, : ), 1.5, allCols );
            
            case 2008
                clockSet1 = 1 : DOYidx( 331.6 );
                data( clockSet1, : ) = shift_data( ...
                    data( clockSet1, : ), 1.5, allCols );
                
                clockSet2 = DOYidx( 331.62 ) : size( data, 1 );
                data( clockSet2, : ) = shift_data( ...
                    data( clockSet2, : ), 0.5, allCols );
                
            case { 2009, 2010, 2011, 2012, 2013, 2014, 2015 }
                data = shift_data( data, 0.5, allCols );
        end
        
    case { UNM_sites.PJ , UNM_sites.TestSite }
        switch year
            case { 2008, 2009, 2010, 2011 }
                data = shift_data( data, 1.5, allCols );
            case 2012
                % Looks like datalogger clock was reset around day 342
                preResetIdx = 1 : DOYidx( 342.625 );
                data( preResetIdx, : ) = ...
                    shift_data( data( preResetIdx, : ), 1.5, allCols );
                % Data for rest of year still need to be shifted .5 hours
                postResetIdx = DOYidx( 342.64 ) : size( data, 1 );
                data( postResetIdx, : ) = ...
                    shift_data( data( postResetIdx, : ), 0.5, allCols );
            case { 2013, 2014, 2015, 2016 }
                data = shift_data( data, 0.5, allCols );
        end
    case UNM_sites.PJ_girdle
        switch year
            case { 2009, 2010, 2011, 2012, 2013, 2014, 2015 };
                data = shift_data( data, 0.5, allCols );
        end
        
    case UNM_sites.PPine
        switch year
            case 2007
                clockSet1 = 1 : DOYidx( 155.79 );
                data( clockSet1, : ) = shift_data( ...
                    data( clockSet1, : ), 7.5, allCols );
                
                clockSet2 = DOYidx( 155.81 ) : size( data, 1 );
                data( clockSet2, : ) = shift_data( ...
                    data( clockSet2, : ), 1.5, allCols );

            case { 2008, 2009, 2010 }
                data = shift_data( data, 1.5, allCols );
                
            case 2011
                % Looks like datalogger clock was reset around day 54
                preClockSet = 1 : DOYidx( 55.395 );
                data( preClockSet, : ) = ...
                    shift_data( data( preClockSet, : ), 1.5, allCols );
                % Data for rest of year need to be shifted 1 hours
                postClockSet = DOYidx( 55.416 ) : size( data, 1 );
                data( postClockSet, : ) = ...
                    shift_data( data( postClockSet, : ), 0.5, allCols );
                
            case 2012 
                data = shift_data( data, 1.0, allCols );
                
            case 2013
                data = shift_data( data, 1.0, allCols );
                % There is a small period in Nov-Dec where time is shifted
                % even further
                shiftIdx = DOYidx( 323.69 ) : DOYidx( 362.52 );
                data( shiftIdx, : ) = ...
                    shift_data( data( shiftIdx, : ), 1.0, allCols );
            case 2014
                data = shift_data( data, 1.0, allCols );
                % There is a period in the summer where time is shifted
                % even further
                shiftIdx = DOYidx( 172.52 ) : DOYidx( 282.52 );
                data( shiftIdx, : ) = ...
                    shift_data( data( shiftIdx, : ), 1.0, allCols );
            case 2015
                data = shift_data( data, 0.5, allCols );
        end
        
    case UNM_sites.MCon
        switch year
            case 2007
                idx = 1 : DOYidx( 250.687 );
                data( idx, : ) = ...
                    shift_data( data( idx, : ), 7.5, allCols );
                idx = DOYidx( 250.7 ) : size( data, 1 );
                data( idx, : ) = ...
                    shift_data( data( idx, : ), 1.5, allCols );

            case {2008, 2009}
                data = shift_data( data, 1.5, allCols );
                
            case 2010
                % Same as 2009 until day 296, then a small shift (?)
                preClockSet = 1 : DOYidx( 296.875 );
                data( preClockSet, : ) = ...
                    shift_data( data( preClockSet, : ), 1.5, allCols );
                % Then another small shift (?)
                preClockSet = DOYidx( 296.89 ) : DOYidx( 327.79 );
                data( preClockSet, : ) = ...
                    shift_data( data( preClockSet, : ), 2.0, allCols );
                % Data for rest of year need to be shifted 2.5 hours
                postClockSet = DOYidx( 327.81 ) : size( data, 1 );
                data( postClockSet, : ) = ...
                    shift_data( data( postClockSet, : ), 2.5, allCols );

            case 2011
                % Looks like datalogger clock was reset around day 47
                preClockSet = 1 : DOYidx( 47.50 );
                data( preClockSet, : ) = ...
                    shift_data( data( preClockSet, : ), 3.0, allCols );
                % Data for rest of year need to be shifted 0.5 hours
                postClockSet = DOYidx( 47.52 ) : size( data, 1 );
                data( postClockSet, : ) = ...
                    shift_data( data( postClockSet, : ), 0.5, allCols );
                
            % This was an insane year...
            case 2012 
                % Before all the crazy shifts...
                shiftIdx = 1 : DOYidx( 132.6 );
                data( shiftIdx, : ) = ...
                    shift_data( data( shiftIdx, : ), 0.5, allCols );
                % First shift
                shiftIdx = DOYidx( 132.625 ) : DOYidx( 160.771 );
                data( shiftIdx, : ) = ...
                    shift_data( data( shiftIdx, : ), 4.5, allCols );
                % Another shift
                shiftIdx = DOYidx( 160.792 ) : DOYidx( 224.875 );
                data( shiftIdx, : ) = ...
                    shift_data( data( shiftIdx, : ), 5.0, allCols );
                % And another...
                % compensate for the 11 Aug 2012 datalogger clock reset
                % so that the clock would match the Ameriflux tech's clock.
                % From Skyler: "I swapped the card beforehand then changed
                % the clock from Aug 11, 2012 20:54 to Aug 11,
                % 2012 17:10."
                shiftIdx = DOYidx( 224.895 ) : DOYidx( 300.48 );
                data( shiftIdx, : ) = ...
                    shift_data( data( shiftIdx, : ), 1.5, allCols );
                % And another
                shiftIdx = DOYidx( 300.5 ) : DOYidx( 319.583 );
                data( shiftIdx, : ) = ...
                    shift_data( data( shiftIdx, : ), 2.0, allCols );
                % And another
                % Clock Update: Datalogger clock was 11/14/12 1:35:30, 
                % PC clock was 11/14/12 11:55:08. Clocks synched at 11:55
                % (UTC: 7:00)
                shiftIdx = DOYidx( 319.6 ) : size( data, 1 );
                data( shiftIdx, : ) = ...
                    shift_data( data( shiftIdx, : ), 0.5, allCols );
                
            case 2013
                shiftIdx = 1 : DOYidx( 58.542 );
                data( shiftIdx, : ) = ...
                    shift_data( data( shiftIdx, : ), 1.0, allCols );
                % Small clock reset
                shiftIdx = DOYidx( 58.562 ) : size( data, 1 );
                data( shiftIdx, : ) = ...
                    shift_data( data( shiftIdx, : ), 1.5, allCols );
            case 2014
                shiftIdx = 1 : DOYidx( 126.688 );
                data( shiftIdx, : ) = ...
                    shift_data( data( shiftIdx, : ), 1.5, allCols );
                % Small clock reset
                shiftIdx = DOYidx( 126.71 ) : size( data, 1 );
                data( shiftIdx, : ) = ...
                    shift_data( data( shiftIdx, : ), 0.5, allCols );
            case 2015
                data = shift_data( data, 0.5, allCols );
        end
        
    case UNM_sites.TX
        switch year
            case { 2007, 2008, 2010, 2011, 2012 }
                data = shift_data( data, 1.0, all30MinCols );
            case 2009
                data = shift_data( data, 1.0, all30MinCols );
                idx = DOYidx( 314 ) : size( data, 1 );
                data( idx, : ) = shift_data( data( idx, : ), 1.0, ...
                    all30MinCols );
        end
        
    case UNM_sites.New_GLand
        switch year
            case 2010
                % Clock reset occured at 3pm on 6/27
                preClockSet = 1 : DOYidx( 178.6042 );
                data( preClockSet, : ) = ...
                    shift_data( data( preClockSet, : ), 0.5, allCols );
                % Data for rest of year need to be shifted 1.5 hours
                postClockSet = DOYidx( 178.625 ) : size( data, 1 );
                data( postClockSet, : ) = ...
                    shift_data( data( postClockSet, : ), 1.5, allCols );
            case 2011
                data = shift_data( data, 1.5, allCols );
            case 2012
                preClockSet = 1 : DOYidx( 342.625 );
                data( preClockSet, : ) = ...
                    shift_data( data( preClockSet, : ), 1.5, allCols );
                % Data for rest of year need to be shifted 0.5 hours
                postClockSet = DOYidx( 342.645 ) : size( data, 1 );
                data( postClockSet, : ) = ...
                    shift_data( data( postClockSet, : ), 0.5, allCols );
            case { 2013 2014, 2015 }
                data = shift_data( data, 0.5, allCols );
        end
        
end

%--------------------------------------------------------------------------

% Create the shifted table from the data array and the column names from
% the original dataTable
dataTableShifted = array2table( data, 'VariableNames', ...
    dataTable.Properties.VariableNames );

% Verify that data table timestamps are the same
test = dataTableShifted.timestamp == dataTable.timestamp;
if sum( test ) ~= nRows;
    error( ' The timestamps of the 2 created tables do not match ');
end

%==========================================================================
% Diagnostic plots
if debug
    plot_fixed_datalogger_timestamps( sitecode, year, ...
                                      dataTable, dataTableShifted );
end

% End function
end