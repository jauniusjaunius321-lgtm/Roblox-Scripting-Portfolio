--[[
	AlarmDisplay

	Updates TextLabels tagged as AlarmDisplay when the active alarm changes.
]]

local CollectionService = game:GetService("CollectionService")

local AlarmConfig = require(script.Parent.AlarmConfig)
local AlarmService = require(script.Parent.AlarmService)

local AlarmDisplay = {}

local started = false

local function addTextLabels(target, labels, seen)
	if seen[target] then
		return
	end

	seen[target] = true

	if target:IsA("TextLabel") then
		table.insert(labels, target)
		return
	end

	for _, descendant in ipairs(target:GetDescendants()) do
		if descendant:IsA("TextLabel") then
			addTextLabels(descendant, labels, seen)
		end
	end
end

local function getLabels()
	local labels = {}
	local seen = {}

	for _, target in ipairs(CollectionService:GetTagged(AlarmConfig.Tags.Display)) do
		addTextLabels(target, labels, seen)
	end

	return labels
end

function AlarmDisplay.refresh()
	local alarm = AlarmService.getAlarm()
	local alarmConfig = AlarmConfig.getAlarm(alarm)

	for _, label in ipairs(getLabels()) do
		label.Text = alarmConfig.Display
		label.TextColor3 = alarmConfig.Color
	end
end

function AlarmDisplay.start()
	if started then
		return
	end

	started = true

	AlarmService.AlarmChanged:Connect(AlarmDisplay.refresh)
	CollectionService:GetInstanceAddedSignal(AlarmConfig.Tags.Display):Connect(AlarmDisplay.refresh)
	CollectionService:GetInstanceRemovedSignal(AlarmConfig.Tags.Display):Connect(AlarmDisplay.refresh)

	AlarmDisplay.refresh()
end

return AlarmDisplay
