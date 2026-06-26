--[[
	DoorConfig

	Central settings, attribute names, and CollectionService tags for doors.
	Door models can override these values through attributes.
]]

local DoorConfig = {}

DoorConfig.Tags = {
	Door = "SCPDoor",
	Scanner = "SCPDoorScanner",
}

DoorConfig.Attributes = {
	DoorId = "DoorId",
	LinkedDoorId = "LinkedDoorId",
	RequiredClearanceLevel = "RequiredClearanceLevel",
	RequiredSector = "RequiredSector",
	AutoCloseSeconds = "AutoCloseSeconds",
	Locked = "Locked",
	EmergencyLockdown = "EmergencyLockdown",
	IsOpen = "IsOpen",
	LastAccessStatus = "LastAccessStatus",
	LastAccessReason = "LastAccessReason",
}

DoorConfig.Defaults = {
	AutoCloseSeconds = 5,
	OpenTransparency = 0.65,
	ScannerCooldownSeconds = 1,
	ScannerPromptActionText = "Scan",
	ScannerPromptObjectText = "Door Scanner",
	ScannerPromptMaxActivationDistance = 10,
	ScannerPromptHoldDuration = 0,
}

DoorConfig.Status = {
	Opened = "Opened",
	Closed = "Closed",
	Denied = "Denied",
	Locked = "Locked",
	Lockdown = "Lockdown",
}

return DoorConfig
