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
%   - Credentials stored in .netrc file (created automatically)
%   - Uses wget for downloads (handles OAuth authentication properly)
%   - Downloaded files are cached in data/ directory
%   - Automatically extracts .gz files
%
% SYSTEM REQUIREMENTS:
%   - wget must be installed
%   - Linux/macOS: pre-installed or install via package manager
%   - Windows: Use WSL or download from gnu.org/software/wget/
%
% Carlos Molina
% UPC-IEEC
% 21-Aug-2026

    % Display version
    fprintf('IONEX Reader v%s - Download Module\n', get_version());
    
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
    
    % Get credentials and ensure .netrc file exists
    [username, password] = get_earthdata_credentials(opts.Username, opts.Password);
    setup_netrc_file(username, password);
    
    % Download file using curl (handles OAuth redirects properly)
    fprintf('Downloading: %s\n', filename);
    gz_file = fullfile(local_dir, filename);
    
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
            
            % Use wget with .netrc authentication (handles OAuth properly)
            download_with_wget(remote_url, gz_file);
            fprintf('Download complete.\n');
            break;  % Success, exit retry loop
            
        catch ME
            if attempt == max_retries
                % Final attempt failed, provide detailed error
                if contains(ME.message, 'timed out') || contains(ME.message, 'Timeout') || contains(ME.message, 'Operation too slow')
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
                           'Solutions:\n' ...
                           '  - Visit: https://urs.earthdata.nasa.gov → Applications → Authorize CDDIS\n' ...
                           '  - Check .netrc file in home directory\n' ...
                           'URL: %s'], remote_url);
                elseif contains(ME.message, '401') || contains(ME.message, 'Unauthorized')
                    error(['Download failed: Unauthorized (401)\n' ...
                           'Check credentials in .netrc file:\n' ...
                           '  Username: %s\n' ...
                           '  File: %s\n' ...
                           'URL: %s'], username, fullfile(get_home_dir(), '.netrc'), remote_url);
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

function setup_netrc_file(username, password)
    % Create or update .netrc file for curl authentication
    % Format: machine urs.earthdata.nasa.gov login <user> password <pass>
    
    home_dir = get_home_dir();
    netrc_file = fullfile(home_dir, '.netrc');
    
    % Define the required entry
    required_machine = 'urs.earthdata.nasa.gov';
    required_entry = sprintf('machine %s login %s password %s', required_machine, username, password);
    
    % Check if .netrc exists and has correct entry
    if exist(netrc_file, 'file')
        content = fileread(netrc_file);
        
        % Check if our machine is already configured
        if contains(content, required_machine)
            % Parse existing entry
            pattern = sprintf('machine\\s+%s\\s+login\\s+(\\S+)\\s+password\\s+(\\S+)', required_machine);
            tokens = regexp(content, pattern, 'tokens');
            
            if ~isempty(tokens)
                existing_user = tokens{1}{1};
                existing_pass = tokens{1}{2};
                
                % If credentials match, nothing to do
                if strcmp(existing_user, username) && strcmp(existing_pass, password)
                    return;
                else
                    % Update existing entry
                    old_entry = sprintf('machine %s login %s password %s', required_machine, existing_user, existing_pass);
                    content = strrep(content, old_entry, required_entry);
                end
            end
        else
            % Append new machine entry
            if ~endsWith(content, newline)
                content = [content newline];
            end
            content = [content required_entry newline];
        end
    else
        % Create new .netrc file
        content = [required_entry newline];
    end
    
    % Write .netrc file
    fid = fopen(netrc_file, 'w');
    if fid == -1
        error('Cannot create .netrc file: %s', netrc_file);
    end
    fprintf(fid, '%s', content);
    fclose(fid);
    
    % Set proper permissions (read/write for owner only)
    if isunix || ismac
        [status, ~] = system(sprintf('chmod 600 "%s"', netrc_file));
        if status ~= 0
            warning('Could not set permissions on .netrc file. Run: chmod 600 %s', netrc_file);
        end
    end
end

function home_dir = get_home_dir()
    % Get user's home directory (cross-platform)
    
    if ispc
        home_dir = getenv('USERPROFILE');
    else
        home_dir = getenv('HOME');
    end
    
    if isempty(home_dir)
        error('Cannot determine home directory');
    end
end

function download_with_wget(url, output_file)
    % Download file using wget with .netrc authentication
    % This properly handles NASA Earthdata OAuth redirects
    
    % Verify .netrc exists
    netrc_file = fullfile(get_home_dir(), '.netrc');
    if ~exist(netrc_file, 'file')
        error('.netrc file not found: %s\nThis should have been created automatically.', netrc_file);
    end
    
    % Build wget command with NASA CDDIS recommended flags
    % --auth-no-challenge: send credentials from .netrc proactively
    download_cmd = sprintf(['wget --auth-no-challenge ' ...
                            '--user-agent="MATLAB-IONEX-Reader/1.0" ' ...
                            '-O "%s" "%s"'], output_file, url);
    
    % Unset LD_LIBRARY_PATH on Unix to avoid MATLAB library conflicts
    if isunix
        download_cmd = sprintf('unset LD_LIBRARY_PATH; %s', download_cmd);
    end
    
    % Execute wget
    [status, output] = system(download_cmd);
    
    if status ~= 0
        % Parse wget error codes
        if contains(output, '401') || contains(output, 'Unauthorized')
            error('HTTP 401 Unauthorized: Check credentials in .netrc file.');
        elseif contains(output, '403') || contains(output, 'Forbidden')
            error('HTTP 403 Forbidden: Authorize CDDIS in Earthdata account.');
        elseif contains(output, '404') || contains(output, 'Not Found')
            error('HTTP 404 Not Found: File does not exist on server.');
        elseif contains(output, 'certificate') || contains(output, 'SSL')
            error('SSL/TLS error: %s', output);
        else
            error('wget failed (exit code %d): %s', status, output);
        end
    end
    
    % Verify downloaded file exists and is not empty
    if ~exist(output_file, 'file')
        error('Download completed but file not found: %s', output_file);
    end
    
    file_info = dir(output_file);
    if file_info.bytes == 0
        delete(output_file);
        error('Downloaded file is empty (0 bytes)');
    end
    
    % Check if file is HTML (common error when auth fails)
    fid = fopen(output_file, 'r');
    header = fread(fid, min(1024, file_info.bytes), '*char')';
    fclose(fid);
    
    if contains(header, '<html') || contains(header, '<!DOCTYPE')
        delete(output_file);
        error(['Downloaded HTML instead of binary file.\n' ...
               'This indicates authentication failure.\n' ...
               'Solutions:\n' ...
               '  1. Verify Earthdata credentials\n' ...
               '  2. Authorize CDDIS at: https://urs.earthdata.nasa.gov\n' ...
               '  3. Check .netrc file: %s'], fullfile(get_home_dir(), '.netrc'));
    end
end
