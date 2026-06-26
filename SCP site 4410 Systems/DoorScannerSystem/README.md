# Door & Scanner System

The Door Scanner System validates player access for secured doors and returns structured scan results to the Door System.

## Overview

- `DoorScannerService.lua` checks clearance levels, keycards, and administrator access.
- `DoorScannerResult.lua` defines scan result data such as allowed state, status, and reason.
- `DoorScannerConfig.lua` stores scanner-related configuration.
- `init.lua` exposes the scanner service to other server systems.

## Usage

A scanner is linked to a door through `LinkedDoorId`. When a player presses `E`, the Door System asks the scanner to validate access before opening the door.
