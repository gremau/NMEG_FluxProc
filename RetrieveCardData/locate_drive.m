function drive_letter = locate_drive(drive_name)
% LOCATE_DRIVE - determines the windows drive letter for a given name (e.g. "My
%   Book", etc.)
    
    letter = int8('a');
    found = false;
    
    while(not(found) & (letter <= int8('z')))
        [result, output] = system(sprintf('vol %c:', letter));
        
        found = length(regexpi(output, drive_name)) > 0;
        
        if not(found)
            letter = letter + 1;
        end
    end

    if found
        drive_letter = char(letter);
    else
        drive_letter = '0';
    end