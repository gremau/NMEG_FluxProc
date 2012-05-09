% enumerated type to specify sonic rotation scheme
% (c) Timothy W. Hilton, UNM, May 2012

classdef(Enumeration) sonic_rotation < int32
    enumeration
        threeD(0),
        planar(1)
    end
end