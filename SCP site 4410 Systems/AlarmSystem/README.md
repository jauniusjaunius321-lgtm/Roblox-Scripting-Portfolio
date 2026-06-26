# Alarm System

The Alarm System controls facility-wide alarm states such as lockdown, maintenance, and emergency modes.

## Overview

- `AlarmService.lua` stores the active alarm state and notifies dependent services when it changes.
- `AlarmConfig.lua` defines display text, color, flash speed, sound, and volume for each alarm type.
- `AlarmLights.lua` controls LED strips and light instances.
- `AlarmSounds.lua` plays alarm audio when configured.
- `AlarmDisplay.lua` updates alarm display panels.
- `AlarmTerminalService.lua` creates the `E` interaction prompt for alarm terminals.
- `TestService.lua` can be used to quickly cycle through alarm states during testing.

## Terminal Setup

Name a part or model `AlarmTerminal`. The system automatically creates a `ProximityPrompt`, allowing players to press `E` and open the alarm control terminal.
