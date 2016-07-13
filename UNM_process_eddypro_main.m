function [ result, all_data ] = UNM_process_eddypro_main( sitecode, ...
                                                  t_start, ...
                                                  t_end, ...
                                                  varargin )
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
if ( year_start ~= year_end )
    error( '10-hz data processing may not span different calendar years' );
else
    year = year_start;
end

if( isempty( ts_data_dir ) )
    ts_data_dir = fullfile( get_site_directory( sitecode ), 'ts_data' );
end

% Update eddypro project file for current CDP time period
obj.sitecode='TestSite';
eddypro_proj = fullfile('C:','Research_Flux_Towers',...
            'SiteData',obj.sitecode,...
            'eddypro_out',[obj.sitecode,'.eddypro']);

A = regexp( fileread(eddypro_proj), '\n', 'split');     %Read in proj file
A = A(1:numel(A)-1);                                    %Remove empty line
A = regexprep(A,'\r\n|\n|\r','');                       %Remove carriage returns
A{129} = sprintf('%s'.ts_data_dir);                     %Raw data directory
A = regexprep(A,'\\','\/');                             %Eddypro wants forward slashes
% Update project start and end dates with cdp date_start and date_end
A{45}  = sprintf('%s',['pr_start_date=',datestr(t_start,'yyyy-mm-dd')]);
A{46}  = sprintf('%s','pr_start_time=00:00');
A{47}  = sprintf('%s',['pr_end_date=',datestr(t_end+1,'yyyy-mm-dd')]);
A{48}  = sprintf('%s','pr_end_time=00:00');
fid = fopen(eddypro_proj, 'w');                          %Write new proj file
fprintf(fid, '%s\n', A{:});
fclose(fid)

% Construct EddyPro system command and run

eddypro_exe = fullfile('C:','Program Files (x86)',...
    'LI-COR','EddyPro-6.1.0','bin','eddypro_rp');
eddypro_cmd = [eddypro_exe,' ',eddypro_proj];
ep_t = datevec(now);    %Grab timestamp to start of EP processing

tic
system(eddypro_cmd);    %Run EddyPro
toc

% Read in newly processed data 

