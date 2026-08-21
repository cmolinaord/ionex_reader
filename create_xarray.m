function ds = create_xarray(tecmaps, rmsmaps, epochs, metadata)
% CREATE_XARRAY  Organize parsed IONEX data into structured output
%
% Assembles TEC/RMS maps with coordinate grids and temporal information.
%
% Carlos Molina
% UPC-IEEC
% 20-Aug-2026
    
    n_lat = size(tecmaps{1}, 1);
    n_lon = size(tecmaps{1}, 2);
    latitudes = linspace(87.5, -87.5, n_lat);
    longitudes = linspace(-180, 180, n_lon);
    
    ds.tec = cat(3, tecmaps{:});
    ds.rms = cat(3, rmsmaps{:});
    % epochs is already a datetime array from get_epoch_array
    ds.time = epochs;
    ds.latitude = latitudes;
    ds.longitude = longitudes;
    ds.metadata = metadata;
end
