-- Zytharian (roblox: Legend26)

-- Services
local projectRoot = game:GetService("ServerScriptService")

-- Includes
local cs = require(projectRoot.Modules.ClassSystem)

-- Configuration
local DEBUG = false

--[[
	init(Network network)

	Properties:
		string name
		
	Methods:
		bool handleCommand(Section section, Enum::ConsoleType conType, table dat, Rbx::Player player)
			True on command success, false otherwise.
		
		table getBatchInfo(Section section, Enum::ConsoleType conType, Rbx::Player player)
	Events:
		networkUpdate(...)
		
	Callbacks:
		void
		
]]
--------
-- Header end
--------

cs.class 'ConsoleHandler' : abstract() (function (this) 

	--[[
		Internal properties:
			Network network
	]]

	function this:init (network)
		self.network = network
		self.networkUpdate = cs.new "Signal" ()
		self.name = "N/A"
	end
	
	function this.member:handleCommand(section, conType, dat, player)
		error("Not implemented")
	end
	
	function this.member:getBatchInfo(section, conType, player)
		error("Not	implemented")
	end
	
	this.get.name = true
	this.get.handleCommand = true
	this.get.getBatchInfo = true
	this.get.networkUpdate = true
end)

return false