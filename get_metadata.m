function metadata = get_metadata(ionex)
% GET_METADATA  Extract header metadata from IONEX file
%
% Parses IONEX header labels (columns 60-80) for version and processing info.
%
% Carlos Molina
% UPC-IEEC
% 20-Aug-2026
    
    metadata = struct();
    
    % Split into lines for label-based parsing (IONEX format: columns 60-80)
    lines = strsplit(ionex, '\n', 'CollapseDelimiters', false);
    
    for i = 1:min(100, length(lines))  % Metadata is in first ~100 lines
        line = lines{i};
        if length(line) < 60
            continue;
        end
        
        label = strtrim(line(61:end));  % Label is in columns 60-80
        
        if contains(label, 'IONEX VERSION')
            metadata.ionex_version = strtrim(line(1:20));
        elseif contains(label, 'PGM / RUN BY / DATE')
            % Format: "program     run_by     date     PGM / RUN BY / DATE"
            parts = strsplit(strtrim(line(1:60)));
            if length(parts) >= 2
                metadata.run_by = parts{2};
            end
        end
    end
end
