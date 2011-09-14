%test batch script to run matlab remotely on skynet

args = UNM_data_feeder('US-Pcp', 'year_start', 2009, 'jday_start', ...
		       100, 'year_end', 2009, 'jday_end', 110);

disp(args)  %will this go to the log file?


exit  %must be last 