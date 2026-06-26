--[[
	KeycardTemporaryStore

	Persists active temporary keycard grants by absolute expiration time so the
	timer continues across server hops instead of restarting.
]]

local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")

local KeycardConfig = require(script.Parent.KeycardConfig)

local temporaryDataStore = DataStoreService:GetDataStore(KeycardConfig.TemporaryDataStoreName)

local KeycardTemporaryStore = {}

local cachedGrants = {}
local loadedPlayers = {}
local saveEnabled = {}

local function getKey(player)
	return "Player_" .. player.UserId
end

local function isGrantActive(grant, now)
	return typeof(grant) == "table"
		and typeof(grant.Id) == "string"
		and typeof(grant.Level) == "number"
		and typeof(grant.ExpiresAt) == "number"
		and grant.ExpiresAt > now
end

local function normalizeGrants(rawGrants)
	local grants = {}
	local now = os.time()

	if typeof(rawGrants) ~= "table" then
		return grants
	end

	for _, grant in ipairs(rawGrants) do
		if isGrantActive(grant, now) then
			table.insert(grants, {
				Id = grant.Id,
				Level = math.floor(grant.Level),
				IsAdmin = grant.IsAdmin == true,
				ExpiresAt = math.floor(grant.ExpiresAt),
			})
		end
	end

	return grants
end

function KeycardTemporaryStore.load(player)
	assert(typeof(player) == "Instance" and player:IsA("Player"), "Expected a Player")

	local success, result = pcall(function()
		return temporaryDataStore:GetAsync(getKey(player))
	end)

	if not success then
		warn(("Failed to load temporary keycards for %s: %s"):format(player.Name, tostring(result)))
	end

	cachedGrants[player.UserId] = normalizeGrants(success and result or nil)
	loadedPlayers[player.UserId] = true
	saveEnabled[player.UserId] = success

	return cachedGrants[player.UserId]
end

function KeycardTemporaryStore.get(player)
	assert(typeof(player) == "Instance" and player:IsA("Player"), "Expected a Player")

	if not loadedPlayers[player.UserId] then
		return KeycardTemporaryStore.load(player)
	end

	cachedGrants[player.UserId] = normalizeGrants(cachedGrants[player.UserId])

	return cachedGrants[player.UserId]
end

function KeycardTemporaryStore.save(player)
	assert(typeof(player) == "Instance" and player:IsA("Player"), "Expected a Player")

	if not loadedPlayers[player.UserId] or not saveEnabled[player.UserId] then
		return false
	end

	local grants = normalizeGrants(cachedGrants[player.UserId])
	cachedGrants[player.UserId] = grants

	local success, result = pcall(function()
		temporaryDataStore:SetAsync(getKey(player), grants)
	end)

	if not success then
		warn(("Failed to save temporary keycards for %s: %s"):format(player.Name, tostring(result)))
	end

	return success
end

function KeycardTemporaryStore.addGrant(player, level, isAdmin, expiresAt)
	assert(typeof(player) == "Instance" and player:IsA("Player"), "Expected a Player")

	local grants = KeycardTemporaryStore.get(player)
	local grant = {
		Id = HttpService:GenerateGUID(false),
		Level = math.floor(level),
		IsAdmin = isAdmin == true,
		ExpiresAt = math.floor(expiresAt),
	}

	table.insert(grants, grant)
	KeycardTemporaryStore.save(player)

	return grant
end

function KeycardTemporaryStore.removeGrant(player, grantId)
	assert(typeof(player) == "Instance" and player:IsA("Player"), "Expected a Player")

	if typeof(grantId) ~= "string" then
		return false
	end

	local grants = KeycardTemporaryStore.get(player)
	local changed = false

	for index = #grants, 1, -1 do
		if grants[index].Id == grantId then
			table.remove(grants, index)
			changed = true
		end
	end

	if changed then
		KeycardTemporaryStore.save(player)
	end

	return changed
end

function KeycardTemporaryStore.clear(player)
	assert(typeof(player) == "Instance" and player:IsA("Player"), "Expected a Player")

	cachedGrants[player.UserId] = nil
	loadedPlayers[player.UserId] = nil
	saveEnabled[player.UserId] = nil
end

return KeycardTemporaryStore
