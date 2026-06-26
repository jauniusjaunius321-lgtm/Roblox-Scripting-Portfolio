--[[
	AlarmTerminalService

	Creates E-key prompts for tagged alarm terminals and exposes server remotes
	for the fullscreen terminal UI.
]]

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AlarmConfig = require(script.Parent.AlarmConfig)
local AlarmService = require(script.Parent.AlarmService)

local AlarmTerminalService = {}

local TERMINAL_TAG = "AlarmTerminal"
local REMOTES_FOLDER_NAME = "AlarmTerminalRemotes"

local started = false
local promptConnections = {}

local remotesFolder = ReplicatedStorage:FindFirstChild(REMOTES_FOLDER_NAME)

if not remotesFolder then
	remotesFolder = Instance.new("Folder")
	remotesFolder.Name = REMOTES_FOLDER_NAME
	remotesFolder.Parent = ReplicatedStorage
end

local openTerminalEvent = remotesFolder:FindFirstChild("OpenTerminal")

if not openTerminalEvent then
	openTerminalEvent = Instance.new("RemoteEvent")
	openTerminalEvent.Name = "OpenTerminal"
	openTerminalEvent.Parent = remotesFolder
end

local getAlarmFunction = remotesFolder:FindFirstChild("GetAlarm")

if not getAlarmFunction then
	getAlarmFunction = Instance.new("RemoteFunction")
	getAlarmFunction.Name = "GetAlarm"
	getAlarmFunction.Parent = remotesFolder
end

local setAlarmFunction = remotesFolder:FindFirstChild("SetAlarm")

if not setAlarmFunction then
	setAlarmFunction = Instance.new("RemoteFunction")
	setAlarmFunction.Name = "SetAlarm"
	setAlarmFunction.Parent = remotesFolder
end

local function getPromptPart(instance)
	if instance:IsA("BasePart") then
		return instance
	end

	local promptPart = instance:FindFirstChild("PromptPart", true)

	if promptPart and promptPart:IsA("BasePart") then
		return promptPart
	end

	return instance:FindFirstChildWhichIsA("BasePart", true)
end

local function getOrCreatePrompt(promptPart)
	local prompt = promptPart:FindFirstChild("AlarmTerminalPrompt")

	if not prompt then
		prompt = Instance.new("ProximityPrompt")
		prompt.Name = "AlarmTerminalPrompt"
		prompt.Parent = promptPart
	end

	prompt.ActionText = "Use"
	prompt.ObjectText = "Alarm Terminal"
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.MaxActivationDistance = 10
	prompt.HoldDuration = 0
	prompt.RequiresLineOfSight = false

	return prompt
end

local function registerTerminal(instance)
	local promptPart = getPromptPart(instance)

	if not promptPart or promptConnections[promptPart] then
		return
	end

	local prompt = getOrCreatePrompt(promptPart)

	promptConnections[promptPart] = prompt.Triggered:Connect(function(player)
		openTerminalEvent:FireClient(player)
	end)
end

local function unregisterTerminal(instance)
	local promptPart = getPromptPart(instance)
	local connection = promptPart and promptConnections[promptPart]

	if connection then
		connection:Disconnect()
		promptConnections[promptPart] = nil
	end
end

getAlarmFunction.OnServerInvoke = function()
	return AlarmService.getAlarm()
end

setAlarmFunction.OnServerInvoke = function(_player, alarmType)
	if alarmType == AlarmConfig.Types.Lockdown then
		return AlarmService.setLockdown(true)
	elseif alarmType == AlarmConfig.Types.None then
		return AlarmService.setLockdown(false)
	end

	return AlarmService.getAlarm()
end

function AlarmTerminalService.start()
	if started then
		return
	end

	started = true

	for _, terminal in ipairs(CollectionService:GetTagged(TERMINAL_TAG)) do
		registerTerminal(terminal)
	end

	CollectionService:GetInstanceAddedSignal(TERMINAL_TAG):Connect(registerTerminal)
	CollectionService:GetInstanceRemovedSignal(TERMINAL_TAG):Connect(unregisterTerminal)

	for _, instance in ipairs(workspace:GetDescendants()) do
		if instance.Name == TERMINAL_TAG then
			registerTerminal(instance)
		end
	end

	workspace.DescendantAdded:Connect(function(instance)
		if instance.Name == TERMINAL_TAG then
			registerTerminal(instance)
		end
	end)
end

return AlarmTerminalService
