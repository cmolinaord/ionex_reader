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

**Error: "Download failed: Forbidden (403)"**
- Solution: Authorize CDDIS application in Earthdata profile

**Error: "Download failed: Unauthorized (401)"**
- Solution: Verify username/password

**Error: "Download failed: Not Found (404)"**
- Solution: Check date validity and product availability

## Data Access Policy

NASA CDDIS data is freely available for scientific research under NASA's Earth Science Data Policy. Attribution to data providers (IGS, CODE, UPC) is required in publications.

## References

- [NASA Earthdata Registration](https://urs.earthdata.nasa.gov)
- [CDDIS Archive Guide](https://cddis.nasa.gov/Data_and_Derived_Products/GNSS/atmospheric_products.html)
