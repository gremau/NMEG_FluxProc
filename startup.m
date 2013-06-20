% set up environment
if not( isempty( regexpi( computer(), 'mac' ) ) )
    %%% setup environment for Tim's macbook
    % add Peter Acklam's time/date utilities to path
    addpath(genpath('/Users/tim/Software/Acklam_Utils/timeutil'));
    mac_setenv;
    
    % newer versions seem to use really tiny plotting markers by default --
    % make them bigger
    set(0,'DefaultLineMarkerSize',12);
elseif not( isempty( regexpi( computer(), 'PCWIN64' ) ) )
    %%% setup environment for Jemez
    path( pathdef_CardDev_R2013a_windows );
end
    