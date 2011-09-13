%program to feed 10Hz data files to other programs for analysis
%
% Timothy W. Hilton, UNM, Sep 2011
%
% INPUTS
% sitecode: integer; code for the site to be run
% date_start: datenum; starting date and time for processing
% date_end: datenum; ending date and time for processing

function all_filenames = UNM_filebuilder(site, date_start, date_end)

  fluxrc = UNM_flux_process_config();
  
  sitedir = get_site_directory(get_site_code(site));
  infile_dir = get_in_directory(get_site_code(site));

  % create a sequence of dates corresponding to the TOB1 files to process.
  % Only the first will have hour & min, so take the floor of the rest
  dates = date_start:1.0:date_end;
  dates(2:end) = floor(dates(2:end));
  all_filenames = cellstr(datestr(dates, 'YYYY_mm_dd_HHMM'));
  for i = 1:length(all_filenames)
    all_filenames{i} = fullfile(infile_dir, site, ...
				sprintf('TOB1_%s_%s.DAT;', site, ...
					all_filenames{i}));
  end
  
  %[DATE,hr,fco2out,tdryout,hsout,hlout,iokout] = UNM_data_processor(f_year,filename,date,jday,site,sitecode,outfolder,sitedir,figures,rotation,lag,writefluxall);  


