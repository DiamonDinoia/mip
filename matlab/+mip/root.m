function root = root()
%ROOT   Get the mip root directory path.
%   ROOT() returns the path to the mip root directory by determining where
%   this package is installed. Assumes the layout:
%     <root>/packages/mip-org/core/mip/mip/+mip/root.m

% Navigate up from this file's location:
%   +mip/root -> +mip -> mip (source) -> mip (package) -> core -> mip-org -> packages -> root
this_dir = fileparts(mfilename('fullpath'));   % .../+mip
source_dir = fileparts(this_dir);             % .../mip/mip
package_dir = fileparts(source_dir);          % .../core/mip
channel_dir = fileparts(package_dir);         % .../mip-org/core
org_dir = fileparts(channel_dir);             % .../packages/mip-org
packages_dir = fileparts(org_dir);            % .../packages
root = fileparts(packages_dir);               % .../root

end
