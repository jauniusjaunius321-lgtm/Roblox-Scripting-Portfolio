--[[
	AlarmService

	Owns the active alarm state and listens to AccessControlSystem status
	changes. Other alarm modules react to AlarmChanged.
]]

local ServerScriptService = game:GetService("ServerScriptService")

local SystemStatusService = require(ServerScriptService.AccessControlSystem.SystemStatusService)
local AlarmConfig = require(script.Parent.AlarmConfig)

local AlarmService = {}

local alarmChanged = Instance.new("BindableEvent")
local currentAlarm = AlarmConfig.Types.None
local started = false

AlarmService.AlarmChanged = alarmChanged.Event
AlarmService.Types = AlarmConfig.Types

local function alarmForStatus(status)
	if status == SystemStatusService.Status.Lockdown then
		return AlarmConfig.Types.Lockdown
	elseif status == SystemStatusService.Status.Maintenance then
		return AlarmConfig.Types.Maintenance
	elseif status == SystemStatusService.Status.Emergency then
		return AlarmConfig.Types.Emergency
	end

	return AlarmConfig.Types.None
end

function AlarmService.getAlarm()
	return currentAlarm
end

function AlarmService.setAlarm(alarmType)
	assert(typeof(alarmType) == "string" and alarmType ~= "", "Alarm type must be a non-empty string")

	if currentAlarm == alarmType then
		return currentAlarm
	end

	currentAlarm = alarmType
	alarmChanged:Fire(currentAlarm)

	return currentAlarm
end

function AlarmService.setLockdown(enabled)
	SystemStatusService.setLockdown(enabled == true)
	return AlarmService.setAlarm(enabled and AlarmConfig.Types.Lockdown or AlarmConfig.Types.None)
end

function AlarmService.start()
	if started then
		return
	end

	started = true

	SystemStatusService.StatusChanged:Connect(function(status)
		AlarmService.setAlarm(alarmForStatus(status))
	end)

	AlarmService.setAlarm(alarmForStatus(SystemStatusService.getStatus()))
end

return AlarmService
