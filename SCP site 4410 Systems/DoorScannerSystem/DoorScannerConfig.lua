--[[
	DoorScannerConfig

	Default scanner settings and status names. Keeping these values separate
	makes it easier to expand scanner behavior later without touching the core
	access logic.
]]

local DoorScannerConfig = {}

DoorScannerConfig.Status = {
	AccessGranted = "AccessGranted",
	AccessDenied = "AccessDenied",
}

DoorScannerConfig.Reasons = {
	AccessGranted = "AccessGranted",
	RoleOverride = "RoleOverride",
	FullAccessOverride = "FullAccessOverride",
	ClearanceMet = "ClearanceMet",
	SectorAccessGranted = "SectorAccessGranted",
	MissingRequirement = "MissingRequirement",
	ClearanceTooLow = "ClearanceTooLow",
	SectorAccessDenied = "SectorAccessDenied",
	UnknownSector = "UnknownSector",
}

DoorScannerConfig.DefaultScanOptions = {
	-- A scanner with no configured sector or clearance acts as public access.
	-- Door models can still restrict access with their own attributes.
	RequiredClearanceLevel = 0,
	RequiredSector = nil,
}

return DoorScannerConfig
