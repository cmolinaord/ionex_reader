# NASA Earthdata Setup Guide

## Overview
Automatic download from NASA CDDIS archive requires free registration at NASA Earthdata.

## Registration Steps

1. **Create Account**
   - Visit: [urs.earthdata.nasa.gov/users/new](https://urs.earthdata.nasa.gov/users/new)
   - Fill registration form
   - Verify email

2. **Authorize CDDIS Application**
   - Login to Earthdata
   - Navigate to Applications → Authorized Apps
   - Search for "CDDIS" or "NASA CDDIS Archive"
   - Click "Authorize"

## Credential Configuration

The download system automatically creates a `.netrc` file for secure authentication with NASA's servers using wget.

### Option 1: Environment Variables (Recommended)

**Linux/macOS:**
```bash
export EARTHDATA_USER=your_username
export EARTHDATA_PASS=your_password
```

Add to `~/.bashrc` or `~/.zshrc` for persistence.

**Windows (PowerShell):**
```powershell
$env:EARTHDATA_USER = "your_username"
$env:EARTHDATA_PASS = "your_password"
```

**Windows (CMD):**
```cmd
set EARTHDATA_USER=your_username
set EARTHDATA_PASS=your_password
```

### Option 2: Direct Input (Development Only)

```matlab
filepath = download_ionex(datetime('2026-01-03'), ...
                         'Username', 'your_username', ...
                         'Password', 'your_password');
```

⚠️ **Security Warning**: Never commit credentials to Git repositories.

### About .netrc File

The system automatically manages a `.netrc` file in your home directory:
- **Location**: `~/.netrc` (Linux/macOS) or `%USERPROFILE%\.netrc` (Windows)
- **Format**: `machine urs.earthdata.nasa.gov login <user> password <pass>`
- **Permissions**: Automatically set to 600 (owner read/write only)
- **Purpose**: Used by wget for authentication with NASA Earthdata

You **don't need to create this file manually** — `download_ionex()` handles it automatically.

## Verification

Test credentials:
```matlab
% Should download without errors
filepath = download_ionex(datetime('2026-01-03'));
```

If authentication fails, verify:
1. Credentials are correct
2. Earthdata account is active
3. CDDIS application is authorized
4. Network allows HTTPS connections

## Troubleshooting

**Error: "wget not found"**
- Solution: Install wget
  - Linux: `sudo apt install wget`
  - macOS: `brew install wget`
  - Windows: Use WSL or download from [gnu.org/software/wget](https://www.gnu.org/software/wget/)

**Error: "HTTP 401 Unauthorized" or "HTTP 403 Forbidden"**
- Solution: Verify credentials and authorize CDDIS
  1. Check .netrc file: `cat ~/.netrc`
  2. Verify permissions: `chmod 600 ~/.netrc`
  3. Authorize CDDIS: https://urs.earthdata.nasa.gov → Applications → Authorize Apps

**Error: "Downloaded HTML instead of binary file"**
- Solution: Authentication failed silently
  1. Verify credentials: `cat ~/.netrc` (Linux/macOS)
  2. Authorize CDDIS: https://urs.earthdata.nasa.gov → Applications
  3. Check environment variables are set correctly

**Error: "HTTP 404 Not Found"**
- Solution: Check date validity and product availability

**Error: "Could not set permissions on .netrc file"**
- Solution (Linux/macOS): Run manually: `chmod 600 ~/.netrc`
- Note: This is a security warning, not critical for functionality

## Data Access Policy

NASA CDDIS data is freely available for scientific research under NASA's Earth Science Data Policy. Attribution to data providers (IGS, CODE, UPC) is required in publications.

## References

- [NASA Earthdata Registration](https://urs.earthdata.nasa.gov)
- [CDDIS Archive Access Guide](https://www.earthdata.nasa.gov/centers/cddis-daac/archive-access)
- [CDDIS .netrc Setup](https://cddis.nasa.gov/Data_and_Derived_Products/CreateNetrcFile.html)
- [CDDIS GNSS/Ionosphere Products](https://cddis.nasa.gov/Data_and_Derived_Products/GNSS/atmospheric_products.html)
