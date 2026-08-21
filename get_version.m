function version = get_version()
% GET_VERSION  Read version string from VERSION file
%
% SYNTAX:
%   version = get_version()
%
% OUTPUT:
%   version  - Version string (e.g., '0.1.0')
%
% DESCRIPTION:
%   Reads the VERSION file in the ionex_reader root directory and returns
%   the version string as a trimmed character array.
%
% Carlos Molina
% UPC-IEEC
% 21-Aug-2026

    % Get the path to this function's directory
    func_dir = fileparts(mfilename('fullpath'));
    version_file = fullfile(func_dir, 'VERSION');
    
    % Read version file
    if isfile(version_file)
        fid = fopen(version_file, 'r');
        version = strtrim(fgetl(fid));
        fclose(fid);
    else
        warning('VERSION file not found. Using default version.');
        version = '0.0.0-unknown';
    end
end
