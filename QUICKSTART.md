# Quick Start Guide

## 1. Installation (30 seconds)
```matlab
% Add to MATLAB path
addpath('/proyectos/ionex_reader')

% Verify installation
test_ionex
```

## 2. NASA Earthdata Setup (2 minutes)
1. Register at [urs.earthdata.nasa.gov](https://urs.earthdata.nasa.gov)
2. Authorize "CDDIS" application in your profile
3. Set credentials:
```matlab
setenv('EARTHDATA_USER', 'your_username');
setenv('EARTHDATA_PASS', 'your_password');
```

## 3. Download & Process (3 lines)
```matlab
file = download_ionex(datetime('2026-01-03'));
ds = read_ionex(file);
imagesc(ds.longitude, ds.latitude, ds.tec(:,:,1)); colorbar;
```

## Output Structure
```matlab
ds.tec        % TEC maps [71×73×N] in TECU
ds.rms        % RMS error [71×73×N] in TECU
ds.time       % Datetime array [N×1]
ds.latitude   % [-87.5, 87.5] deg
ds.longitude  % [-180, 180] deg
ds.metadata   % File information
```

## Common Tasks

### Extract TEC time series for location
```matlab
lat = 41.39; lon = 2.16;  % Barcelona
[~, i] = min(abs(ds.latitude - lat));
[~, j] = min(abs(ds.longitude - lon));
tec_series = squeeze(ds.tec(i, j, :));
plot(ds.time, tec_series);
```

### Download date range
```matlab
for date = datetime('2026-01-01'):days(1):datetime('2026-01-07')
    file = download_ionex(date);
    ds = read_ionex(file);
    % Your analysis here...
end
```

### Use different products
```matlab
% UPC Rapid 15min (default, low latency)
file = download_ionex(date);

% UPC Final 2h (highest accuracy, ~7-14 days delay)
file = download_ionex(date, 'Product', 'UPC0OPSFIN', 'Resolution', '02H');
```

## Help & Troubleshooting

See detailed guides:
- [README.md](README.md) - Complete documentation
- [EARTHDATA_SETUP.md](EARTHDATA_SETUP.md) - Credential configuration
- `help download_ionex` - Function documentation
- `help read_ionex` - Parser documentation

Contact: carlos.molina@upc.edu
