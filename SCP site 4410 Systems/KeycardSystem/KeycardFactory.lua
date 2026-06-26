--[[
	KeycardFactory

	Creates server-owned Roblox Tool instances that represent keycards.
	Only data needed for future access checks is added here.
]]

local ServerScriptService = game:GetService("ServerScriptService")

local ClearanceSystem = require(ServerScriptService.ClearanceSystem)
local KeycardConfig = require(script.Parent.KeycardConfig)

local KeycardFactory = {}

local function getDisplayName(level)
	local metadata = KeycardConfig.LevelMetadata[level]

	if metadata and metadata.DisplayName then
		return metadata.DisplayName
	end

	return string.format(KeycardConfig.ToolNameFormat, level)
end

local function createKeycard(level, name)
	local keycard = Instance.new("Tool")
	keycard.Name = name or getDisplayName(level)
	keycard.RequiresHandle = false
	keycard.CanBeDropped = false

	-- Attributes make the keycard easy for future systems to identify.
	keycard:SetAttribute(KeycardConfig.Attributes.IsKeycard, true)
	keycard:SetAttribute(KeycardConfig.Attributes.ClearanceLevel, level)

	return keycard
end

function KeycardFactory.create(level)
	assert(ClearanceSystem.isValidLevel(level), "Keycard clearance level must be valid")
	assert(level <= KeycardConfig.StandardMaximumClearance, "Level 11 is reserved for Admin Keycard")

	return createKeycard(level)
end

function KeycardFactory.createAdminKeycard()
	local keycard = createKeycard(KeycardConfig.AdminClearanceLevel, KeycardConfig.AdminKeycardName)
	keycard:SetAttribute(KeycardConfig.Attributes.IsAdminKeycard, true)

	return keycard
end

return KeycardFactory
