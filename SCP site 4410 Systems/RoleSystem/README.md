# Role & Permission System

The Role & Permission System stores player roles and exposes permission checks for other gameplay systems.

## Overview

- `RoleDefinitions.lua` defines available roles, permissions, and administrator flags.
- `RoleService.lua` checks player roles, permissions, and administrator status.
- `PlayerRoleStore.lua` persists player roles through DataStore.
- `init.lua` exposes the role service to other server systems.

## Integration

Other systems, including doors, sectors, reactor controls, and the admin panel, can query this system to determine whether a player has the required permission.
