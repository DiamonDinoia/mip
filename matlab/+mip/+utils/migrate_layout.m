function migrate_layout()
%MIGRATE_LAYOUT   Migrate packages from flat layout to namespaced layout.
%
% Old layout: ~/.mip/packages/<package_name>/
% New layout: ~/.mip/packages/<org>/<channel>/<package_name>/
%
% This runs once on first use after the upgrade. It moves all existing
% flat packages into mip-org/core/<package_name>/ and updates
% directly_installed.txt to use fully qualified names.

packagesDir = mip.utils.get_packages_dir();

if ~exist(packagesDir, 'dir')
    return
end

% Check if migration is needed by looking for a migration marker
markerFile = fullfile(packagesDir, '.migrated_v2');
if exist(markerFile, 'file')
    return
end

% Detect old-style layout: look for package directories that are NOT
% org directories (i.e., they contain mip.json or load_package.m directly)
dirContents = dir(packagesDir);
oldPackages = {};

for i = 1:length(dirContents)
    if ~dirContents(i).isdir || startsWith(dirContents(i).name, '.')
        continue
    end
    name = dirContents(i).name;
    pkgPath = fullfile(packagesDir, name);

    % A flat package has mip.json or load_package.m at the top level
    if exist(fullfile(pkgPath, 'mip.json'), 'file') || ...
       exist(fullfile(pkgPath, 'load_package.m'), 'file')
        oldPackages{end+1} = name; %#ok<AGROW>
    end
end

if ~isempty(oldPackages)
    fprintf('Migrating %d package(s) to namespaced layout...\n', length(oldPackages));

    % Read old channel_map.json if it exists
    channelMap = struct();
    channelMapFile = fullfile(packagesDir, 'channel_map.json');
    if exist(channelMapFile, 'file')
        try
            channelMap = jsondecode(fileread(channelMapFile));
        catch
        end
    end

    % Move each package to its namespaced location
    for i = 1:length(oldPackages)
        name = oldPackages{i};
        oldPath = fullfile(packagesDir, name);

        % Determine org/channel from channel_map, default to mip-org/core
        if isfield(channelMap, name)
            ch = channelMap.(name);
            [org, channelName] = mip.utils.parse_channel_spec(ch);
        else
            org = 'mip-org';
            channelName = 'core';
        end

        newPath = fullfile(packagesDir, org, channelName, name);

        % Create parent directories
        parentDir = fullfile(packagesDir, org, channelName);
        if ~exist(parentDir, 'dir')
            mkdir(parentDir);
        end

        % Move the package
        try
            movefile(oldPath, newPath);
            fprintf('  Migrated "%s" -> %s/%s/%s\n', name, org, channelName, name);
        catch ME
            warning('mip:migrationFailed', ...
                    'Failed to migrate package "%s": %s', name, ME.message);
        end
    end

    % Update directly_installed.txt to use FQNs
    directFile = fullfile(packagesDir, 'directly_installed.txt');
    if exist(directFile, 'file')
        oldDirectly = mip.utils.get_directly_installed();
        newDirectly = {};
        for i = 1:length(oldDirectly)
            name = oldDirectly{i};
            % If already a FQN, keep as-is
            if contains(name, '/')
                newDirectly{end+1} = name; %#ok<AGROW>
                continue
            end
            % Convert bare name to FQN
            if isfield(channelMap, name)
                ch = channelMap.(name);
                [org, channelName] = mip.utils.parse_channel_spec(ch);
            else
                org = 'mip-org';
                channelName = 'core';
            end
            newDirectly{end+1} = mip.utils.make_fqn(org, channelName, name); %#ok<AGROW>
        end
        mip.utils.set_directly_installed(newDirectly);
    end

    % Remove old channel_map.json (no longer needed)
    if exist(channelMapFile, 'file')
        delete(channelMapFile);
    end

    fprintf('Migration complete.\n');
end

% Write migration marker
fid = fopen(markerFile, 'w');
fprintf(fid, 'Migrated to namespaced layout on %s\n', datestr(now));
fclose(fid);

end
