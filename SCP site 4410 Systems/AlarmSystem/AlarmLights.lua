--[[
	AlarmLights

	Updates tagged alarm light parts and Light instances when alarm state
	changes.
]]

local CollectionService = game:GetService("CollectionService")

local AlarmConfig = require(script.Parent.AlarmConfig)
local AlarmService = require(script.Parent.AlarmService)

local AlarmLights = {}

local started = false
local flashTaskId = 0
local originalStates = {}

local function addAlarmInstance(instance, instances, seen)
	if not instance or seen[instance] then
		return
	end

	if instance:IsA("BasePart") or instance:IsA("Light") then
		seen[instance] = true
		table.insert(instances, instance)
	end
end

local function rememberState(instance)
	if originalStates[instance] then
		return originalStates[instance]
	end

	local state = {}

	if instance:IsA("BasePart") then
		state.Color = instance.Color
		state.Material = instance.Material
	elseif instance:IsA("Light") then
		state.Color = instance.Color
		state.Enabled = instance.Enabled
		state.Brightness = instance.Brightness
	end

	originalStates[instance] = state

	return state
end

local function restoreState(instance)
	local state = rememberState(instance)

	if instance:IsA("BasePart") then
		instance.Color = AlarmConfig.LightOffColor
		instance.Material = AlarmConfig.LightOffMaterial
	elseif instance:IsA("Light") then
		local brightness = state.Brightness

		if not brightness or brightness <= 0 then
			brightness = 1
		end

		instance.Color = AlarmConfig.LightOffColor
		instance.Enabled = true
		instance.Brightness = brightness
	end
end

local function setLightState(instance, alarmConfig, visible)
	rememberState(instance)

	if instance:IsA("BasePart") then
		instance.Color = visible and alarmConfig.Color or AlarmConfig.LightFlashOffColor
		instance.Material = visible and AlarmConfig.LightOnMaterial or AlarmConfig.LightOffMaterial
	elseif instance:IsA("Light") then
		local state = rememberState(instance)

		instance.Color = alarmConfig.Color
		instance.Enabled = visible
		instance.Brightness = visible and math.max(state.Brightness or 1, 1) or 0
	end
end

local function collectAlarmInstances()
	local instances = {}
	local seen = {}

	for _, target in ipairs(CollectionService:GetTagged(AlarmConfig.Tags.Light)) do
		addAlarmInstance(target, instances, seen)

		if target:IsA("Light") then
			addAlarmInstance(target.Parent, instances, seen)
		end

		for _, descendant in ipairs(target:GetDescendants()) do
			addAlarmInstance(descendant, instances, seen)

			if descendant:IsA("Light") then
				addAlarmInstance(descendant.Parent, instances, seen)
			end
		end
	end

	for _, descendant in ipairs(workspace:GetDescendants()) do
		if descendant.Name == AlarmConfig.Tags.Light then
			addAlarmInstance(descendant, instances, seen)

			if descendant:IsA("Light") then
				addAlarmInstance(descendant.Parent, instances, seen)
			end

			for _, child in ipairs(descendant:GetDescendants()) do
				addAlarmInstance(child, instances, seen)

				if child:IsA("Light") then
					addAlarmInstance(child.Parent, instances, seen)
				end
			end
		end
	end

	return instances
end

local function applyToAlarmLights(callback)
	for _, instance in ipairs(collectAlarmInstances()) do
		callback(instance)
	end
end

function AlarmLights.refresh()
	local alarm = AlarmService.getAlarm()
	local alarmConfig = AlarmConfig.getAlarm(alarm)
	flashTaskId += 1

	if alarm == AlarmConfig.Types.None then
		applyToAlarmLights(restoreState)
		return
	end

	if alarmConfig.FlashSpeed <= 0 then
		applyToAlarmLights(function(instance)
			setLightState(instance, alarmConfig, true)
		end)

		return
	end

	local taskId = flashTaskId

	task.spawn(function()
		local visible = true

		while taskId == flashTaskId and AlarmService.getAlarm() == alarm do
			applyToAlarmLights(function(instance)
				setLightState(instance, alarmConfig, visible)
			end)

			visible = not visible
			task.wait(alarmConfig.FlashSpeed)
		end
	end)
end

function AlarmLights.start()
	if started then
		return
	end

	started = true

	AlarmService.AlarmChanged:Connect(AlarmLights.refresh)
	CollectionService:GetInstanceAddedSignal(AlarmConfig.Tags.Light):Connect(AlarmLights.refresh)
	CollectionService:GetInstanceRemovedSignal(AlarmConfig.Tags.Light):Connect(AlarmLights.refresh)
	workspace.DescendantAdded:Connect(function(instance)
		if instance.Name == AlarmConfig.Tags.Light then
			AlarmLights.refresh()
		end
	end)

	AlarmLights.refresh()
end

return AlarmLights

