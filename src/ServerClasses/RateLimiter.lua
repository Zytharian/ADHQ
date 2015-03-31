-- Services
local projectRoot = game:GetService("ServerScriptService")

-- Includes
local cs = require(projectRoot.Modules.ClassSystem)

-- Configuration
local DEBUG = false

--[[
	init()

	Properties:
		void
		
	Methods:
		void registerPlayerCommand(Rbx::Player player)
		bool withinLimit(Rbx::Player player)
		void setSecondsBetweenCommands(number seconds)
		
	Events:
		void
		
	Callbacks:
		void
		
]]

--------
-- Header end
--------

cs.class 'RateLimiter' (function (this) 

	--[[
		Internal properties:
			table limits
			number seconds
	]]

	function this:init ()
		self.limits = {}
	end
	
	function this.member:registerPlayerCommand(player)
		self.limits[player] = tick()
	end
	
	function this.member:withinLimit(player)
		return tick() > (self.limits[player] or 0)+self.seconds
	end
	
	function this.member:setSecondsBetweenCommands(seconds)
		self.seconds = seconds
	end
	
	this.get.registerPlayerCommand = true
	this.get.withinLimit = true
	this.get.setSecondsBetweenCommands = true
end)

return false