function [ result, all_data ] = UNM_process_eddypro_main( sitecode, ...
                                                  t_start, ...
                                                  t_end, ...
                                                  varargin )
% FIXME - documentation and cleanup                                              

p = inputParser;
p.addRequired( 'sitecode', @( x ) ( isnumeric( x ) | isa( x, 'UNM_sites' ) ) ); 
p.addRequired( 't_start', @isnumeric );
p.addRequired( 't_end', @isnumeric );

p.addParameter( 'ts_data_dir', ...
                 [], ...
                 @ischar );
    
% parse optional inputs
p.parse( sitecode, t_start, t_end, varargin{ : } );
    
sitecode = p.Results.sitecode;
t_start = p.Results.t_start;
t_end = p.Results.t_end;
ts_data_dir = p.Results.ts_data_dir;
% -----
% if called with more than two output arguments, throw exception
% -----
nargoutchk( 0, 2 );

% -----
% start processing
% -----

t0 = now();  % track running time

result = 1;  % initialize to failure -- will change on successful completion

[ year_start, ~, ~, ~, ~, ~ ] = datevec( t_start );
[ year_end, ~, ~, ~, ~, ~ ] = datevec( t_end );

% if ( year_start ~= year_end )
%     error( '10-hz data processing may not span different calendar years' );
% else
    year = year_start;
% end

if( isempty( ts_data_dir ) )
    ts_data_dir = fullfile( get_site_directory( sitecode ), 'ts_data' );
end

% Update eddypro project file for current CDP time period

setenv('EPROOT',fullfile('C:','Research_Flux_Towers',...
    'SiteData',char(sitecode),...
    'eddypro_out'));
eddypro_proj = fullfile('C:','Research_Flux_Towers',...
            'SiteData',char(sitecode),...
            'eddypro_out',[char(sitecode),'.eddypro']);
%mkdir(fullfile(getenv('EPROOT'),'temp'));
%-----------------------------
%For future parallel computing
%-----------------------------
%Timestamp extraction for parsing eddypro project files into day-sized
%chunks
% [~,~,~,start_h,start_min,~]=datevec(t_start);
% [~,~,~,end_h,end_min,~]=datevec(t_end);
% ndays = ceil(t_end) - floor(t_start);
% ep_ts = linspace(floor(t_start),floor(t_end),ndays);
% ep_ts(1) = min(ep_ts)+datenum([ 0 0 0 start_h start_min 0 ]);
% ep_ts(length(ep_ts)) = ep_ts(length(ep_ts))+datenum([ 0 0 0 end_h end_min 0 ] );


% temp_pf = tempname(fullfile(getenv('EPROOT'),'temp'));
% temp_pf = fullfile([temp_pf,'.eddypro']);
% copyfile(eddypro_proj,temp_pf); %Copy project file to temporary file for editing/processing

A = regexp( fileread(eddypro_proj), '\n', 'split');          %Read in proj file
A = A(1:numel(A)-1);                                    %Remove empty line
A = regexprep(A,'\r\n|\n|\r','');                       %Remove carriage returns
A{129} = sprintf('data_path=%s',ts_data_dir);           %Raw data directory
A = regexprep(A,'\\','\/');                             %Eddypro wants forward slashes
% Update project start and end dates with cdp date_start and date_end
A{45}  = sprintf('%s',['pr_start_date=',datestr(t_start,'yyyy-mm-dd')]);
A{46}  = sprintf('%s',['pr_start_time=',datestr(t_start,'HH:00')]);
A{47}  = sprintf('%s',['pr_end_date=',datestr(t_end,'yyyy-mm-dd')]);
A{48}  = sprintf('%s',['pr_end_time=',datestr(t_end,'HH:00')]);
fid = fopen(eddypro_proj, 'w');                          %Write new proj file
fprintf(fid, '%s\n', A{:});
fclose(fid)
% Construct EddyPro system command and run

eddypro_exe = fullfile('C:','"Program Files (x86)"',...
    'LI-COR','EddyPro-6.1.0','bin','eddypro_rp');
eddypro_cmd = [eddypro_exe,' ',eddypro_proj];

tic
fprintf( '---------- processing in EddyPro ----------\n' );
[ep_status ep_result]=system(eddypro_cmd)    %Run EddyPro. May need to change environment
toc

%Get list of full_output eddypro files in site dir
listing= dir(fullfile('C:','Research_Flux_Towers',...
    'SiteData',char(sitecode),...
    'eddypro_out','*full_output*'));
%listing = struct2table(listing);   %Convert listing to table
[maxdate f_i] = max([listing.datenum]);    %Find newest file, this will be used for opening file
fname = listing(f_i).name;
fname = fullfile(getenv('EPROOT'),fname);
all_data = eddypro_2_table( fname );

outfolder = fullfile(getenv('FLUXROOT'),'SiteData', char( sitecode ), ...
			 'ep_data');
if exist(outfolder) ~= 7
    disp(['creating ', outfolder]);
    [result, msg, msgid] = mkdir(outfolder);
end

%Save file if something goes wrong
outfile = fullfile( get_out_directory( sitecode ), ...
                    'ep_data', ...
                    sprintf( '%s_ep_%d.mat', ...
                             get_site_name( sitecode ), year ) );

save( outfile, 'all_data' );

ts_start = min(all_data.timestamp);
ts_start = datestr(ts_start,'yyyy_mm_dd_HHMM');

 [SUCCESS,MESSAGE,MESSAGEID] = movefile(fname,...
      fullfile(getenv('FLUXROOT'),'SiteData',char(sitecode),...
      'ep_data',['ep_',char(sitecode),'_',ts_start,'.csv']))
  
 delete(fullfile(getenv('EPROOT'),['eddypro_',char(sitecode),'*']),fullfile(getenv('EPROOT'),'processing*'));

 %Save to .mat file. Not sure if this is necessary right now.
 %Check to see if directory exists

% 
% outfile = fullfile( get_out_directory( sitecode ), ...
%                     'ep_data', ...
%                     sprintf( '%s_ep_%d.mat', ...
%                              get_site_name( sitecode ), year ) );
% save( outfile, 'all_data' );

end
