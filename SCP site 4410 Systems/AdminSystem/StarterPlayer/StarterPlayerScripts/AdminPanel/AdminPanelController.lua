--[[
	AdminPanelController

	Connects the player list UI to the server remotes used for clearance and
	keycard actions.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AdminPanelUI = require(script.Parent.AdminPanelUI)

local REMOTES_FOLDER_NAME = "AdminPanelRemotes"

local AdminPanelController = {}

local selectedPlayer = nil

local function waitForRemotes()
	local remotesFolder = ReplicatedStorage:WaitForChild(REMOTES_FOLDER_NAME)

	return {
		IsAdmin = remotesFolder:WaitForChild("IsAdmin"),
		Action = remotesFolder:WaitForChild("Action"),
	}
end

local function getValidLevel(text)
	local level = tonumber(text)

	if level then
		level = math.floor(level)
	end

	if not level or level < 0 or level > 10 then
		return nil
	end

	return level
end

local function getDurationMinutes(text)
	if text == nil or text == "" then
		return nil
	end

	local minutes = tonumber(text)

	if minutes then
		minutes = math.floor(minutes)
	end

	if not minutes or minutes < 1 or minutes > 60 then
		return false
	end

	return minutes
end

local function formatDuration(minutes)
	if not minutes then
		return "permanent"
	end

	return ("%d min"):format(minutes)
end

local function refreshPlayerList(ui)
	ui.clearPlayerList()

	for _, player in ipairs(Players:GetPlayers()) do
		ui.addPlayerButton(player, function()
			selectedPlayer = player
			ui.setSelectedPlayer(player)
		end)
	end

	if selectedPlayer and not selectedPlayer.Parent then
		selectedPlayer = nil
		ui.setSelectedPlayer(nil)
	end
end

function AdminPanelController.start()
	local remotes = waitForRemotes()
	local isAdmin = remotes.IsAdmin:InvokeServer()

	if not isAdmin then
		return
	end

	local ui = AdminPanelUI.create()

	refreshPlayerList(ui)

	Players.PlayerAdded:Connect(function()
		refreshPlayerList(ui)
	end)

	Players.PlayerRemoving:Connect(function(player)
		if selectedPlayer == player then
			selectedPlayer = nil
			ui.setSelectedPlayer(nil)
		end

		refreshPlayerList(ui)
	end)

	ui.onSetClearance(function()
		local level = getValidLevel(ui.getLevelText())

		if selectedPlayer and level then
			remotes.Action:FireServer("SetClearance", selectedPlayer.UserId, level)
			ui.setStatus(("Set %s to clearance %d."):format(selectedPlayer.Name, level))
		else
			ui.setStatus("Select a player and enter a level from 0 to 10.")
		end
	end)

	ui.onGiveKeycard(function()
		local level = getValidLevel(ui.getLevelText())
		local durationMinutes = getDurationMinutes(ui.getDurationText())

		if durationMinutes == false then
			ui.setStatus("Duration must be blank or 1-60 minutes.")
		elseif selectedPlayer and level then
			remotes.Action:FireServer("GiveKeycard", selectedPlayer.UserId, level, durationMinutes)
			ui.setStatus(("Gave %s a level %d keycard (%s)."):format(
				selectedPlayer.Name,
				level,
				formatDuration(durationMinutes)
			))
		else
			ui.setStatus("Select a player and enter a level from 0 to 10.")
		end
	end)

	ui.onGiveAdminKeycard(function()
		local durationMinutes = getDurationMinutes(ui.getDurationText())

		if durationMinutes == false then
			ui.setStatus("Duration must be blank or 1-60 minutes.")
		elseif selectedPlayer then
			remotes.Action:FireServer("GiveAdminKeycard", selectedPlayer.UserId, nil, durationMinutes)
			ui.setStatus(("Gave %s an admin keycard (%s)."):format(
				selectedPlayer.Name,
				formatDuration(durationMinutes)
			))
		else
			ui.setStatus("Select a player first.")
		end
	end)
end

return AdminPanelController
