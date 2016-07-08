function varargout = setDateAxes(varargin)
% setDateAxes is a convenience function that allows you to programmatically
% set properties of axes that contain dates and automatically update the
% date ticks. This function should be used in lieu of SET for date axes.
%
% This function is intended to be used after an initial call to
% DYNAMICDATETICKS. For more information on this function please see the
% help for <a href="matlab:help dynamicDateTicks">dynamicDateTicks</a>
%
% The calling syntax for this function is the same as that of SET. For more
% information see the documentation for <a href="matlab:help set">SET</a>
%
% Example:
% load integersignal
% dates = datenum('July 1, 2008'):1/24:datenum('May 11, 2009 1:00 PM');
% subplot(2,1,1), plot(dates, Signal1);
% dynamicDateTicks
% subplot(2,1,2), plot(dates, Signal1);
% dynamicDateTicks
% setDateAxes(gca, 'XLim', [datenum('July 1, 2008') datenum('August 1, 2008')]);


% Call the SET function with all inputs and outputs requested.
[varargout{1:nargout}] = set(varargin{:});

% At this point we could return and nothing different from calling SET
% would have occurred.

% Since this is a date axes convenience function, we should update the
% ticks if appropriate. The updateDateLabels function will automatically
% check if the axes are date axes before making changes
if nargin == 0
    return
end
for i = 1:length(varargin{1})
    updateDateLabel([], struct('Axes',varargin{1}(i)));
end


% This subfunction is identical to its namesake in dynamicDateTicks
function updateDateLabel(obj, ev, varargin) %#ok<INUSL>
ax1 = ev.Axes; % On which axes has the zoom/pan occurred
axesInfo = get(ev.Axes, 'UserData');
% Check if this axes is a date axes. If not, do nothing more (return)
try
    if ~strcmp(axesInfo.Type, 'dateaxes')
        return;
    end
catch %#ok<CTCH>
    return;
end

% Re-apply date ticks, but keep limits (unless called the first time)
if nargin < 3
    datetick(ax1, 'x', 'keeplimits');
end


% Get the current axes ticks & labels
ticks  = get(ax1, 'XTick');
labels = get(ax1, 'XTickLabel');

% Sometimes the first tick can be outside axes limits. If so, remove it & its label
if all(ticks(1) < get(ax1,'xlim'))
    ticks(1) = [];
    labels(1,:) = [];
end

[yr, mo, da] = datevec(ticks); %#ok<ASGLU> % Extract year & day information (necessary for ticks on the boundary)
newlabels = cell(size(labels,1), 1); % Initialize cell array of new tick label information

if regexpi(labels(1,:), '[a-z]{3}', 'once') % Tick format is mmm
    
    % Add year information to first tick & ticks where the year changes
    ind = [1 find(diff(yr))+1];
    newlabels(ind) = cellstr(datestr(ticks(ind), '/yy'));
    labels = strcat(labels, newlabels);
    
elseif regexpi(labels(1,:), '\d\d/\d\d', 'once') % Tick format is mm/dd
    
    % Change mm/dd to dd/mm if necessary
    labels = datestr(ticks, axesInfo.mdformat);
    % Add year information to first tick & ticks where the year changes
    ind = [1 find(diff(yr))+1];
    newlabels(ind) = cellstr(datestr(ticks(ind), '/yy'));
    labels = strcat(labels, newlabels);
    
elseif any(labels(1,:) == ':') % Tick format is HH:MM
    
    % Add month/day/year information to the first tick and month/day to other ticks where the day changes
    ind = find(diff(da))+1;
    newlabels{1}   = datestr(ticks(1), [axesInfo.mdformat '/yy-']); % Add month/day/year to first tick
    newlabels(ind) = cellstr(datestr(ticks(ind), [axesInfo.mdformat '-'])); % Add month/day to ticks where day changes
    labels = strcat(newlabels, labels);
    
end

set(axesInfo.Linked, 'XTick', ticks, 'XTickLabel', labels);
