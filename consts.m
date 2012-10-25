classdef consts 
% Property data is private to the class
   properties( SetAccess = private, GetAccess = private )
       SECS_PER_DAY = 60 * 60 * 24;  % seconds in 1 day
       THIRTY_MINS = 1 / 48;  % 30 minutes expressed in units of days
   end % properties
   
   methods
       function secs = secs_per_day( obj )
           secs = obj.SECS_PER_DAY;
       end
   end
   
end