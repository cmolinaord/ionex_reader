# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.1] - 2026-08-21

### Fixed
- **TEC unit conversion**: IONEX maps now correctly convert from 0.1 TECU (file format) to TECU (output values)
- Missing value handling: Values marked as 9999 in IONEX files are now replaced with NaN
- Updated documentation to reflect automatic unit conversion in output

### Technical Details
- Modified `parse_map.m`: Applies 0.1× scaling factor and NaN replacement per IONEX 1.0 specification
- Output `.tec` field now directly provides values in TECU units without user conversion

## [0.1.0] - 2026-08-21

### Added
- Initial stable release of IONEX Reader toolbox
- Core functionality for parsing IONEX (IONosphere Map EXchange) files
- Support for NASA CDDIS automated downloads with Earthdata credentials
- TEC (Total Electron Content) and RMS map extraction
- MATLAB xarray integration via `create_xarray.m`
- Metadata parsing (version, processing information, temporal data)
- Simple versioning system with `get_version()` function
- Version display in download and parsing messages
- Comprehensive test suite (`test_ionex.m`)
- Quick start guide and documentation

### Documentation
- README.md with installation and usage examples
- QUICKSTART.md for 3-minute setup
- EARTHDATA_SETUP.md for NASA Earthdata authentication
- Inline function documentation with examples
- CITATION.cff for academic citations
