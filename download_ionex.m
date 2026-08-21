function filepath = download_ionex(target_date, varargin)
% DOWNLOAD_IONEX  Download and extract IONEX files from NASA CDDIS archive
%
% SYNTAX:
%   filepath = download_ionex(target_date)
%   filepath = download_ionex(target_date, 'Product', 'UQRG')
%   filepath = download_ionex(target_date, 'Resolution', '15M')
%
% INPUTS:
%   target_date  - datetime object or date string (e.g., '2026-01-03')
%
% OPTIONAL PARAMETERS (Name-Value pairs):
%   'Product'    - IONEX product type: 'UPC0OPSRAP' (default), 'UPC0OPSFIN', 'UQRG'
%   'Resolution' - Temporal resolution: '15M' (default), '01H', '02H'
%   'DataDir'    - Local data directory (default: './data/')
%   'Force'      - Force redownload even if file exists (default: false)
%   'Username'   - NASA Earthdata username (or set env var EARTHDATA_USER)
%   'Password'   - NASA Earthdata password (or set env var EARTHDATA_PASS)
%
% OUTPUT:
%   filepath     - Full path to extracted IONEX file (.INX)
%
% EXAMPLE:
%   % Download UPC Rapid 15-min resolution for 2026-01-03
%   file = download_ionex(datetime('2026-01-03'));
%   ds = read_ionex(file);
%
% NOTES:
%   - Requires NASA Earthdata credentials (register at urs.earthdata.nasa.gov)
%   - Downloaded files are cached in data/ directory
%   - Automatically extracts .gz files
%
% Carlos Molina
% UPC-IEEC
% 20-Aug-2026

    % Validate target date
    if ~isdatetime(target_date) && ~ischar(target_date) && ~isstring(target_date)
        error('Input must be a datetime object or date string.');
    end
    
    % Parse optional inputs
    p = inputParser;
    addParameter(p, 'Product', 'UPC0OPSRAP', @ischar);
    addParameter(p, 'Resolution', '15M', @ischar);
    addParameter(p, 'DataDir', './data/', @ischar);
    addParameter(p, 'Force', false, @islogical);
    addParameter(p, 'Username', '', @ischar);
    addParameter(p, 'Password', '', @ischar);
    parse(p, varargin{:});
    
    opts = p.Results;
    
    % Convert target date to datetime
    if ischar(target_date) || isstring(target_date)
        target_date = datetime(target_date);
    end
    
    % Extract year and day-of-year
    yyyy = year(target_date);
    doy = day(target_date, 'dayofyear');
    
    % Build filename pattern
    filename = build_ionex_filename(opts.Product, yyyy, doy, opts.Resolution);
    
    % Check local cache
    local_dir = fullfile(opts.DataDir, sprintf('%04d', yyyy), sprintf('%03d', doy));
    if ~exist(local_dir, 'dir')
        mkdir(local_dir);
    end
    
    extracted_file = fullfile(local_dir, strrep(filename, '.gz', ''));
    
    if exist(extracted_file, 'file') && ~opts.Force
        fprintf('File already exists (cached): %s\n', extracted_file);
        filepath = extracted_file;
        return;
    end
    
    % Build CDDIS URL
    base_url = 'https://cddis.nasa.gov/archive/gnss/products/ionosphere';
    remote_url = sprintf('%s/%04d/%03d/%s', base_url, yyyy, doy, filename);
    
    % Get credentials
    [username, password] = get_earthdata_credentials(opts.Username, opts.Password);
    
    % Download file with retry logic
    fprintf('Downloading: %s\n', filename);
    gz_file = fullfile(local_dir, filename);
    
    % Configure web options with proper User-Agent
    web_opts = weboptions('Username', username, ...
                          'Password', password, ...
                          'Timeout', 180, ...
                          'UserAgent', 'MATLAB-IONEX-Reader/1.0 (carlos.molina@upc.edu)', ...
                          'ContentType', 'auto');
    
    % Retry logic with exponential backoff
    max_retries = 3;
    retry_delay = 5;  % seconds
    
    for attempt = 1:max_retries
        try
            if attempt > 1
                fprintf('  Retry attempt %d/%d (waiting %ds)...\n', attempt-1, max_retries-1, retry_delay);
                pause(retry_delay);
                retry_delay = retry_delay * 2;  % Exponential backoff
            end
            
            websave(gz_file, remote_url, web_opts);
            fprintf('Download complete.\n');
            break;  % Success, exit retry loop
            
        catch ME
            if attempt == max_retries
                % Final attempt failed, provide detailed error
                if contains(ME.message, 'timed out') || contains(ME.message, 'Timeout')
                    error(['Download failed: Connection timeout\n' ...
                           'This may indicate:\n' ...
                           '  1. Network congestion or slow connection\n' ...
                           '  2. IP temporarily blocked by CDDIS (rate limiting)\n' ...
                           '  3. File is very large (>10MB)\n' ...
                           'Solutions:\n' ...
                           '  - Wait 5-10 minutes and try again\n' ...
                           '  - Use different network (mobile data, VPN)\n' ...
                           '  - Check CDDIS status: https://cddis.nasa.gov\n' ...
                           'URL: %s'], remote_url);
                elseif contains(ME.message, '403') || contains(ME.message, 'Forbidden')
                    error(['Download failed: Access Forbidden (403)\n' ...
                           'Possible causes:\n' ...
                           '  1. CDDIS application not authorized in Earthdata account\n' ...
                           '  2. Invalid credentials\n' ...
                           'Visit: https://urs.earthdata.nasa.gov → Applications → Authorize CDDIS\n' ...
                           'URL: %s'], remote_url);
                elseif contains(ME.message, '401') || contains(ME.message, 'Unauthorized')
                    error(['Download failed: Unauthorized (401)\n' ...
                           'Check credentials:\n' ...
                           '  Username: %s\n' ...
                           '  Password: (hidden)\n' ...
                           'URL: %s'], username, remote_url);
                elseif contains(ME.message, '404') || contains(ME.message, 'Not Found')
                    error(['Download failed: File Not Found (404)\n' ...
                           'Date: %s (DoY %03d)\n' ...
                           'Product: %s @ %s\n' ...
                           'Verify date is valid and data is available.\n' ...
                           'URL: %s'], datestr(target_date), doy, opts.Product, opts.Resolution, remote_url);
                else
                    error('Download failed after %d attempts: %s\nURL: %s', max_retries, ME.message, remote_url);
                end
            end
            % Continue to next retry if not final attempt
        end
    end
    
    % Extract gunzip
    fprintf('Extracting: %s\n', filename);
    gunzip(gz_file, local_dir);
    
    % Clean up .gz file (optional)
    delete(gz_file);
    
    filepath = extracted_file;
    fprintf('Ready: %s\n', filepath);
end

%% Helper Functions

function filename = build_ionex_filename(product, year, doy, resolution)
    % Build IONEX filename following CDDIS naming convention
    % Pattern: PRODUCT_YYYYDDD0000_01D_RES_GIM.INX.gz
    
    date_str = sprintf('%04d%03d0000', year, doy);
    filename = sprintf('%s_%s_01D_%s_GIM.INX.gz', product, date_str, resolution);
end

function [username, password] = get_earthdata_credentials(user_input, pass_input)
    % Retrieve NASA Earthdata credentials from inputs or environment variables
    
    if ~isempty(user_input) && ~isempty(pass_input)
        username = user_input;
        password = pass_input;
        return;
    end
    
    % Try environment variables
    username = getenv('EARTHDATA_USER');
    password = getenv('EARTHDATA_PASS');
    
    if isempty(username) || isempty(password)
        error(['NASA Earthdata credentials not found.\n' ...
               'Provide as arguments or set environment variables:\n' ...
               '  export EARTHDATA_USER=your_username\n' ...
               '  export EARTHDATA_PASS=your_password\n' ...
               'Register at: https://urs.earthdata.nasa.gov']);
    end
end
