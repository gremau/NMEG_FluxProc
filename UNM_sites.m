classdef(Enumeration) UNM_sites < int32
    % enumerated type to specify UNM sitecodes.  
    %
    % May be specified with an integer argument or with a field; see examples
    % section below.  Site--integer pairs are: GLand 1, SLand 2, JSav 3, PJ 4,
    % PPine 5, MCon 6, TX 7, TX_forest 8, TX_grass 9, PJ_girdle 10, New_GLand
    % 11, SevEco 12
    %
    % EXAMPLES:
    %    sitecode = UNM_sites(1);
    %    sitecode = UNM_sites.GLand;
    %    character( sitecode );
    %
    % see also enumeration
    %
    % author: Timothy W. Hilton, UNM, May 2012

    enumeration
        GLand(1),
        SLand(2),
        JSav(3),
        PJ(4),
        PPine(5),
        MCon(6),
        TX(7),
        TX_forest(8),
        TX_grass(9),
        PJ_girdle(10),
        New_GLand(11),
        SevEco( 12 ),
        MCon_SS( 13 ),
        TestSite( 14 )
    end
end