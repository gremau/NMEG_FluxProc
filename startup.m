% set up environment for Tim's Macbook
if not( isempty( regexpi( computer(), 'mac' ) ) )
    % add Peter Acklam's time/date utilities to path
    addpath(genpath('/Users/tim/Software/Acklam_Utils/timeutil'));
    mac_setenv;
end
    