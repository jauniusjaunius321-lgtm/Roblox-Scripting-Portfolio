--[[
	RoleService

	Public server-sided API for role, faction, clearance, keycard, permission,
	and future sector-access checks.
]]

local ServerScriptService = game:GetService("ServerScriptService")

local ClearanceSystem = require(ServerScriptService.ClearanceSystem)
local KeycardSystem = require(ServerScriptService.KeycardSystem)
local PlayerRoleStore = require(script.Parent.PlayerRoleStore)
local RoleDefinitions = require(script.Parent.RoleDefinitions)

local RoleService = {}

RoleService.DefaultRole = RoleDefinitions.DefaultRole
RoleService.FoundationGovernmentRole = RoleDefinitions.FoundationGovernmentRole
RoleService.Roles = RoleDefinitions.Roles
RoleService.Factions = RoleDefinitions.Factions

local function getRoleDefinition(roleName)
	return RoleDefinitions.Roles[roleName]
end

local function getRoleClearanceLevel(roleName)
	local roleDefinition = getRoleDefinition(roleName)

	if not roleDefinition then
		return ClearanceSystem.MinimumLevel
	end

	return roleDefinition.ClearanceLevel or ClearanceSystem.MinimumLevel
end

function RoleService.isValidRole(roleName)
	return getRoleDefinition(roleName) ~= nil
end

function RoleService.isValidFaction(factionName)
	return RoleDefinitions.Factions[factionName] ~= nil
end

function RoleService.getRoleDefinition(roleName)
	return getRoleDefinition(roleName)
end

function RoleService.getFactionDefinition(factionName)
	return RoleDefinitions.Factions[factionName]
end

function RoleService.assignPlayerRole(player, roleName)
	assert(RoleService.isValidRole(roleName), "Unknown role")

	PlayerRoleStore.assign(player, roleName)

	-- Roles grant minimum clearance only. Manual/admin clearance can still be
	-- higher and should not be lowered by role changes.
	local clearanceLevel = getRoleClearanceLevel(roleName)
	ClearanceSystem.grantMinimumClearance(player, clearanceLevel)

	-- RankSystem is required lazily to avoid a startup require cycle.
	local rankSystem = ServerScriptService:FindFirstChild("RankSystem")

	if rankSystem then
		require(rankSystem).syncPlayerClearance(player, roleName)
	end
end

function RoleService.assignPlayerFaction(player, factionName)
	assert(RoleService.isValidFaction(factionName), "Unknown faction")

	local factionDefinition = RoleDefinitions.Factions[factionName]

	RoleService.assignPlayerRole(player, factionDefinition.DefaultRole)
end

function RoleService.getPlayerRole(player)
	return PlayerRoleStore.get(player)
end

function RoleService.clearPlayerRole(player)
	PlayerRoleStore.clear(player)
end

function RoleService.getPlayerFaction(player)
	local roleDefinition = getRoleDefinition(RoleService.getPlayerRole(player))

	if not roleDefinition then
		return nil
	end

	return roleDefinition.Faction
end

function RoleService.isPlayerHostile(player)
	local factionName = RoleService.getPlayerFaction(player)
	local factionDefinition = RoleDefinitions.Factions[factionName]

	return factionDefinition ~= nil and factionDefinition.IsHostile == true
end

function RoleService.getPlayerRoleClearance(player)
	return getRoleClearanceLevel(RoleService.getPlayerRole(player))
end

function RoleService.playerHasRoleClearance(player, requiredLevel)
	assert(ClearanceSystem.isValidLevel(requiredLevel), "Required clearance level must be valid")

	if RoleService.playerHasAdminPermissions(player) then
		return true
	end

	return RoleService.getPlayerRoleClearance(player) >= requiredLevel
end

function RoleService.givePlayerRoleKeycard(player)
	local level = RoleService.getPlayerRoleClearance(player)

	return KeycardSystem.giveKeycard(player, level)
end

function RoleService.playerHasPermission(player, permissionName)
	local roleDefinition = getRoleDefinition(RoleService.getPlayerRole(player))

	if not roleDefinition then
		return false
	end

	if roleDefinition.IsAdministrator then
		return true
	end

	return roleDefinition.Permissions ~= nil and roleDefinition.Permissions[permissionName] == true
end

function RoleService.playerHasAdminPermissions(player)
	local roleDefinition = getRoleDefinition(RoleService.getPlayerRole(player))

	return roleDefinition ~= nil and roleDefinition.IsAdministrator == true
end

function RoleService.playerHasModeratorPermissions(player)
	local roleDefinition = getRoleDefinition(RoleService.getPlayerRole(player))

	return roleDefinition ~= nil
		and (roleDefinition.IsAdministrator == true or roleDefinition.IsModerator == true)
end

function RoleService.getPublicRoleName(roleName)
	local roleDefinition = getRoleDefinition(roleName)

	if not roleDefinition or roleDefinition.HiddenFromPublicDisplays then
		return nil
	end

	return roleName
end

function RoleService.getPlayerPublicRoleName(player)
	return RoleService.getPublicRoleName(RoleService.getPlayerRole(player))
end

function RoleService.canPlayerAccessSector(player, sectorName)
	-- Lazy require avoids circular loading while keeping old RoleSystem callers
	-- compatible with the dedicated SectorAccessSystem.
	local SectorAccessSystem = require(ServerScriptService.SectorAccessSystem)

	return SectorAccessSystem.canPlayerAccessSector(player, sectorName)
end

return RoleService
