--[[
	PlayerRoleStore

	Loads, caches, and saves role assignments for players on the server. This
	is kept separate from RoleService so the public API stays small.
]]

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")

local RoleDefinitions = require(script.Parent.RoleDefinitions)

local PlayerRoleStore = {}

local DATA_STORE_NAME = "SCP_SITE_4410_Roles_v1"
local DATA_VERSION = 1

local roleDataStore = DataStoreService:GetDataStore(DATA_STORE_NAME)
local assignedRoles = {}
local loadedPlayers = {}
local saveEnabled = {}

local function getPlayerKey(player)
	return player.UserId
end

local function getDataStoreKey(player)
	return "Player_" .. player.UserId
end

local function normalizeRoleName(roleName)
	if RoleDefinitions.Roles[roleName] then
		return roleName
	end

	return RoleDefinitions.DefaultRole
end

local function loadRole(player)
	local key = getPlayerKey(player)

	if loadedPlayers[key] then
		return assignedRoles[key] or RoleDefinitions.DefaultRole
	end

	local success, result = pcall(function()
		return roleDataStore:GetAsync(getDataStoreKey(player))
	end)

	if success and typeof(result) == "table" then
		assignedRoles[key] = normalizeRoleName(result.Role)
	elseif success and typeof(result) == "string" then
		assignedRoles[key] = normalizeRoleName(result)
	elseif success then
		assignedRoles[key] = RoleDefinitions.DefaultRole
	else
		warn(("Failed to load role for %s: %s"):format(player.Name, tostring(result)))
		assignedRoles[key] = RoleDefinitions.DefaultRole
	end

	loadedPlayers[key] = true
	saveEnabled[key] = success

	return assignedRoles[key]
end

function PlayerRoleStore.load(player)
	assert(typeof(player) == "Instance" and player:IsA("Player"), "Expected a Player")

	return loadRole(player)
end

function PlayerRoleStore.save(player)
	assert(typeof(player) == "Instance" and player:IsA("Player"), "Expected a Player")

	local key = getPlayerKey(player)

	if not loadedPlayers[key] or not saveEnabled[key] then
		return false
	end

	local success, result = pcall(function()
		roleDataStore:SetAsync(getDataStoreKey(player), {
			Version = DATA_VERSION,
			Role = normalizeRoleName(assignedRoles[key]),
		})
	end)

	if not success then
		warn(("Failed to save role for %s: %s"):format(player.Name, tostring(result)))
	end

	return success
end

function PlayerRoleStore.assign(player, roleName)
	assert(typeof(player) == "Instance" and player:IsA("Player"), "Expected a Player")
	assert(RoleDefinitions.Roles[roleName] ~= nil, "Unknown role")

	loadRole(player)
	assignedRoles[getPlayerKey(player)] = roleName
end

function PlayerRoleStore.get(player)
	assert(typeof(player) == "Instance" and player:IsA("Player"), "Expected a Player")

	return loadRole(player)
end

function PlayerRoleStore.clear(player)
	assert(typeof(player) == "Instance" and player:IsA("Player"), "Expected a Player")

	local key = getPlayerKey(player)

	assignedRoles[key] = RoleDefinitions.DefaultRole
	loadedPlayers[key] = true
	saveEnabled[key] = saveEnabled[key] ~= false
end

local function clearCache(player)
	local key = getPlayerKey(player)

	assignedRoles[key] = nil
	loadedPlayers[key] = nil
	saveEnabled[key] = nil
end

-- Remove runtime role data when a player leaves the server.
Players.PlayerRemoving:Connect(function(player)
	PlayerRoleStore.save(player)
	clearCache(player)
end)

game:BindToClose(function()
	for _, player in ipairs(Players:GetPlayers()) do
		PlayerRoleStore.save(player)
	end
end)

return PlayerRoleStore
