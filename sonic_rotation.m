classdef(Enumeration) sonic_rotation < int32
    
    % enumerated type to specify sonic rotation schemes.  Valid values are:
    %   threeD   0 
    %   planar   1
    %
    % EXAMPLES
    %    rotation = sonic_rotation( 0 );
    %    rotation = sonic_rotation.threeD;
    %
    % see also enumeration
    %
    % author: Timothy W. Hilton, UNM, May 2012


    enumeration
        threeD(0),
        planar(1)
    end
end