--[[
	RoleDefinitions

	Central data for every role and faction. Systems for permissions, sectors,
	overhead displays, or admin tools should read from here instead of hard
	coding role names in multiple places.
]]

local RoleDefinitions = {}

RoleDefinitions.Factions = {
	Foundation = {
		Name = "Foundation",
		IsHostile = false,
		DefaultRole = "Visitor",
	},

	Hostile = {
		Name = "Hostile",
		IsHostile = true,
		DefaultRole = "Chaos Insurgency",
	},
}

RoleDefinitions.DefaultRole = "Visitor"
RoleDefinitions.FoundationGovernmentRole = "Foundation Government"

RoleDefinitions.Roles = {
	["Class-D"] = {
		Faction = "Foundation",
		ClearanceLevel = 0,
		Permissions = {},
	},

	Visitor = {
		Faction = "Foundation",
		ClearanceLevel = 0,
		Permissions = {},
	},

	Janitor = {
		Faction = "Foundation",
		ClearanceLevel = 1,
		Permissions = {},
	},

	Maintenance = {
		Faction = "Foundation",
		ClearanceLevel = 2,
		Permissions = {
			ReactorRepair = true,
		},
	},

	Security = {
		Faction = "Foundation",
		ClearanceLevel = 3,
		Permissions = {
			SecurityAccess = true,
		},
	},

	["SCP Foundation Police"] = {
		Faction = "Foundation",
		ClearanceLevel = 4,
		Permissions = {
			SecurityAccess = true,
		},
	},

	["SCP Foundation Justice"] = {
		Faction = "Foundation",
		ClearanceLevel = 4,
		Permissions = {
			SecurityAccess = true,
		},
	},

	Scientist = {
		Faction = "Foundation",
		ClearanceLevel = 3,
		Permissions = {
			ResearchAccess = true,
		},
	},

	["Research & Development"] = {
		Faction = "Foundation",
		ClearanceLevel = 4,
		Permissions = {
			ResearchAccess = true,
			ReactorRepair = true,
		},
	},

	["Medical Staff"] = {
		Faction = "Foundation",
		ClearanceLevel = 3,
		Permissions = {
			MedicalAccess = true,
		},
	},

	["Intelligence Agency"] = {
		Faction = "Foundation",
		ClearanceLevel = 5,
		Permissions = {
			IntelligenceAccess = true,
		},
	},

	["Rapid Response Team"] = {
		Faction = "Foundation",
		ClearanceLevel = 5,
		Permissions = {
			SecurityAccess = true,
			ResponseAccess = true,
		},
	},

	["Mobile Task Force"] = {
		Faction = "Foundation",
		ClearanceLevel = 6,
		Permissions = {
			SecurityAccess = true,
			ResponseAccess = true,
		},
	},

	["Site Director"] = {
		Faction = "Foundation",
		ClearanceLevel = 8,
		Permissions = {
			SiteManagement = true,
			ReactorAuthority = true,
		},
	},

	["O5 Command"] = {
		Faction = "Foundation",
		ClearanceLevel = 9,
		Permissions = {
			SiteManagement = true,
			CommandAccess = true,
			ReactorAuthority = true,
			NuclearFailSafe = true,
		},
	},

	["X Command"] = {
		Faction = "Foundation",
		ClearanceLevel = 10,
		Permissions = {
			SiteManagement = true,
			CommandAccess = true,
			ReactorAuthority = true,
			ReactorOverride = true,
			NuclearFailSafe = true,
		},
	},

	["Foundation Government"] = {
		Faction = "Foundation",
		ClearanceLevel = 10,
		IsAdministrator = true,
		IsModerator = true,
		HiddenFromPublicDisplays = true,
		Permissions = {
			AdminPanelAccess = true,
			ModerationAccess = true,
			SiteManagement = true,
			CommandAccess = true,
			FullClearance = true,
			ReactorAuthority = true,
			ReactorOverride = true,
			ReactorRepair = true,
			NuclearFailSafe = true,
		},
	},

	["Chaos Insurgency"] = {
		Faction = "Hostile",
		ClearanceLevel = 3,
		Permissions = {
			HostileAccess = true,
			ReactorSabotage = true,
		},
	},
}

return RoleDefinitions
