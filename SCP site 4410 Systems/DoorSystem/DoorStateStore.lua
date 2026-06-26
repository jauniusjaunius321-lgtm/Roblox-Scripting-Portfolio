--[[
	DoorStateStore

	Keeps runtime state for registered door models. This is intentionally
	separate from DoorService so persistence or replication can be added later.
]]

local DoorConfig = require(script.Parent.DoorConfig)

local DoorStateStore = {}

local doorsById = {}
local stateByModel = {}

local function getDoorId(doorModel)
	local doorId = doorModel:GetAttribute(DoorConfig.Attributes.DoorId)

	if doorId == nil or doorId == "" then
		doorId = doorModel:GetFullName()
		doorModel:SetAttribute(DoorConfig.Attributes.DoorId, doorId)
	end

	return tostring(doorId)
end

function DoorStateStore.registerDoor(doorModel)
	assert(typeof(doorModel) == "Instance", "Expected a door Instance")

	local doorId = getDoorId(doorModel)
	local state = stateByModel[doorModel]

	if not state then
		state = {
			DoorId = doorId,
			Model = doorModel,
			IsOpen = false,
			AutoCloseTaskId = 0,
		}

		stateByModel[doorModel] = state
	end

	doorsById[doorId] = doorModel
	doorModel:SetAttribute(DoorConfig.Attributes.IsOpen, state.IsOpen)

	return state
end

function DoorStateStore.unregisterDoor(doorModel)
	local state = stateByModel[doorModel]

	if state then
		doorsById[state.DoorId] = nil
	end

	stateByModel[doorModel] = nil
end

function DoorStateStore.getDoorById(doorId)
	return doorsById[tostring(doorId)]
end

function DoorStateStore.getState(doorModel)
	return stateByModel[doorModel]
end

function DoorStateStore.getAllDoors()
	local doors = {}

	for _, doorModel in pairs(doorsById) do
		table.insert(doors, doorModel)
	end

	return doors
end

return DoorStateStore
