--[[
	TestService

	Optional manual test helper. Require this module and call start() from the
	Studio command bar or a temporary script when you want to test alarms.
]]

local AlarmService = require(script.Parent.AlarmService)

local TestService = {}

function TestService.start()
	task.spawn(function()
		AlarmService.setAlarm(AlarmService.Types.Lockdown)
		task.wait(5)

		AlarmService.setAlarm(AlarmService.Types.Maintenance)
		task.wait(5)

		AlarmService.setAlarm(AlarmService.Types.Emergency)
		task.wait(5)

		AlarmService.setAlarm(AlarmService.Types.None)
	end)
end

return TestService
