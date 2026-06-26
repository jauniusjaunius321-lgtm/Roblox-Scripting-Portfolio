--[[
	AlarmSounds

	Starts or stops tagged Sound instances when an alarm is active.
]]

local CollectionService = game:GetService("CollectionService")

local AlarmConfig = require(script.Parent.AlarmConfig)
local AlarmService = require(script.Parent.AlarmService)

local AlarmSounds = {}

local started = false

local function getOrCreateSound(target)
	if target:IsA("Sound") then
		return target
	end

	local sound = target:FindFirstChildOfClass("Sound")

	if not sound then
		sound = Instance.new("Sound")
		sound.Name = "AlarmSound"
		sound.Parent = target
	end

	return sound
end

local function configureSound(sound, alarmConfig)
	sound.SoundId = alarmConfig.SoundId or ""
	sound.Volume = alarmConfig.Volume or 0
	sound.Looped = true
end

local function stopTaggedSounds()
	for _, target in ipairs(CollectionService:GetTagged(AlarmConfig.Tags.Sound)) do
		local sound = getOrCreateSound(target)
		sound:Stop()
	end
end

function AlarmSounds.refresh()
	local alarm = AlarmService.getAlarm()
	local alarmConfig = AlarmConfig.getAlarm(alarm)

	stopTaggedSounds()

	if alarmConfig.SoundId == "" then
		return
	end

	for _, target in ipairs(CollectionService:GetTagged(AlarmConfig.Tags.Sound)) do
		local sound = getOrCreateSound(target)
		configureSound(sound, alarmConfig)

		sound:Play()
	end
end

function AlarmSounds.start()
	if started then
		return
	end

	started = true

	AlarmService.AlarmChanged:Connect(AlarmSounds.refresh)
	CollectionService:GetInstanceAddedSignal(AlarmConfig.Tags.Sound):Connect(AlarmSounds.refresh)
	CollectionService:GetInstanceRemovedSignal(AlarmConfig.Tags.Sound):Connect(AlarmSounds.refresh)

	AlarmSounds.refresh()
end

return AlarmSounds
