-- Zytharian (roblox: Legend26)

-- Services
local projectRoot = game:GetService("ServerScriptService")

-- Includes
local Classes = require(projectRoot.Modules.ClassSystem)

-- Exported object
local ENUMS = {}

ENUMS.DeviceMode = Classes.new 'Enum' {
	"Unpowered";
	"Normal";
	"LocalLock";
	"GeneralLock";
	"InterfaceDisabled";
}

ENUMS.ConsoleType = Classes.new 'Enum' {
	"Local";
	"Control";
	"Core";
}

ENUMS.SectionMode = Classes.new 'Enum' {
	"Unpowered";
	"Normal";
	"Lockdown";
}

-- return exported object
return ENUMS