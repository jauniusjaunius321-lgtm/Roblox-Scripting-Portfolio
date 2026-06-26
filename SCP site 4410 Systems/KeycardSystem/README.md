# Keycard System

The Keycard System creates, grants, restores, and validates digital keycards for players.

## Overview

- `KeycardConfig.lua` defines clearance levels, keycard names, attributes, and administrator keycard settings.
- `KeycardFactory.lua` creates keycard instances with the required attributes.
- `KeycardService.lua` grants keycards, restores temporary grants, and checks player access.
- `KeycardTemporaryStore.lua` stores temporary keycard grants across servers.
- `init.lua` exposes the keycard service to other server scripts.

## Clearance Model

Standard keycards use clearance levels up to `10`. Administrator keycards use level `11` to avoid conflicts with public level `10` access.
