function out = UNM_data_feeder(site, varargin)
%--------------------------------------------------
% function to collect necessary information from user to run UNM
% flux processing code.  
%
% The start date and end date for processing are required.  Each
% requires a year.  The day may be specified as either a
% day-of-year (1 to 366) or a calendar month and calendar day.  If
% both are specified the calendar month - calendary day pair will
% be ignored.  If input_from_excel is set to true, the start/stop
% dates will be read from data\ to\ run.xls, and dates specified as
% arguments will be ignored.
%
% INPUTS (required)
%    site: string containing the site to process
% INPUTS (required parameter-val pairs)
%    year_start: the year to begin processing
%    year_end: the year to stop processing
%    jday_start: day of year to start processing (1 to 366)
%    cmon_start: month to start processing (1 to 12) (ignored if
%                jday_start specified)
%    cday_start: day to start processing (1 to 31).  (ignored if
%                jday_start specified)
%    jday_end: day of year to stop processing (1 to 366)
%    cmon_end: month to stop processing (1 to 12) (ignored if
%                jday_stop specified)
%    cday_end: day to stop processing (1 to 31).  (ignored if
%                jday_stop specified)
%
% INPUTS (optional)
%    hour_start: hour of day to begin processing (0 to 23). Default 00
%    min_start: minute to begin processing (0 to 59).  Default 00.
%    input_from_excel: logical; if true will read start and stop
%        dates and times from excel file.
%    figures: logical; if true open windows and draw figures
%    rotation: string; 3d or planar.  Default 3d.
%    lag_nsteps: integer; number of lag steps to use
%    writefluxall: logical; write to FLUX_all file.  Default false.
%
% Timothy W. Hilton, UNM, Aug 2011
  
  % get current year
  this_year = str2num(datestr(now(), 'yyyy'));

  %-----
  % create a parser to handle user input
  p = inputParser();
  % require the site name
  p.addRequired('site', @ischar);
  % parameters for start and end year
  p.addParamValue('year_start', NaN,  @(x) isnumeric(x) && mod(x,1) == 0 ...
		  && (x >= 2007) && (x <= this_year));
  p.addParamValue('year_end', NaN,  @(x) isnumeric(x) && mod(x,1) == 0 ...
		  && (x >= 2007) && (x <= this_year)); 
  % parameters for start and end day and time
  p.addParamValue('cday_start', NaN, @isintval);  %calendar day (start)
  p.addParamValue('cday_end', NaN, @isintval);    %calendar day (end)
  p.addParamValue('cmon_start', NaN, @isintval);  %calendar month (start) 
  p.addParamValue('cmon_end', NaN, @isintval);    %calendar month (end)
  p.addParamValue('jday_start', NaN, @isintval);  %Julian day (start)
  p.addParamValue('jday_end', NaN, @isintval);    %Julian day (end)
  p.addParamValue('hour_start', 0, ...
		  @(x) isintval(x) && x >= 0 && x <=  23);
  p.addParamValue('min_start', 0, ...
		  @(x) isintval(x) && x >= 0 && x <=  59);
  % user options
  %     use the MS Excel file to specify start, stop parameters
  p.addParamValue('input_from_excel', false, @islogical);
  %     display figures
  p.addParamValue('figures', false, @islogical);
  %     3d or planar
  p.addParamValue('rotation', '3d', ...
		  @(x) any(strcmpi(x,{'3d','planar'})));
  %     lag -- on or off.  If on must specify number of steps
  p.addParamValue('lag_nsteps', 0, @(x) isinteger(x) && x >= 0);
  %     write to FLUX_all file
  p.addParamValue('writefluxall', false, @islogical);
  % end parser setup
  %-----

  % parse the input args and perform checks defined above
  p.parse('site', varargin{:});

  %collect start and end dates for processing
  if p.Results.input_from_excel
    % if user asked to input dates via excel, read the excel sheet
    user_xls = UNM_data_feeder_xls();  
    site = user_xls.site;
    user_dates = struct('year_start', user_xls.year_start,  ...
			'jday_start', user_xls.jday_start, ...
			'cmon_start', user_xls.cmon_start, ...
			'cday_start', user_xls.cday_start, ...
			'year_end', user_xls.year_end, ...
			'jday_end', user_xls.jday_end, ...
			'cmon_end', user_xls.cmon_end, ...
			'cday_end', user_xls.cday_end, ...
			'hour_start', user_xls.hour_start, ...
			'min_start', user_xls.min_start);
  else
    %collect the dates the user provided as arguments    
    user_dates = struct('year_start', p.Results.year_start,  ...
			'jday_start', p.Results.jday_start, ...
			'cmon_start', p.Results.cmon_start, ...
			'cday_start', p.Results.cday_start, ...
			'year_end', p.Results.year_end, ...
			'jday_end', p.Results.jday_end, ...
			'cmon_end', p.Results.cmon_end, ...
			'cday_end', p.Results.cday_end, ...
			'hour_start', p.Results.hour_start, ...
			'min_start', p.Results.min_start);
  end
  
  % make sure the user-provided dates are sane
  [start_dn, end_dn] = check_user_dates(user_dates);
  
  %return the user arguments
  out = p.Results;
  out.site = site;
  out.hhmm = strcat(sprintf('%02d', user_dates.hour_start),...
		    sprintf('%02d', user_dates.min_start));
  out.start_date = start_dn;
  out.end_date = end_dn;
  out.year_start = str2num(datestr(out.start_date, 'YYYY'));
  out.year_end = str2num(datestr(out.end_date, 'YYYY'));
  out.hour_start = str2num(datestr(out.start_date, 'HH'));
  out.min_start = str2num(datestr(out.start_date, 'MM'));
  out.cmon_start = str2num(datestr(out.start_date, 'mm'));
  out.cday_start = str2num(datestr(out.start_date, 'dd'));
  out.cmon_end = str2num(datestr(out.end_date, 'mm'));
  out.cday_end = str2num(datestr(out.end_date, 'dd'));
  out.jday_start = floor(start_dn) - datenum(user_dates.year_start, 1, 1) + 1;
  out.jday_end = floor(end_dn) - datenum(user_dates.year_end, 1, 1) + 1; 

%end UNM_data_feeder()

function [start_dn, end_dn] = check_user_dates(user_dates)
  %-----
  % check parsed user arguments for errors not checked in UNM_data_feeder
  %
  % -- check dates --
  % check the start and end dates; if valid convert them to datenum    
  try  % check start date
    start_dn = valid_flux_date(user_dates.year_start, user_dates.cmon_start, ...
			       user_dates.cday_start, user_dates.jday_start);
  catch start_date_err  
    %caught the specific problem with the date from valid_flux_date
    % now add a note that the problem is in the start_date
    bad_start_date = MException('UNM_data_fneeder:bad_start_date', ...
				'The start date is not a valid date');
    complete_err = addCause(start_date_err, bad_start_date);
    %throw the combined error message
    throw(complete_err);
  end
  
  try  % same as above try/catch block, but check end date
    end_dn = valid_flux_date(user_dates.year_end, user_dates.cmon_end, ...
			     user_dates.cday_end, user_dates.jday_end);
  catch end_date_err  
    bad_end_date = MException('UNM_data_feeder:bad_end_date', ...
			      'The end date is not a valid date');
    complete_err = addCause(bad_end_date, end_date_err)
    throw(complete_err)
  end
  
  %make sure end date is before start date
  if start_dn > end_dn
    err = MException('UNM_data_feeder:date_error', ...
		     'The start date is after the end date');
    throw(err)
  end

  if ~isintval(user_dates.hour_start) || user_dates.hour_start < 0 || ...
	user_dates.hour_start > 23
    throw(MException('UNM_data_feeder:date_error', ...
		     'start hour should be an integer between 0 and 23'))
  end
  if ~isintval(user_dates.min_start) || user_dates.min_start < 0 || ...
	user_dates.min_start > 59
    throw(MException('UNM_data_feeder:date_error', ...
		     'start minute should be an integer between 0 and 59'))
  end
  %
  % end date checking
  %-----

  % start and end dates and times are valid, so add start time to start date
  start_dn = start_dn + (user_dates.hour_start / 24) + ...
      (user_dates.min_start / (24 * 60));

%end check_user_dates    

function [result] = valid_flux_date(y, m, d, jd)
%----------
% check the parsed user-provided dates from UNM_data_feeder() and make sure they
% are sane
%
% INPUTS:
%    args: parsed inputParser object from UNM_data_feeder
% OUTPUTS:
%    valid: boolean; true if inputs are complete and make sense
%function [valid] = check_all_inputs(args)

    valid = false;
    %check that y is integer value and not in future
    valid_year = (mod(y,1) == 0) && (y <= str2num(datestr(now(), 'yyyy')));
    if ~isnan(jd)
        % if user specifed jday make sure it is integer and 
        % 1 <= jd <= 366
        valid_date = valid_year && valid_jdate(y, jd);
        if ~valid_date
            err = MException('valid_flux_date:invalid_Julian_date',...
                             'Julian date is not valid');
            throw(err);
        end
        result = datenum(y, 0, jd);
    else  %jd is NaN so get day from m, d
        if isnan(y) || isnan(d)
            %make sure month & day were specified
            valid_date = false;
            err = MException('valid_flux_date:missing_cal_date', ...
                             'please specify month and day OR Julian day');
            throw(err);
        else
            % month and day are present
            valid_date = isdate(y, m, d);
            if ~valid_date
                % month and day are not a valid date
                err = MException('valid_flux_date:invalid_calendar_date',...
                                 'The day/month/year triple is invalid')
                throw(err)
            end
            result = datenum(y, m, d);
        end
    end


function [result] = valid_jdate(y, jd)
    result = isintval(jd) && ...
             jd <= 365 + isleapyear(y) && ...
             jd >= 1;


