function epochs = get_epoch_array(map_sections)
% GET_EPOCH_ARRAY  Extract temporal epochs from IONEX map sections
%
% Parses EPOCH OF CURRENT MAP lines and converts to MATLAB datetime array.
%
% Carlos Molina
% UPC-IEEC
% 20-Aug-2026
    
    epoch_cells = cellfun(@get_epoch, map_sections(2:end), 'UniformOutput', false);
    % Convert cell array of datetime objects to datetime array
    epochs = [epoch_cells{:}]';
end

function epoch = get_epoch(tecmap)
    % Extract the epoch from a TEC map string.
    
    epoch = sscanf(tecmap, '%d %d %d %d %d %d');
    epoch = datetime(epoch(1), epoch(2), epoch(3), epoch(4), epoch(5), epoch(6));
end