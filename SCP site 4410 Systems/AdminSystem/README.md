# Admin System

The Admin System provides a server-authorized admin panel for managing player clearance and keycard access.

## Overview

- `ServerScriptService/AdminPanel.server.lua` validates administrator access and executes server-side actions.
- `StarterPlayer/StarterPlayerScripts/AdminPanel/AdminPanelUI.lua` builds the client-side admin panel interface.
- `StarterPlayer/StarterPlayerScripts/AdminPanel/AdminPanelController.lua` connects the UI to server remotes.
- `StarterPlayer/StarterPlayerScripts/AdminPanel/init.client.lua` starts the admin panel client.

## Features

- Grant player clearance levels.
- Grant standard keycards.
- Grant administrator keycards.
- Grant temporary keycards with time limits.

## Security

The client only displays the interface and sends requests. All permission checks and privileged actions are handled on the server. This exported copy does not include personal Roblox user IDs.
