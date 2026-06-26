--[[
	DoorSystem Bootstrap

	Starts automatic registration for tagged door models and scanner parts.
	This script does not create GUI, animations, or sounds.
]]

local ServerScriptService = game:GetService("ServerScriptService")

local ServerRuntimeMode = require(ServerScriptService.ServerSynchronizationHub.ServerRuntimeMode)

if ServerRuntimeMode.isSynchronizationHub() then
	return
end

local DoorSystem = require(ServerScriptService.DoorSystem)

DoorSystem.start()
