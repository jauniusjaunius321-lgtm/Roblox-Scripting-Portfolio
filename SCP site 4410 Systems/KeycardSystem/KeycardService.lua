--[[
	KeycardService

	Public server-sided API for creating and inspecting SCP-style keycard items.
	This module does not create doors, GUI, or animations.
]]

local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

local ClearanceSystem = require(ServerScriptService.ClearanceSystem)
local KeycardConfig = require(script.Parent.KeycardConfig)
local KeycardFactory = require(script.Parent.KeycardFactory)
local KeycardTemporaryStore = require(script.Parent.KeycardTemporaryStore)

local KeycardService = {}

KeycardService.Attributes = KeycardConfig.Attributes
KeycardService.StandardMaximumClearance = KeycardConfig.StandardMaximumClearance
KeycardService.AdminClearanceLevel = KeycardConfig.AdminClearanceLevel
KeycardService.TemporaryMaximumMinutes = KeycardConfig.TemporaryMaximumMinutes

local function getExpiresAt(keycard)
	local expiresAt = keycard:GetAttribute(KeycardConfig.Attributes.ExpiresAt)

	if typeof(expiresAt) ~= "number" or expiresAt <= 0 then
		return nil
	end

	return expiresAt
end

local function isExpired(keycard)
	local expiresAt = getExpiresAt(keycard)

	return expiresAt ~= nil and os.time() >= expiresAt
end

local function scheduleExpiration(player, keycard)
	local expiresAt = getExpiresAt(keycard)

	if not expiresAt then
		return
	end

	task.delay(math.max(0, expiresAt - os.time()), function()
		if not player.Parent then
			return
		end

		if keycard.Parent and isExpired(keycard) then
			local grantId = keycard:GetAttribute(KeycardConfig.Attributes.TemporaryGrantId)

			keycard:Destroy()

			if grantId then
				KeycardTemporaryStore.removeGrant(player, grantId)
			end
		end
	end)
end

function KeycardService.createKeycard(level)
	return KeycardFactory.create(level)
end

function KeycardService.createAdminKeycard()
	return KeycardFactory.createAdminKeycard()
end

function KeycardService.isKeycard(instance)
	return typeof(instance) == "Instance"
		and instance:GetAttribute(KeycardConfig.Attributes.IsKeycard) == true
end

function KeycardService.getKeycardLevel(instance)
	if not KeycardService.isKeycard(instance) then
		return nil
	end

	local level = instance:GetAttribute(KeycardConfig.Attributes.ClearanceLevel)

	if not ClearanceSystem.isValidLevel(level) then
		return nil
	end

	return level
end

function KeycardService.storeKeycard(player, keycard)
	assert(typeof(player) == "Instance" and player:IsA("Player"), "Expected a Player")
	assert(KeycardService.isKeycard(keycard), "Expected a keycard Tool")

	keycard.RequiresHandle = false
	keycard.CanBeDropped = false

	for _, descendant in ipairs(keycard:GetDescendants()) do
		if descendant:IsA("BasePart") then
			descendant:Destroy()
		end
	end

	keycard.Parent = player:WaitForChild("Backpack")
	scheduleExpiration(player, keycard)

	return keycard
end

local function applyTemporaryAttributes(player, keycard, expiresAt, grantId)
	keycard:SetAttribute(KeycardConfig.Attributes.IsTemporaryKeycard, true)
	keycard:SetAttribute(KeycardConfig.Attributes.ExpiresAt, expiresAt)
	keycard:SetAttribute(KeycardConfig.Attributes.TemporaryGrantId, grantId)
	scheduleExpiration(player, keycard)

	return keycard
end

function KeycardService.makeTemporary(player, keycard, durationSeconds)
	assert(typeof(player) == "Instance" and player:IsA("Player"), "Expected a Player")
	assert(KeycardService.isKeycard(keycard), "Expected a keycard Tool")

	local seconds = tonumber(durationSeconds)

	if not seconds or seconds <= 0 then
		return keycard
	end

	seconds = math.min(math.floor(seconds), KeycardConfig.TemporaryMaximumMinutes * 60)

	local expiresAt = os.time() + seconds
	local grant = KeycardTemporaryStore.addGrant(
		player,
		KeycardService.getKeycardLevel(keycard),
		keycard:GetAttribute(KeycardConfig.Attributes.IsAdminKeycard) == true,
		expiresAt
	)

	return applyTemporaryAttributes(player, keycard, grant.ExpiresAt, grant.Id)
end

function KeycardService.giveKeycard(player, level)
	assert(typeof(player) == "Instance" and player:IsA("Player"), "Expected a Player")

	local keycard = KeycardFactory.create(level)

	return KeycardService.storeKeycard(player, keycard)
end

function KeycardService.giveTemporaryKeycard(player, level, durationSeconds)
	local keycard = KeycardService.giveKeycard(player, level)

	return KeycardService.makeTemporary(player, keycard, durationSeconds)
end

function KeycardService.giveAdminKeycard(player)
	assert(typeof(player) == "Instance" and player:IsA("Player"), "Expected a Player")

	local keycard = KeycardFactory.createAdminKeycard()

	return KeycardService.storeKeycard(player, keycard)
end

function KeycardService.giveTemporaryAdminKeycard(player, durationSeconds)
	local keycard = KeycardService.giveAdminKeycard(player)

	return KeycardService.makeTemporary(player, keycard, durationSeconds)
end

function KeycardService.restoreTemporaryKeycard(player, grant)
	assert(typeof(player) == "Instance" and player:IsA("Player"), "Expected a Player")

	if typeof(grant) ~= "table"
		or typeof(grant.ExpiresAt) ~= "number"
		or grant.ExpiresAt <= os.time() then
		return nil
	end

	local keycard

	if grant.IsAdmin == true then
		keycard = KeycardFactory.createAdminKeycard()
	else
		keycard = KeycardFactory.create(math.clamp(
			math.floor(tonumber(grant.Level) or ClearanceSystem.MinimumLevel),
			ClearanceSystem.MinimumLevel,
			KeycardConfig.StandardMaximumClearance
		))
	end

	applyTemporaryAttributes(player, keycard, grant.ExpiresAt, grant.Id)

	return KeycardService.storeKeycard(player, keycard)
end

local function scanKeycards(player, callback)
	local function scanContainer(container)
		if not container then
			return
		end

		for _, item in ipairs(container:GetChildren()) do
			if KeycardService.isKeycard(item) and isExpired(item) then
				item:Destroy()
			elseif callback(item) then
				return true
			end
		end

		return false
	end

	return scanContainer(player:FindFirstChild("Backpack"))
		or scanContainer(player.Character)
end

function KeycardService.playerHasAdminKeycard(player)
	assert(typeof(player) == "Instance" and player:IsA("Player"), "Expected a Player")

	return scanKeycards(player, function(item)
		return KeycardService.isKeycard(item)
			and item:GetAttribute(KeycardConfig.Attributes.IsAdminKeycard) == true
	end)
end

function KeycardService.findBestKeycardLevel(player)
	assert(typeof(player) == "Instance" and player:IsA("Player"), "Expected a Player")

	local bestLevel = nil

	scanKeycards(player, function(item)
		local level = KeycardService.getKeycardLevel(item)

		if level and (bestLevel == nil or level > bestLevel) then
			bestLevel = level
		end

		return false
	end)

	return bestLevel
end

function KeycardService.playerHasKeycardClearance(player, requiredLevel)
	assert(ClearanceSystem.isValidLevel(requiredLevel), "Required clearance level must be valid")

	local bestLevel = KeycardService.findBestKeycardLevel(player)

	return bestLevel ~= nil and bestLevel >= requiredLevel
end

local function restorePlayerTemporaryKeycards(player)
	local grants = KeycardTemporaryStore.load(player)

	for _, grant in ipairs(grants) do
		KeycardService.restoreTemporaryKeycard(player, grant)
	end

	KeycardTemporaryStore.save(player)
end

Players.PlayerAdded:Connect(function(player)
	task.spawn(restorePlayerTemporaryKeycards, player)
end)

Players.PlayerRemoving:Connect(function(player)
	KeycardTemporaryStore.save(player)
	KeycardTemporaryStore.clear(player)
end)

game:BindToClose(function()
	for _, player in ipairs(Players:GetPlayers()) do
		KeycardTemporaryStore.save(player)
	end
end)

for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(restorePlayerTemporaryKeycards, player)
end

return KeycardService
