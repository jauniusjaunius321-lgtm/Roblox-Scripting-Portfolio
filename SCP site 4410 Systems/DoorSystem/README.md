# Door System

The Door System controls door state, opening requests, and physical door behavior.

## Overview

- `DoorService.lua` receives open requests and validates whether a player can open a door.
- `DoorStateStore.lua` stores door records by `DoorId`.
- `DoorModelController.lua` applies the physical open/closed state to door models.
- `DoorConfig.lua` defines door tags and shared configuration.
- `Bootstrap.server.lua` starts the system on the server.

## Door Linking

Each door should have a `DoorId`. A scanner should use `LinkedDoorId` to point to the matching door.
