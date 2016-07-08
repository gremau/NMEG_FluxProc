function s = cellstrcat(cs,sep)
% CELLSTRCAT       Concatenate cellstring into string w/separators
%
% s = cellstrcat(cs,sep)
%
% cs    = cellstring object
% sep   = separator to put between cells in the string (default = ',')
%
% s     = string with the cells columnwise put after one another with the
%         chosen separator between each of them. 
%
% EXAMPLE:     cs = {'Nilsen' 'Jan Even'};
%               s = cellstrcat(cs,', ');      =>    s = 'Nilsen, Jan Even'
%
% See also STRCAT STRVCAT
%
%--
% http://www-2.nersc.no/~even/matlab/evenmat/cellstrcat.m
% downloaded 25 Aug 2011
% -TWH
%--
  
error(nargchk(0,2,nargin));
if nargin<2|isempty(sep)
  sep={','};
elseif any(findstr(sep,' '))
  eval(['sep={''',sep,'''};']);
else
  sep=cellstr(sep);
end
if nargin<1|isempty(cs)
  cs={''};
end

if isempty(cs)
  s='';
else
  strcat(cs,sep)';
%  s=strcat(ans{:});
  s=[ans{:}];
  if strmatch(s(end-length(char(sep))+1:end),sep)
    s=s(1:end-length(char(sep)));
  end
end
