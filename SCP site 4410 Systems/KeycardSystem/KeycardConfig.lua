--[[
	KeycardConfig

	Central configuration for keycard item metadata. The actual level range is
	validated through ClearanceSystem so both systems stay compatible.
]]

local KeycardConfig = {}

KeycardConfig.ToolNameFormat = "Keycard L%d"
KeycardConfig.StandardMaximumClearance = 10
KeycardConfig.AdminClearanceLevel = 11
KeycardConfig.AdminKeycardName = "Admin Keycard L11"
KeycardConfig.TemporaryDataStoreName = "SCP_SITE_4410_TemporaryKeycards_v1"
KeycardConfig.TemporaryMaximumMinutes = 60

KeycardConfig.Attributes = {
	IsKeycard = "IsKeycard",
	ClearanceLevel = "ClearanceLevel",
	IsAdminKeycard = "IsAdminKeycard",
	IsTemporaryKeycard = "IsTemporaryKeycard",
	ExpiresAt = "ExpiresAt",
	TemporaryGrantId = "TemporaryGrantId",
}

-- Optional metadata for future expansion, such as colors, descriptions, or icons.
KeycardConfig.LevelMetadata = {}

for level = 0, KeycardConfig.StandardMaximumClearance do
	KeycardConfig.LevelMetadata[level] = {
		DisplayName = string.format(KeycardConfig.ToolNameFormat, level),
	}
end

return KeycardConfig
