--[[
	AdminPanelUI

	Builds a simple admin panel ScreenGui with a player list, clearance input,
	and action buttons. This module only creates UI; it does not run admin
	actions directly.
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local AdminPanelUI = {}

local COLORS = {
	Background = Color3.fromRGB(20, 22, 26),
	Panel = Color3.fromRGB(30, 34, 40),
	PanelLight = Color3.fromRGB(42, 47, 55),
	Text = Color3.fromRGB(235, 238, 242),
	MutedText = Color3.fromRGB(170, 178, 190),
	Accent = Color3.fromRGB(63, 138, 224),
	AccentDark = Color3.fromRGB(45, 103, 170),
}

local function addCorner(instance, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	corner.Parent = instance
end

local function createTextLabel(parent, text, size, color)
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.Gotham
	label.Text = text
	label.TextColor3 = color or COLORS.Text
	label.TextSize = size
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextWrapped = true
	label.Parent = parent

	return label
end

local function createButton(parent, text)
	local button = Instance.new("TextButton")
	button.AutoButtonColor = true
	button.BackgroundColor3 = COLORS.Accent
	button.BorderSizePixel = 0
	button.Font = Enum.Font.GothamSemibold
	button.Text = text
	button.TextColor3 = COLORS.Text
	button.TextSize = 14
	button.Parent = parent
	addCorner(button, 6)

	return button
end

local function makeDraggable(handle, target)
	local dragging = false
	local dragStart = nil
	local startPosition = nil
	local dragInput = nil

	local function updatePosition(input)
		local delta = input.Position - dragStart

		target.Position = UDim2.new(
			startPosition.X.Scale,
			startPosition.X.Offset + delta.X,
			startPosition.Y.Scale,
			startPosition.Y.Offset + delta.Y
		)
	end

	handle.InputBegan:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.MouseButton1
			and input.UserInputType ~= Enum.UserInputType.Touch then
			return
		end

		dragging = true
		dragStart = input.Position
		startPosition = target.Position

		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				dragging = false
			end
		end)
	end)

	handle.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch then
			dragInput = input
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if dragging and input == dragInput then
			updatePosition(input)
		end
	end)
end

function AdminPanelUI.create()
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "AdminPanel"
	screenGui.DisplayOrder = 50
	screenGui.ResetOnSpawn = false
	screenGui.Parent = playerGui

	local launcherButton = createButton(screenGui, "ADMIN")
	launcherButton.AnchorPoint = Vector2.new(0, 1)
	launcherButton.BackgroundColor3 = COLORS.AccentDark
	launcherButton.Position = UDim2.new(0, 20, 1, -20)
	launcherButton.Size = UDim2.fromOffset(82, 36)

	local panel = Instance.new("Frame")
	panel.AnchorPoint = Vector2.new(0, 1)
	panel.BackgroundColor3 = COLORS.Panel
	panel.BorderSizePixel = 0
	panel.Position = UDim2.new(0, 20, 1, -66)
	panel.Size = UDim2.fromOffset(320, 476)
	panel.Visible = false
	panel.Parent = screenGui
	addCorner(panel, 8)

	local padding = Instance.new("UIPadding")
	padding.PaddingBottom = UDim.new(0, 14)
	padding.PaddingLeft = UDim.new(0, 14)
	padding.PaddingRight = UDim.new(0, 14)
	padding.PaddingTop = UDim.new(0, 14)
	padding.Parent = panel

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 10)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = panel

	local header = Instance.new("Frame")
	header.Active = true
	header.BackgroundTransparency = 1
	header.LayoutOrder = 1
	header.Size = UDim2.new(1, 0, 0, 28)
	header.Parent = panel

	local title = createTextLabel(header, "Admin Panel", 18, COLORS.Text)
	title.Font = Enum.Font.GothamBold
	title.Size = UDim2.new(1, -34, 1, 0)

	local closeButton = createButton(header, "X")
	closeButton.AnchorPoint = Vector2.new(1, 0)
	closeButton.BackgroundColor3 = COLORS.PanelLight
	closeButton.Position = UDim2.new(1, 0, 0, 0)
	closeButton.Size = UDim2.fromOffset(28, 28)
	closeButton.TextSize = 12

	makeDraggable(header, panel)

	local selectedLabel = createTextLabel(panel, "Selected: none", 14, COLORS.MutedText)
	selectedLabel.LayoutOrder = 2
	selectedLabel.Size = UDim2.new(1, 0, 0, 22)

	local playerList = Instance.new("ScrollingFrame")
	playerList.BackgroundColor3 = COLORS.Background
	playerList.BorderSizePixel = 0
	playerList.CanvasSize = UDim2.fromOffset(0, 0)
	playerList.LayoutOrder = 3
	playerList.ScrollBarThickness = 6
	playerList.Size = UDim2.new(1, 0, 0, 150)
	playerList.Parent = panel
	addCorner(playerList, 6)

	local listPadding = Instance.new("UIPadding")
	listPadding.PaddingBottom = UDim.new(0, 8)
	listPadding.PaddingLeft = UDim.new(0, 8)
	listPadding.PaddingRight = UDim.new(0, 8)
	listPadding.PaddingTop = UDim.new(0, 8)
	listPadding.Parent = playerList

	local playerListLayout = Instance.new("UIListLayout")
	playerListLayout.Padding = UDim.new(0, 6)
	playerListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	playerListLayout.Parent = playerList

	playerListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		playerList.CanvasSize = UDim2.fromOffset(0, playerListLayout.AbsoluteContentSize.Y + 16)
	end)

	local levelInput = Instance.new("TextBox")
	levelInput.BackgroundColor3 = COLORS.PanelLight
	levelInput.BorderSizePixel = 0
	levelInput.ClearTextOnFocus = false
	levelInput.Font = Enum.Font.Gotham
	levelInput.LayoutOrder = 4
	levelInput.PlaceholderText = "Clearance level 0-10"
	levelInput.Size = UDim2.new(1, 0, 0, 34)
	levelInput.Text = ""
	levelInput.TextColor3 = COLORS.Text
	levelInput.TextSize = 14
	levelInput.Parent = panel
	addCorner(levelInput, 6)

	local durationInput = Instance.new("TextBox")
	durationInput.BackgroundColor3 = COLORS.PanelLight
	durationInput.BorderSizePixel = 0
	durationInput.ClearTextOnFocus = false
	durationInput.Font = Enum.Font.Gotham
	durationInput.LayoutOrder = 5
	durationInput.PlaceholderText = "Duration minutes 1-60, blank = permanent"
	durationInput.Size = UDim2.new(1, 0, 0, 34)
	durationInput.Text = ""
	durationInput.TextColor3 = COLORS.Text
	durationInput.TextSize = 14
	durationInput.Parent = panel
	addCorner(durationInput, 6)

	local buttonRow = Instance.new("Frame")
	buttonRow.BackgroundTransparency = 1
	buttonRow.LayoutOrder = 6
	buttonRow.Size = UDim2.new(1, 0, 0, 34)
	buttonRow.Parent = panel

	local buttonLayout = Instance.new("UIListLayout")
	buttonLayout.FillDirection = Enum.FillDirection.Horizontal
	buttonLayout.Padding = UDim.new(0, 8)
	buttonLayout.SortOrder = Enum.SortOrder.LayoutOrder
	buttonLayout.Parent = buttonRow

	local setClearanceButton = createButton(buttonRow, "Set Clearance")
	setClearanceButton.Size = UDim2.new(0.5, -4, 1, 0)

	local giveKeycardButton = createButton(buttonRow, "Give Keycard")
	giveKeycardButton.BackgroundColor3 = COLORS.AccentDark
	giveKeycardButton.Size = UDim2.new(0.5, -4, 1, 0)

	local adminKeycardButton = createButton(panel, "Give Admin Keycard")
	adminKeycardButton.BackgroundColor3 = COLORS.AccentDark
	adminKeycardButton.LayoutOrder = 7
	adminKeycardButton.Size = UDim2.new(1, 0, 0, 34)

	local statusLabel = createTextLabel(panel, "", 13, COLORS.MutedText)
	statusLabel.LayoutOrder = 8
	statusLabel.Size = UDim2.new(1, 0, 0, 36)

	local ui = {}

	function ui.clearPlayerList()
		for _, child in ipairs(playerList:GetChildren()) do
			if child:IsA("TextButton") then
				child:Destroy()
			end
		end
	end

	function ui.addPlayerButton(player, onClick)
		local button = createButton(playerList, player.Name)
		button.BackgroundColor3 = COLORS.PanelLight
		button.Size = UDim2.new(1, -16, 0, 32)
		button.TextXAlignment = Enum.TextXAlignment.Left

		local buttonPadding = Instance.new("UIPadding")
		buttonPadding.PaddingLeft = UDim.new(0, 10)
		buttonPadding.Parent = button

		button.Activated:Connect(onClick)
	end

	function ui.setSelectedPlayer(player)
		if player then
			selectedLabel.Text = "Selected: " .. player.Name
		else
			selectedLabel.Text = "Selected: none"
		end
	end

	function ui.getLevelText()
		return levelInput.Text
	end

	function ui.getDurationText()
		return durationInput.Text
	end

	function ui.setStatus(message)
		statusLabel.Text = message
	end

	function ui.onSetClearance(callback)
		setClearanceButton.Activated:Connect(callback)
	end

	function ui.onGiveKeycard(callback)
		giveKeycardButton.Activated:Connect(callback)
	end

	function ui.onGiveAdminKeycard(callback)
		adminKeycardButton.Activated:Connect(callback)
	end

	launcherButton.Activated:Connect(function()
		panel.Visible = not panel.Visible
	end)

	closeButton.Activated:Connect(function()
		panel.Visible = false
	end)

	return ui
end

return AdminPanelUI
