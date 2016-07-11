% Sets paths in fluxproc directory
if ~isempty( regexpi( pwd, 'FluxProc' ) )
    fprintf( 'Setting paths for FluxProc...\n' );
    addpath( fullfile( pwd, 'scripts' ))
    addpath( fullfile( pwd, 'm_utils' ))
    addpath( genpath( fullfile( pwd, 'm_exchange_utils' )))
    addpath( fullfile( pwd, 'retrieve_card_data' ))
    %addpath('Utilities/') - moved to utils/
    addpath( fullfile( pwd, 'plots' ))
else
    error( 'Present directory not a FluxProc directory!' );
end

% Moved to ./m_utils/
%addpath('/home/greg/current/MatlabFluxUtilities/')
% Moved to ./m_exchange_utils/
%addpath('/home/greg/current/MatlabGeneralUtilities/')
