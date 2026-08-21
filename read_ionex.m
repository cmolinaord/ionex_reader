function ds = read_ionex(filename)
% READ_IONEX  Read and parse IONEX file format
%
% SYNTAX:
%   ds = read_ionex(filename)
%
% INPUT:
%   filename  - Path to IONEX file (.INX or .ionex)
%
% OUTPUT:
%   ds        - Structure with fields:
%               .tec       [lat×lon×time] TEC values in TECU
%               .rms       [lat×lon×time] RMS error in TECU
%               .time      [N×1] datetime array of epochs
%               .latitude  [M×1] latitude grid [deg]
%               .longitude [P×1] longitude grid [deg]
%               .metadata  Structure with file information
%
% EXAMPLE:
%   ds = read_ionex('UPC0OPSRAP_20260030000_01D_15M_GIM.INX');
%   imagesc(ds.longitude, ds.latitude, ds.tec(:,:,1));
%
% Carlos Molina
% UPC-IEEC
% 20-Aug-2026

	arguments
		filename (1,:) char {mustBeFile}
	end
    
    ionex = fileread(filename);
    tec_maps = parse_map_array(strsplit(ionex, 'START OF TEC MAP'));
    rms_maps = parse_map_array(strsplit(ionex, 'START OF RMS MAP'));
    epochs = get_epoch_array(strsplit(ionex, 'START OF TEC MAP'));
    metadata = get_metadata(ionex);
    ds = create_xarray(tec_maps, rms_maps, epochs, metadata);
end
function tec_maps = parse_map_array(map_sections)
    % Parse an array of TEC or RMS maps from IONEX sections.
    
    tec_maps = cellfun(@(section) parse_map(section), map_sections(2:end), 'UniformOutput', false);
end
