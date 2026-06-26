--[[
	DoorScannerSystem

	Server-sided entry point for SCP-style door scanner access checks. Future
	door scripts can require this ModuleScript and ask whether a player should
	be allowed through.
]]

local DoorScannerService = require(script.DoorScannerService)

return DoorScannerService
