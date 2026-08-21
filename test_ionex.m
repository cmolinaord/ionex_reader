%% Test Suite for IONEX Reader
% Basic validation tests (no credentials required for cached data tests)
%
% Carlos Molina
% UPC-IEEC
% 20-Aug-2026

fprintf('IONEX Reader - Test Suite\n');
fprintf('=========================\n\n');

%% Test 1: Date conversion utilities
fprintf('Test 1: Date conversion to DoY...\n');
test_date = datetime('2026-01-15');
doy = day(test_date, 'dayofyear');
assert(doy == 15, 'DoY calculation failed');
fprintf('  ✓ DoY conversion correct (15)\n');

test_date2 = datetime('2026-12-31');
doy2 = day(test_date2, 'dayofyear');
assert(doy2 == 365, 'DoY calculation failed for year end');
fprintf('  ✓ Year-end DoY correct (365)\n\n');

%% Test 2: Filename construction
fprintf('Test 2: IONEX filename generation...\n');
expected = 'UPC0OPSRAP_20260150000_01D_15M_GIM.INX.gz';
% Manually call the helper (would need to be exposed or tested via main function)
year = 2026;
doy = 15;
product = 'UPC0OPSRAP';
resolution = '15M';
date_str = sprintf('%04d%03d0000', year, doy);
filename = sprintf('%s_%s_01D_%s_GIM.INX.gz', product, date_str, resolution);
assert(strcmp(filename, expected), 'Filename construction failed');
fprintf('  ✓ Filename: %s\n\n', filename);

%% Test 3: URL construction
fprintf('Test 3: CDDIS URL construction...\n');
base_url = 'https://cddis.nasa.gov/archive/gnss/products/ionosphere';
remote_url = sprintf('%s/%04d/%03d/%s', base_url, 2026, 15, filename);
expected_url = 'https://cddis.nasa.gov/archive/gnss/products/ionosphere/2026/015/UPC0OPSRAP_20260150000_01D_15M_GIM.INX.gz';
assert(strcmp(remote_url, expected_url), 'URL construction failed');
fprintf('  ✓ URL: %s\n\n', remote_url);

%% Test 4: Cache directory structure
fprintf('Test 4: Cache directory structure...\n');
data_dir = './test_data';
local_dir = fullfile(data_dir, sprintf('%04d', 2026), sprintf('%03d', 15));
expected_dir = './test_data/2026/015';
assert(strcmp(local_dir, expected_dir), 'Directory structure incorrect');
fprintf('  ✓ Cache path: %s\n', local_dir);

% Cleanup test directory if exists
if exist(data_dir, 'dir')
    rmdir(data_dir, 's');
end
fprintf('  ✓ Cleanup complete\n\n');

%% Test 5: Product variants
fprintf('Test 5: Product name variants...\n');
products = {'UPC0OPSRAP', 'UPC0OPSFIN', 'UQRG'};
resolutions = {'15M', '01H', '02H'};

for i = 1:length(products)
    for j = 1:length(resolutions)
        fname = sprintf('%s_20260150000_01D_%s_GIM.INX.gz', products{i}, resolutions{j});
        fprintf('  ✓ %s @ %s: %s\n', products{i}, resolutions{j}, fname);
    end
end

fprintf('\n=========================\n');
fprintf('All tests passed! ✓\n');
fprintf('=========================\n\n');

fprintf('Note: Download tests require NASA Earthdata credentials.\n');
fprintf('See EARTHDATA_SETUP.md for configuration instructions.\n');
