%% EXAMPLE: Download and process IONEX data from NASA CDDIS
% This script demonstrates how to download IONEX files automatically
% and extract TEC maps for ionospheric analysis.
%
% Carlos Molina
% UPC-IEEC
% 20-Aug-2026

%% Setup credentials (first time only)
% Option 1: Set environment variables in terminal before launching MATLAB
%   export EARTHDATA_USER=your_username
%   export EARTHDATA_PASS=your_password

% Option 2: Provide credentials directly (not recommended for scripts in repos)
%   username = 'your_username';
%   password = 'your_password';

%% Download IONEX file for specific date
target_date = datetime('2026-01-03');

% Download UPC Rapid product with 15-minute resolution (default)
filepath = download_ionex(target_date);

% Or specify explicitly
% filepath = download_ionex(target_date, 'Product', 'UPC0OPSRAP', 'Resolution', '15M');

%% Read and process IONEX data
ds = read_ionex(filepath);

fprintf('TEC data dimensions: %dx%dx%d (lat x lon x time)\n', size(ds.tec));
fprintf('Time span: %s to %s\n', datestr(ds.time(1)), datestr(ds.time(end)));
fprintf('Number of epochs: %d\n', length(ds.time));

%% Visualize first TEC map
figure('Position', [100 100 800 500]);
imagesc(ds.longitude, ds.latitude, ds.tec(:,:,1));
set(gca, 'YDir', 'normal');
colorbar;
colormap('jet');
caxis([0 60]);  % Typical TEC range in TECU
xlabel('Longitude [deg]');
ylabel('Latitude [deg]');
title(sprintf('Global TEC Map - %s UTC', datestr(ds.time(1))));

%% Extract TEC time series for specific location
% Example: Barcelona (41.39°N, 2.16°E)
lat_target = 41.39;
lon_target = 2.16;

[~, idx_lat] = min(abs(ds.latitude - lat_target));
[~, idx_lon] = min(abs(ds.longitude - lon_target));

tec_series = squeeze(ds.tec(idx_lat, idx_lon, :));

figure;
plot(ds.time, tec_series, 'LineWidth', 1.5);
xlabel('Time [UTC]');
ylabel('TEC [TECU]');
title(sprintf('TEC Time Series - Lat: %.2f°, Lon: %.2f°', ...
              ds.latitude(idx_lat), ds.longitude(idx_lon)));
grid on;

%% Download multiple days
date_range = datetime('2026-01-01'):days(1):datetime('2026-01-07');

for date = date_range
    try
        fprintf('\nProcessing: %s\n', datestr(date));
        filepath = download_ionex(date);
        % Process data here...
    catch ME
        warning('Failed for %s: %s', datestr(date), ME.message);
    end
end
