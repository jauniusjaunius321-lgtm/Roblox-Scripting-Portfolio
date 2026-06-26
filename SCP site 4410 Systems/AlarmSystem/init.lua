--[[
	AlarmSystem

	Independent alarm system that reacts to AccessControlSystem status changes.
]]

local AlarmService = require(script.AlarmService)
local AlarmDisplay = require(script.AlarmDisplay)
local AlarmLights = require(script.AlarmLights)
local AlarmSounds = require(script.AlarmSounds)
local AlarmTerminalService = require(script.AlarmTerminalService)

AlarmService.start()
AlarmDisplay.start()
AlarmLights.start()
AlarmSounds.start()
AlarmTerminalService.start()

return AlarmService
