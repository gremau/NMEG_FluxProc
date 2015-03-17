function result = find_missing_data( sitecode, year );

% Find missing TOB1 and TOA5 data for a site/year by examinng the files
% on this computer

% sitecode = UNM_sites.PJ_girdle;
% year = 2009;
%sitelist = {UNM_sites.New_GLand};
result = 0;

ts_dataDir = fullfile( get_site_directory( sitecode ), 'ts_data');

toa5Dir = fullfile( get_site_directory( sitecode ), 'toa5');

toa5Files = cellstr( ls( [ toa5Dir '\TOA5*.DAT' ]));
tob1Files = cellstr( ls( [ ts_dataDir '\TOB1*.DAT' ]));
toa5FileStruct = dir( [ toa5Dir '\TOA5*.DAT' ]);
tob1FileStruct = dir( [ ts_dataDir '\TOB1*.DAT' ]);

tob1Tstamps = floor( tstamps_from_filenames( tob1Files ));
toa5Tstamps = floor( tstamps_from_filenames( toa5Files ));

start_dnum = datenum( year, 1, 1, 0, 0, 0 );
end_dnum = datenum( year, 12, 31, 0, 0, 0 );

fullYearDailyTstamps = ( start_dnum:end_dnum )';

% Full number of files matching days in this year
tob1_all_in_year = ismember( tob1Tstamps, fullYearDailyTstamps);

% Number of days accounted for
tob1_days_accounted_for = ismember( fullYearDailyTstamps, tob1Tstamps );

% Partial days
tob1_partial = sum( tob1_all_in_year ) - sum( tob1_days_accounted_for );

% Missing days from
tob1_missing_days = ~tob1_days_accounted_for;
missing_dnums = fullYearDailyTstamps( tob1_missing_days );
if sum( tob1_missing_days ) ~= 0
    fprintf('\n Missing TOB1 files for %s %d: \n', ...
        get_site_name( sitecode ), year );
    for i = 1:length( missing_dnums )
        missing = missing_dnums( i );
        fprintf('... TOB1_%s_%s.dat\n', ...
            get_site_name( sitecode ), ...
            datestr( missing, 'YYYY_mm_DD_HHMM' ));
    end
else
    fprintf(' No TOB1 files are missing for %d.\n', year );
end

% -------------------------------------------------------------------------
% Figure out which TOA5 files are missing

fullYear30minTstamps = ( start_dnum : 1/48 : end_dnum + 1)';

% List the TOA5 files are within the year (include last of prior year)
included = toa5Tstamps >= start_dnum & toa5Tstamps <= end_dnum;
included = find( included );
if min( included ) ~= 1
    included = [ min( included ) - 1; included ];
end
includedTOA5Files = toa5Files( included );

% Empty array to fill with timestamps from all of these TOA5 files
toa5ObsTstamps = [];

% Loop through and load each TOA5 file timestamp into the array
for i = 1:numel( includedTOA5Files )
    fileData = toa5_2_table( fullfile( toa5Dir, includedTOA5Files{ i }));
    toa5ObsTstamps = [ toa5ObsTstamps; fileData.timestamp ];
end
% Trim to year
[ obsYr, ~, ~, ~, ~, ~ ] = datevec( toa5ObsTstamps );
toa5ObsTstamps = toa5ObsTstamps( obsYr == year, : );

% Find which fullyear timestamps are accounted for in the observed
% timestamps and get their index
inTOA5timestamps = ismember( fullYear30minTstamps, toa5ObsTstamps  );
foundTstamps = fullYear30minTstamps( inTOA5timestamps );
% Make sure there is a start and end timestamp in found Tstamps
foundTstamps = [ start_dnum; foundTstamps; end_dnum + 1 ];
% Difference these indices to non-sequential timestamps
foundDiff = diff( foundTstamps );
% The start of each gap is indicated by the first Tstamp in foundTstamps
% that more than 1/48th of a day greater than the previous timestamp. 
startGaps = foundTstamps( foundDiff > 1/47.9 ) + 1/48;
% End of the gap is defined as the next Tstamp in found Tstamps after 
% startGaps
shiftFTS = circshift( foundTstamps, - 1 );
endGaps = shiftFTS( foundDiff > 1/47.9 ) - 1/48;

if length( startGaps ) ~= length( endGaps )
    warning( ' Starting gaps and ending gaps do not match' );
end

% Output...
if length( startGaps ) > 0
    fprintf('\n Missing TOA5 file timestamps (inclusive) for %s %d:\n', ...
        get_site_name( sitecode ), year );
    for i = 1:length( startGaps )
        outStr = sprintf( '... %s to  %s', ...
            datestr( startGaps( i ), 'mmm dd, HH:MM'), ...
            datestr( endGaps( i ), 'mmm dd, HH:MM'));
        lenGap = floor( endGaps( i ) - startGaps( i ));
        if lenGap >= 1
            fprintf( [ outStr '  %d days\n' ], lenGap );
        else
            fprintf( [ outStr '\n' ]);
        end
    end
else
    fprintf(' No TOA5 timestamps are missing for %d.\n', year );
end



