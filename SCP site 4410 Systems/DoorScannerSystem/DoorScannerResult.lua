--[[
	DoorScannerResult

	Builds consistent scanner result tables. Door scripts can use these values
	to decide what to do next without needing to know how access was checked.
]]

local DoorScannerConfig = require(script.Parent.DoorScannerConfig)

local DoorScannerResult = {}

function DoorScannerResult.new(allowed, reason, details)
	details = details or {}

	return {
		Allowed = allowed,
		Status = allowed and DoorScannerConfig.Status.AccessGranted or DoorScannerConfig.Status.AccessDenied,
		Reason = reason,
		RequiredClearanceLevel = details.RequiredClearanceLevel,
		RequiredSector = details.RequiredSector,
		PlayerAccessLevel = details.PlayerAccessLevel,
		SectorResult = details.SectorResult,
	}
end

return DoorScannerResult
