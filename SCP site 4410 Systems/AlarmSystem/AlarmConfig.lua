--[[
	AlarmConfig

	Shared configuration for alarms, alarm displays, lights, and sounds.
]]

local AlarmConfig = {}

AlarmConfig.Types = {
	None = "None",
	Lockdown = "Lockdown",
	Maintenance = "Maintenance",
	Emergency = "Emergency",
}

AlarmConfig.Tags = {
	Display = "AlarmDisplay",
	Light = "AlarmLight",
	Sound = "AlarmSound",
}

AlarmConfig.LightOffColor = Color3.fromRGB(255, 255, 255)
AlarmConfig.LightFlashOffColor = Color3.fromRGB(0, 0, 0)
AlarmConfig.LightOffMaterial = Enum.Material.Neon
AlarmConfig.LightOnMaterial = Enum.Material.Neon

AlarmConfig.Alarms = {
	None = {
		Display = "ALARM: STANDBY",
		Color = Color3.fromRGB(35, 255, 120),
		FlashSpeed = 0,
		SoundId = "",
		Volume = 0,
	},

	Lockdown = {
		Display = "ALARM: LOCKDOWN",
		Color = Color3.fromRGB(255, 45, 35),
		FlashSpeed = 0.5,
		SoundId = "rbxassetid://125955024483792",
		Volume = 0.8,
	},

	Maintenance = {
		Display = "ALARM: MAINTENANCE",
		Color = Color3.fromRGB(255, 190, 45),
		FlashSpeed = 0.75,
		SoundId = "",
		Volume = 0,
	},

	Emergency = {
		Display = "ALARM: EMERGENCY",
		Color = Color3.fromRGB(255, 255, 255),
		FlashSpeed = 0.15,
		SoundId = "",
		Volume = 0,
	},
}

function AlarmConfig.getAlarm(alarmType)
	return AlarmConfig.Alarms[alarmType] or AlarmConfig.Alarms.None
end

return AlarmConfig



