function depList = build_dependency_graph(packageFqn, packageInfoMap, defaultOrg, defaultChannel, visited, path)
%BUILD_DEPENDENCY_GRAPH   Recursively build dependency graph for a package.
%
% Args:
%   packageFqn     - Fully qualified package name (org/channel/name)
%   packageInfoMap - containers.Map of FQN -> package info
%   defaultOrg     - Default organization for resolving bare-name dependencies
%   defaultChannel - Default channel for resolving bare-name dependencies
%   visited        - (Optional) Cell array of already visited FQNs
%   path           - (Optional) Cell array representing current dependency path
%
% Returns:
%   depList - Cell array of FQNs in dependency order (dependencies first)
%
% Example:
%   deps = mip.dependency.build_dependency_graph('mip-org/core/mypackage', pkgMap, 'mip-org', 'core');

if nargin < 5
    visited = {};
end
if nargin < 6
    path = {};
end

% Check for circular dependency
if ismember(packageFqn, path)
    cycle = strjoin([path, {packageFqn}], ' -> ');
    error('mip:circularDependency', ...
          'Circular dependency detected: %s', cycle);
end

% If already visited, skip
if ismember(packageFqn, visited)
    depList = {};
    return
end

% Find package info
if ~isKey(packageInfoMap, packageFqn)
    error('mip:packageNotFound', ...
          'Package "%s" not found in repository', packageFqn);
end
pkgInfo = packageInfoMap(packageFqn);

% Mark as visited and add to path
visited = [visited, {packageFqn}];
path = [path, {packageFqn}];

% Collect all dependencies first
depList = {};
dependencies = pkgInfo.dependencies;
% Handle empty arrays (jsondecode returns 0x0 double for [])
if isempty(dependencies) || (isnumeric(dependencies) && isempty(dependencies))
    dependencies = {};
elseif ~iscell(dependencies)
    dependencies = {dependencies};
end

for i = 1:length(dependencies)
    dep = dependencies{i};
    depResult = mip.utils.parse_package_arg(dep);
    if depResult.is_fqn
        depFqn = dep;
    else
        depFqn = mip.utils.make_fqn(defaultOrg, defaultChannel, depResult.name);
    end

    % If dep is from a different channel and not in the map, skip it
    % (cross-channel dependency assumed to be pre-installed)
    if ~isKey(packageInfoMap, depFqn)
        continue
    end

    subDeps = mip.dependency.build_dependency_graph(depFqn, packageInfoMap, defaultOrg, defaultChannel, visited, path);
    depList = [depList, subDeps]; %#ok<*AGROW>
end

% Then add this package
depList = [depList, {packageFqn}];

end
