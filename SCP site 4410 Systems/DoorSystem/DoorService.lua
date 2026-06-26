--[[
	DoorService

	Public server-sided API for SCP-style automatic doors. This service checks
	scanners, locked state, emergency lockdown, and then opens/closes door
	models without GUI, animations, or sounds.
]]

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

local DoorScannerSystem = require(ServerScriptService.DoorScannerSystem)
local SectorAccessSystem = require(ServerScriptService.SectorAccessSystem)
local DoorConfig = require(script.Parent.DoorConfig)
local DoorModelController = require(script.Parent.DoorModelController)
local DoorStateStore = require(script.Parent.DoorStateStore)

local DoorService = {}

DoorService.Status = DoorConfig.Status
DoorService.Attributes = DoorConfig.Attributes
DoorService.Tags = DoorConfig.Tags

local started = false
local globalEmergencyLockdown = false
local scannerConnections = {}
local scannerTouchTimes = {}

local function getScanOptions(doorModel)
	return {
		RequiredClearanceLevel = doorModel:GetAttribute(DoorConfig.Attributes.RequiredClearanceLevel),
		RequiredSector = doorModel:GetAttribute(DoorConfig.Attributes.RequiredSector),
	}
end

local function getAutoCloseSeconds(doorModel)
	local autoCloseSeconds = tonumber(doorModel:GetAttribute(DoorConfig.Attributes.AutoCloseSeconds))

	if autoCloseSeconds == nil then
		return DoorConfig.Defaults.AutoCloseSeconds
	end

	return math.max(0, autoCloseSeconds)
end

local function getLinkedDoorIds(scannerPart)
	local linkedDoorId = scannerPart:GetAttribute(DoorConfig.Attributes.LinkedDoorId)
	local linkedDoorIds = {}

	if linkedDoorId == nil then
		return linkedDoorIds
	end

	for doorId in string.gmatch(tostring(linkedDoorId), "[^,]+") do
		local trimmedDoorId = string.gsub(doorId, "^%s*(.-)%s*$", "%1")

		if trimmedDoorId ~= "" then
			table.insert(linkedDoorIds, trimmedDoorId)
		end
	end

	return linkedDoorIds
end

local function canScannerUse(scannerPart, player)
	local now = os.clock()
	local scannerTimes = scannerTouchTimes[scannerPart]

	if not scannerTimes then
		scannerTimes = {}
		scannerTouchTimes[scannerPart] = scannerTimes
	end

	local lastTouch = scannerTimes[player.UserId]

	if lastTouch and now - lastTouch < DoorConfig.Defaults.ScannerCooldownSeconds then
		return false
	end

	scannerTimes[player.UserId] = now

	return true
end

local function getOrCreateScannerPrompt(scannerPart)
	local prompt = scannerPart:FindFirstChildOfClass("ProximityPrompt")

	if not prompt then
		prompt = Instance.new("ProximityPrompt")
		prompt.Name = "DoorScannerPrompt"
		prompt.Parent = scannerPart
	end

	prompt.ActionText = DoorConfig.Defaults.ScannerPromptActionText
	prompt.ObjectText = DoorConfig.Defaults.ScannerPromptObjectText
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.MaxActivationDistance = DoorConfig.Defaults.ScannerPromptMaxActivationDistance
	prompt.HoldDuration = DoorConfig.Defaults.ScannerPromptHoldDuration
	prompt.RequiresLineOfSight = false

	return prompt
end

local function requestLinkedDoors(scannerPart, player)
	if not canScannerUse(scannerPart, player) then
		return
	end

	local linkedDoorIds = getLinkedDoorIds(scannerPart)

	if #linkedDoorIds == 0 then
		return
	end

	for _, linkedDoorId in ipairs(linkedDoorIds) do
		local doorModel = DoorStateStore.getDoorById(linkedDoorId)

		if doorModel then
			DoorService.requestOpen(doorModel, player)
		end
	end
end

local function playerCanOverrideRestrictions(player)
	-- X Command and Foundation Government are included through SectorAccessSystem.
	return SectorAccessSystem.playerHasOverride(player)
end

local function setLastAccess(doorModel, status, reason)
	doorModel:SetAttribute(DoorConfig.Attributes.LastAccessStatus, status)
	doorModel:SetAttribute(DoorConfig.Attributes.LastAccessReason, reason)
end

function DoorService.registerDoor(doorModel)
	return DoorStateStore.registerDoor(doorModel)
end

function DoorService.unregisterDoor(doorModel)
	DoorStateStore.unregisterDoor(doorModel)
end

function DoorService.getDoorById(doorId)
	return DoorStateStore.getDoorById(doorId)
end

function DoorService.isDoorLocked(doorModel)
	return doorModel:GetAttribute(DoorConfig.Attributes.Locked) == true
end

function DoorService.setDoorLocked(doorModel, locked)
	doorModel:SetAttribute(DoorConfig.Attributes.Locked, locked == true)
end

function DoorService.isDoorInLockdown(doorModel)
	return globalEmergencyLockdown or doorModel:GetAttribute(DoorConfig.Attributes.EmergencyLockdown) == true
end

function DoorService.setDoorLockdown(doorModel, enabled)
	doorModel:SetAttribute(DoorConfig.Attributes.EmergencyLockdown, enabled == true)
end

function DoorService.setGlobalEmergencyLockdown(enabled)
	globalEmergencyLockdown = enabled == true

	if globalEmergencyLockdown then
		for _, doorModel in ipairs(DoorStateStore.getAllDoors()) do
			DoorService.closeDoor(doorModel)
		end
	end
end

function DoorService.openDoor(doorModel)
	local state = DoorStateStore.registerDoor(doorModel)

	state.IsOpen = true
	state.AutoCloseTaskId += 1
	DoorModelController.open(doorModel)
	setLastAccess(doorModel, DoorConfig.Status.Opened, "Opened")

	local autoCloseSeconds = getAutoCloseSeconds(doorModel)

	if autoCloseSeconds > 0 then
		local taskId = state.AutoCloseTaskId

		task.delay(autoCloseSeconds, function()
			if state.AutoCloseTaskId == taskId and state.IsOpen then
				DoorService.closeDoor(doorModel)
			end
		end)
	end

	return true
end

function DoorService.closeDoor(doorModel)
	local state = DoorStateStore.registerDoor(doorModel)

	state.IsOpen = false
	state.AutoCloseTaskId += 1
	DoorModelController.close(doorModel)
	setLastAccess(doorModel, DoorConfig.Status.Closed, "Closed")

	return true
end

function DoorService.scanDoorForPlayer(doorModel, player)
	assert(typeof(player) == "Instance" and player:IsA("Player"), "Expected a Player")

	DoorStateStore.registerDoor(doorModel)

	if DoorService.isDoorInLockdown(doorModel) and not playerCanOverrideRestrictions(player) then
		setLastAccess(doorModel, DoorConfig.Status.Lockdown, "EmergencyLockdown")
		return {
			Allowed = false,
			Status = DoorConfig.Status.Lockdown,
			Reason = "EmergencyLockdown",
		}
	end

	if DoorService.isDoorLocked(doorModel) and not playerCanOverrideRestrictions(player) then
		setLastAccess(doorModel, DoorConfig.Status.Locked, "DoorLocked")
		return {
			Allowed = false,
			Status = DoorConfig.Status.Locked,
			Reason = "DoorLocked",
		}
	end

	local scannerResult = DoorScannerSystem.scanPlayer(player, getScanOptions(doorModel))

	if not scannerResult.Allowed then
		setLastAccess(doorModel, DoorConfig.Status.Denied, scannerResult.Reason)
		return scannerResult
	end

	setLastAccess(doorModel, DoorConfig.Status.Opened, scannerResult.Reason)
	return scannerResult
end

function DoorService.requestOpen(doorModel, player)
	local scannerResult = DoorService.scanDoorForPlayer(doorModel, player)

	if scannerResult.Allowed then
		DoorService.openDoor(doorModel)
	end

	return scannerResult
end

function DoorService.registerScannerPart(scannerPart)
	assert(typeof(scannerPart) == "Instance" and scannerPart:IsA("BasePart"), "Expected a scanner BasePart")

	if scannerConnections[scannerPart] then
		return
	end

	local prompt = getOrCreateScannerPrompt(scannerPart)

	scannerConnections[scannerPart] = prompt.Triggered:Connect(function(player)
		requestLinkedDoors(scannerPart, player)
	end)
end

function DoorService.unregisterScannerPart(scannerPart)
	local connection = scannerConnections[scannerPart]

	if connection then
		connection:Disconnect()
	end

	scannerConnections[scannerPart] = nil
	scannerTouchTimes[scannerPart] = nil
end

function DoorService.start()
	if started then
		return
	end

	started = true

	for _, doorModel in ipairs(CollectionService:GetTagged(DoorConfig.Tags.Door)) do
		DoorService.registerDoor(doorModel)
	end

	for _, scannerPart in ipairs(CollectionService:GetTagged(DoorConfig.Tags.Scanner)) do
		if scannerPart:IsA("BasePart") then
			DoorService.registerScannerPart(scannerPart)
		end
	end

	CollectionService:GetInstanceAddedSignal(DoorConfig.Tags.Door):Connect(function(doorModel)
		DoorService.registerDoor(doorModel)
	end)

	CollectionService:GetInstanceRemovedSignal(DoorConfig.Tags.Door):Connect(function(doorModel)
		DoorService.unregisterDoor(doorModel)
	end)

	CollectionService:GetInstanceAddedSignal(DoorConfig.Tags.Scanner):Connect(function(scannerPart)
		if scannerPart:IsA("BasePart") then
			DoorService.registerScannerPart(scannerPart)
		end
	end)

	CollectionService:GetInstanceRemovedSignal(DoorConfig.Tags.Scanner):Connect(function(scannerPart)
		DoorService.unregisterScannerPart(scannerPart)
	end)
end

return DoorService
