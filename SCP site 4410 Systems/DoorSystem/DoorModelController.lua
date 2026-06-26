--[[
	DoorModelController

	Applies open and closed states to door model parts without animations or
	sounds. This can later be replaced by a tween/animation module if desired.
]]

local DoorConfig = require(script.Parent.DoorConfig)

local DoorModelController = {}

local originalPartState = {}

local function getDoorParts(doorModel)
	local parts = {}

	if doorModel:IsA("BasePart") then
		table.insert(parts, doorModel)
		return parts
	end

	for _, descendant in ipairs(doorModel:GetDescendants()) do
		if descendant:IsA("BasePart") then
			table.insert(parts, descendant)
		end
	end

	return parts
end

local function rememberPartState(part)
	if originalPartState[part] then
		return
	end

	originalPartState[part] = {
		CanCollide = part.CanCollide,
		Transparency = part.Transparency,
	}
end

function DoorModelController.open(doorModel)
	local openTransparency = doorModel:GetAttribute("OpenTransparency") or DoorConfig.Defaults.OpenTransparency

	for _, part in ipairs(getDoorParts(doorModel)) do
		rememberPartState(part)
		part.CanCollide = false
		part.Transparency = math.max(part.Transparency, openTransparency)
	end

	doorModel:SetAttribute(DoorConfig.Attributes.IsOpen, true)
end

function DoorModelController.close(doorModel)
	for _, part in ipairs(getDoorParts(doorModel)) do
		local partState = originalPartState[part]

		if partState then
			part.CanCollide = partState.CanCollide
			part.Transparency = partState.Transparency
		else
			part.CanCollide = true
		end
	end

	doorModel:SetAttribute(DoorConfig.Attributes.IsOpen, false)
end

return DoorModelController
