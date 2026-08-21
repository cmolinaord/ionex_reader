function tecmap = parse_map(tecmap_str)
% PARSE_MAP  Parse single TEC/RMS map from IONEX section
%
% Extracts numerical data from IONEX map section, filtering metadata lines.
% Standard IONEX maps: 71 latitudes × 73 longitudes (2.5° × 5° resolution).
%
% Carlos Molina
% UPC-IEEC
% 20-Aug-2026
    
    % Cut at END OF TEC MAP to exclude trailing content
    end_idx = strfind(tecmap_str, 'END OF TEC MAP');
    if ~isempty(end_idx)
        tecmap_str = tecmap_str(1:end_idx(1)-1);
    end
    
    % Split into lines
    lines = strsplit(tecmap_str, '\n');
    
    % Extract all numbers, filtering out IONEX metadata lines
    tec_values = [];
    
    for i = 1:length(lines)
        line = lines{i};
        
        % Skip empty lines
        if length(line) < 3
            continue;
        end
        
        % IONEX standard: label keywords are right-justified in columns 60-80
        % Skip any line with alphabetic label (EPOCH, LAT/LON, START/END, etc.)
        if length(line) >= 60
            label = line(60:end);
            if ~isempty(regexp(label, '[A-Za-z]', 'once'))
                continue;  % This is a metadata line with IONEX label
            end
        end
        
        % Additional filters: skip lines with IONEX keywords anywhere
        if contains(line, 'LAT/LON') || contains(line, 'EPOCH') || ...
           contains(line, 'START OF') || contains(line, 'END OF')
            continue;
        end
        
        % Parse all numbers from this line
        nums = sscanf(line, '%f');
        
        % Skip lines with single small integer (map indices 1-999)
        % These come from strsplit artifacts: "12      START OF TEC MAP" → "12      "
        if length(nums) == 1 && nums(1) >= 0 && nums(1) < 1000 && nums(1) == floor(nums(1))
            continue;
        end
        
        % Append TEC values
        if length(nums) > 0
            tec_values = [tec_values; nums];
        end
    end
    
    % Expected dimensions: 71 latitudes × 73 longitudes
    n_lat = 71;
    n_lon = 73;
    expected_count = n_lat * n_lon;
    
    if length(tec_values) == expected_count
        % Reshape: IONEX stores data as [lon1...lon73] for each lat
        tecmap = reshape(tec_values, n_lon, n_lat)';
    else
        error('parse_map:badsize', ...
            'Expected %d TEC values (71×73), got %d', expected_count, length(tec_values));
    end
end
