--[[
	AdminPanel Client Entry

	Starts the local admin panel UI. Privileged actions are still enforced on
	the server by AdminPanel.server.lua.
]]

local AdminPanelController = require(script.AdminPanelController)

AdminPanelController.start()
