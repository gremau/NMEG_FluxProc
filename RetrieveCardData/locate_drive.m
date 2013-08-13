function drive_letter = locate_drive(drive_name)
% LOCATE_DRIVE - determines the current windows drive letter (e.g. "C:\", "E:\",
% etc.)  for a given drive name (e.g. "My Book", etc.).
%
% Returns the letter (a single character, with no ":\") if drive_name is found,
% or "0" if drive_name is not found.
%
% USAGE
%   drive_letter = locate_drive(drive_name);
%
% INPUTS
%   drive_name: string; the name of the drive to locate.
%
% OUTPUTS
%    drive_letter: character; drive letter corresponding to drive_name
%
% (c) Timothy W. Hilton, UNM, Oct 2011 
    
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