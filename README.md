# IONEX Reader for MATLAB

[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.22042973.svg)](https://doi.org/10.5281/zenodo.22042973)

MATLAB toolbox for reading and parsing IONEX (IONosphere Map EXchange) files. IONEX is a standard format used by the International GNSS Service (IGS) to distribute global ionospheric Total Electron Content (TEC) maps.

**Quick Start**: See [QUICKSTART.md](QUICKSTART.md) for 3-minute setup guide.

## Overview

This toolbox provides efficient parsing of IONEX files into structured MATLAB data, extracting:
- **TEC maps**: Total Electron Content in TECU (10¹⁶ electrons/m²)
- **RMS maps**: Root Mean Square error estimates
- **Temporal information**: Epoch timestamps for each map
- **Metadata**: File version, processing information

## Installation

Clone or download this repository:

```bash
git clone https://github.com/cmolinaord/ionex_reader.git
cd ionex_reader
```

Add to MATLAB path:
```matlab
addpath('/path/to/ionex_reader')
```

Run tests to verify installation:
```matlab
test_ionex
```

## Usage

### Automatic Download from NASA CDDIS

```matlab
% Setup NASA Earthdata credentials (first time only)
setenv('EARTHDATA_USER', 'your_username');
setenv('EARTHDATA_PASS', 'your_password');

% Download IONEX file for specific date
% The system automatically creates .netrc for authentication
filepath = download_ionex(datetime('2026-01-03'));

% Read downloaded file
ds = read_ionex(filepath);
```

**Credential Setup**: See [EARTHDATA_SETUP.md](EARTHDATA_SETUP.md) for detailed registration and configuration instructions.

**Technical Details**: Downloads use `wget` with `.netrc` authentication to properly handle NASA's OAuth flow.

### Local File Reading

```matlab
% Read an existing IONEX file
ds = read_ionex('codg0010.21i');

% Access TEC data (latitude × longitude × time)
tec = ds.tec;          % TEC values in TECU (automatically converted from IONEX format: 0.1 TECU)
rms = ds.rms;          % RMS error estimates
time = ds.time;        % Datetime array of epochs
lat = ds.latitude;     % Latitude grid
lon = ds.longitude;    % Longitude grid
metadata = ds.metadata; % File metadata
```

### Visualization Example

```matlab
% Plot TEC map for first epoch
figure;
imagesc(ds.longitude, ds.latitude, ds.tec(:,:,1));
set(gca, 'YDir', 'normal');
colorbar;
xlabel('Longitude [deg]');
ylabel('Latitude [deg]');
title(sprintf('TEC Map - %s', datestr(ds.time(1))));
```

## IONEX Format

IONEX files typically contain:
- Global TEC maps with 2.5° × 5° resolution (71 lat × 73 lon)
- Temporal resolution: 1-2 hours
- Data source: GNSS receiver networks (IGS, regional networks)

## Functions

### Data Acquisition
- **`download_ionex(date, ...)`**: Download IONEX files from NASA CDDIS with automatic caching

### Data Processing
- **`read_ionex(filename)`**: Main function to read IONEX file
- **`parse_map(section)`**: Parse individual TEC/RMS map
- **`get_epoch_array(sections)`**: Extract temporal epochs
- **`get_metadata(ionex)`**: Extract file metadata
- **`create_xarray(...)`**: Organize data into structured output

### Advanced Download Options
```matlab
% Specify product and resolution
filepath = download_ionex(datetime('2026-01-03'), ...
                         'Product', 'UQRG', ...      % Product type
                         'Resolution', '15M', ...     % 15-minute resolution
                         'DataDir', './my_data/');    % Custom cache directory

% Force redownload
filepath = download_ionex(date, 'Force', true);
```

**Available Products:**
- `UPC0OPSRAP`: UPC Rapid (default) - 15min resolution, low latency
- `UPC0OPSFIN`: UPC Final - 2h resolution, highest accuracy
- `UQRG`: UPC Rapid (legacy naming) - 15min resolution

## Data Sources

IONEX files are available from:
- **IGS**: [ftp://cddis.gsfc.nasa.gov/pub/gps/products/ionex/](ftp://cddis.gsfc.nasa.gov/pub/gps/products/ionex/)
- **CODE**: [ftp://ftp.aiub.unibe.ch/CODE/](ftp://ftp.aiub.unibe.ch/CODE/)
- **JPL**: [https://cddis.nasa.gov/archive/gnss/products/ionex/](https://cddis.nasa.gov/archive/gnss/products/ionex/)

## Requirements

- MATLAB R2019b or later (uses `arguments` validation)
- **wget** (for automatic downloads)
  - Pre-installed on most Linux/macOS systems
  - Linux: `sudo apt install wget`
  - macOS: `brew install wget`
  - Windows: Use WSL or download from [gnu.org/software/wget](https://www.gnu.org/software/wget/)
- No additional MATLAB toolboxes required
- Internet connection for automatic downloads
- NASA Earthdata account (free registration at [urs.earthdata.nasa.gov](https://urs.earthdata.nasa.gov))

## Applications

This toolbox is designed for research in:
- Ionospheric scintillation modeling
- GNSS signal propagation
- Space weather monitoring
- Satellite navigation error correction
- Radio astronomy (ionospheric TEC corrections)

## Project Structure

```
ionex_reader/
├── README.md                  # This file
├── LICENSE.txt                # BSD 3-Clause license
├── EARTHDATA_SETUP.md         # NASA credentials configuration guide
├── .gitignore                 # Git ignore rules
├── read_ionex.m               # Main IONEX parser
├── download_ionex.m           # Automatic download from CDDIS
├── parse_map.m                # TEC/RMS map parser
├── get_epoch_array.m          # Temporal epoch extractor
├── get_metadata.m             # Metadata parser
├── create_xarray.m            # Data structure builder
├── example_download.m         # Usage examples
├── test_ionex.m               # Test suite
└── data/                      # Local cache (not in repo)
    └── YYYY/DDD/              # Organized by year/day-of-year
```

## Author

**Carlos Molina**  
UPC-IEEC (Universitat Politècnica de Catalunya, Institut d'Estudis Espacials de Catalunya)  
Email: carlos.molina@upc.edu

## License

BSD 3-Clause License - See [LICENSE.txt](LICENSE.txt) for details.

## Acknowledgments

Based on initial work by Bhuvnesh Brawar (2024). Modified and extended for research applications in ionospheric studies.

## References

1. Schaer, S., Gurtner, W., & Feltens, J. (1998). *IONEX: The IONosphere Map EXchange Format Version 1*. IGS AC Workshop, Darmstadt, Germany.
2. Hernández-Pajares, M., et al. (2009). *The IGS VTEC maps: a reliable source of ionospheric information since 1998*. Journal of Geodesy, 83(3-4), 263-275.
