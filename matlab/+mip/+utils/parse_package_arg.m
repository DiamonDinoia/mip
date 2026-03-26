function result = parse_package_arg(arg)
%PARSE_PACKAGE_ARG   Parse a package argument into its components.
%
% Handles both bare names and fully qualified names (org/channel/package).
%
% Args:
%   arg - Package string: 'package_name' or 'org/channel/package_name'
%
% Returns:
%   result - Struct with fields:
%     .name    - Package name (always set)
%     .org     - Organization (empty if bare name)
%     .channel - Channel name (empty if bare name)
%     .is_fqn  - True if fully qualified
%
% Examples:
%   r = parse_package_arg('chebfun')
%     -> name='chebfun', org='', channel='', is_fqn=false
%
%   r = parse_package_arg('mip-org/core/chebfun')
%     -> name='chebfun', org='mip-org', channel='core', is_fqn=true

parts = strsplit(arg, '/');

if length(parts) == 1
    result.name = parts{1};
    result.org = '';
    result.channel = '';
    result.is_fqn = false;
elseif length(parts) == 3
    result.org = parts{1};
    result.channel = parts{2};
    result.name = parts{3};
    result.is_fqn = true;
else
    error('mip:invalidPackageSpec', ...
          'Invalid package spec "%s". Use "package" or "org/channel/package".', arg);
end

end
