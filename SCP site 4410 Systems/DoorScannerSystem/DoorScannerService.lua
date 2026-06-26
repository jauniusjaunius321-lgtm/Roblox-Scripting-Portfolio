--[[
	DoorScannerService

	Public server-sided API for scanner access checks. This module does not
	create GUI, animations, or actual door movement.
]]

local ServerScriptService = game:GetService("ServerScriptService")

local ClearanceSystem = require(ServerScriptService.ClearanceSystem)
local KeycardSystem = require(ServerScriptService.KeycardSystem)
local RoleSystem = require(ServerScriptService.RoleSystem)
local SectorAccessSystem = require(ServerScriptService.SectorAccessSystem)
local DoorScannerConfig = require(script.Parent.DoorScannerConfig)
local DoorScannerResult = require(script.Parent.DoorScannerResult)

local DoorScannerService = {}

DoorScannerService.Status = DoorScannerConfig.Status
DoorScannerService.Reasons = DoorScannerConfig.Reasons

local function getBestScannerLevel(player)
	local assignedClearance = ClearanceSystem.getPlayerClearance(player)
	local roleClearance = RoleSystem.getPlayerRoleClearance(player)
	local keycardClearance = KeycardSystem.findBestKeycardLevel(player)
	local bestLevel = math.max(assignedClearance, roleClearance)

	if keycardClearance then
		bestLevel = math.max(bestLevel, keycardClearance)
	end

	return bestLevel
end

local function playerHasScannerOverride(player)
	-- X Command and Foundation Government are handled by SectorAccessSystem,
	-- and admin roles from RoleSystem are also treated as full access.
	return SectorAccessSystem.playerHasOverride(player)
end

function DoorScannerService.getBestScannerLevel(player)
	assert(typeof(player) == "Instance" and player:IsA("Player"), "Expected a Player")

	return getBestScannerLevel(player)
end

function DoorScannerService.scanPlayer(player, scanOptions)
	assert(typeof(player) == "Instance" and player:IsA("Player"), "Expected a Player")

	scanOptions = scanOptions or DoorScannerConfig.DefaultScanOptions

	local requiredLevel = scanOptions.RequiredClearanceLevel
	local requiredSector = scanOptions.RequiredSector
	local bestLevel = getBestScannerLevel(player)

	if requiredLevel == nil and requiredSector == nil then
		requiredLevel = DoorScannerConfig.DefaultScanOptions.RequiredClearanceLevel
	end

	if playerHasScannerOverride(player) then
		local reason = KeycardSystem.playerHasAdminKeycard(player)
			and DoorScannerConfig.Reasons.FullAccessOverride
			or DoorScannerConfig.Reasons.RoleOverride

		return DoorScannerResult.new(true, reason, {
			RequiredClearanceLevel = requiredLevel,
			RequiredSector = requiredSector,
			PlayerAccessLevel = ClearanceSystem.MaximumLevel,
		})
	end

	if requiredLevel ~= nil then
		assert(ClearanceSystem.isValidLevel(requiredLevel), "Required clearance level must be valid")

		if bestLevel < requiredLevel then
			return DoorScannerResult.new(false, DoorScannerConfig.Reasons.ClearanceTooLow, {
				RequiredClearanceLevel = requiredLevel,
				RequiredSector = requiredSector,
				PlayerAccessLevel = bestLevel,
			})
		end
	end

	if requiredSector ~= nil then
		if not SectorAccessSystem.isValidSector(requiredSector) then
			return DoorScannerResult.new(false, DoorScannerConfig.Reasons.UnknownSector, {
				RequiredClearanceLevel = requiredLevel,
				RequiredSector = requiredSector,
				PlayerAccessLevel = bestLevel,
			})
		end

		local sectorResult = SectorAccessSystem.getAccessResult(player, requiredSector)

		if not sectorResult.Allowed then
			return DoorScannerResult.new(false, DoorScannerConfig.Reasons.SectorAccessDenied, {
				RequiredClearanceLevel = requiredLevel,
				RequiredSector = requiredSector,
				PlayerAccessLevel = bestLevel,
				SectorResult = sectorResult,
			})
		end
	end

	return DoorScannerResult.new(true, DoorScannerConfig.Reasons.AccessGranted, {
		RequiredClearanceLevel = requiredLevel,
		RequiredSector = requiredSector,
		PlayerAccessLevel = bestLevel,
	})
end

function DoorScannerService.canPlayerPass(player, scanOptions)
	return DoorScannerService.scanPlayer(player, scanOptions).Allowed
end

function DoorScannerService.scanForClearance(player, requiredLevel)
	return DoorScannerService.scanPlayer(player, {
		RequiredClearanceLevel = requiredLevel,
	})
end

function DoorScannerService.scanForSector(player, requiredSector)
	return DoorScannerService.scanPlayer(player, {
		RequiredSector = requiredSector,
	})
end

return DoorScannerService
