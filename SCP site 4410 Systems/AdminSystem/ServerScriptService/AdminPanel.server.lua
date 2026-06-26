--[[
	AdminPanel Server Bridge

	Handles privileged admin panel requests from clients. The UI can only ask
	for actions; this server script validates admin access and then calls the
	server-only ClearanceSystem and KeycardSystem modules.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local ClearanceSystem = require(ServerScriptService.ClearanceSystem)
local KeycardSystem = require(ServerScriptService.KeycardSystem)
local RoleSystem = require(ServerScriptService.RoleSystem)

local REMOTES_FOLDER_NAME = "AdminPanelRemotes"

-- Add trusted Roblox user IDs here. The game creator is also allowed below.
local ADMIN_USER_IDS = {

	-- Add trusted Roblox user IDs here when needed.
}

local remotesFolder = ReplicatedStorage:FindFirstChild(REMOTES_FOLDER_NAME)

if not remotesFolder then
	remotesFolder = Instance.new("Folder")
	remotesFolder.Name = REMOTES_FOLDER_NAME
	remotesFolder.Parent = ReplicatedStorage
end

local isAdminFunction = remotesFolder:FindFirstChild("IsAdmin")

if not isAdminFunction then
	isAdminFunction = Instance.new("RemoteFunction")
	isAdminFunction.Name = "IsAdmin"
	isAdminFunction.Parent = remotesFolder
end

local actionEvent = remotesFolder:FindFirstChild("Action")

if not actionEvent then
	actionEvent = Instance.new("RemoteEvent")
	actionEvent.Name = "Action"
	actionEvent.Parent = remotesFolder
end

local function isAdmin(player)
	return ADMIN_USER_IDS[player.UserId] == true
		or player.UserId == game.CreatorId
		or RoleSystem.playerHasAdminPermissions(player)
end

local function giveAdminKeycardIfNeeded(player)
	if not isAdmin(player) then
		return
	end

	task.spawn(function()
		if not player:WaitForChild("Backpack", 10) then
			return
		end

		if player.Parent and not KeycardSystem.playerHasAdminKeycard(player) then
			KeycardSystem.giveAdminKeycard(player)
		end
	end)
end

local function getPlayerByUserId(userId)
	for _, player in ipairs(Players:GetPlayers()) do
		if player.UserId == userId then
			return player
		end
	end

	return nil
end

local function readValidLevel(value)
	local level = tonumber(value)

	if level then
		level = math.floor(level)
	end

	if not ClearanceSystem.isValidLevel(level)
		or level > KeycardSystem.StandardMaximumClearance then
		return nil
	end

	return level
end

local function readDurationSeconds(value)
	local minutes = tonumber(value)

	if not minutes or minutes <= 0 then
		return nil
	end

	minutes = math.floor(minutes)

	if minutes < 1 then
		return nil
	end

	return math.clamp(minutes, 1, KeycardSystem.TemporaryMaximumMinutes) * 60
end

isAdminFunction.OnServerInvoke = function(player)
	return isAdmin(player)
end

actionEvent.OnServerEvent:Connect(function(adminPlayer, actionName, targetUserId, levelValue, durationMinutes)
	if not isAdmin(adminPlayer) then
		warn(("%s attempted to use the admin panel without permission."):format(adminPlayer.Name))
		return
	end

	local targetPlayer = getPlayerByUserId(tonumber(targetUserId))

	if not targetPlayer then
		return
	end

	if actionName == "GiveAdminKeycard" then
		local durationSeconds = readDurationSeconds(durationMinutes)

		if durationSeconds then
			KeycardSystem.giveTemporaryAdminKeycard(targetPlayer, durationSeconds)
		else
			KeycardSystem.giveAdminKeycard(targetPlayer)
		end

		return
	end

	local level = readValidLevel(levelValue)
	local durationSeconds = readDurationSeconds(durationMinutes)

	if not level then
		return
	end

	if actionName == "SetClearance" then
		ClearanceSystem.setPlayerClearance(targetPlayer, level)
	elseif actionName == "GiveKeycard" then
		if durationSeconds then
			KeycardSystem.giveTemporaryKeycard(targetPlayer, level, durationSeconds)
		else
			KeycardSystem.giveKeycard(targetPlayer, level)
		end
	end
end)

Players.PlayerAdded:Connect(function(player)
	giveAdminKeycardIfNeeded(player)

	player.CharacterAdded:Connect(function()
		giveAdminKeycardIfNeeded(player)
	end)
end)

for _, player in ipairs(Players:GetPlayers()) do
	giveAdminKeycardIfNeeded(player)
end
