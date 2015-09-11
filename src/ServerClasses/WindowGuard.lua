-- Services
local projectRoot = game:GetService("ServerScriptService")

-- Includes
local cs = require(projectRoot.Modules.ClassSystem)
local Util = require(projectRoot.Modules.Utilities)

--[[
	init(Rbx::Model windowModel)

	Properties:
		bool enabled
		
	Methods:
		setEnabled(bool enabled)
		
	Events:
		void
		
	Callbacks:
		void
		
]]

--------
-- Header end
--------

cs.class 'WindowGuard' (function (this) 

	--[[
		Internal properties:
			paneStats
	]]

	function this:init (windowModel)
		self.paneStats = {}
		self.guard = false
		
		for _, windowPart in next, Util.findAll(windowModel, "BasePart") do
			table.insert(self.paneStats, {
				part = windowPart;
				originalTransparency = windowPart.Transparency;
				originalReflectance = windowPart.Reflectance;
			})
		end
		
		if windowModel:FindFirstChild"EnableByDefault" then
			self.setEnabled(true)
		end
		
	end
	
	function this.member:setEnabled(enabled) 
		if self.enabled == enabled then
			return
		end
		
		for _, stat in next, self.paneStats do
			stat.part.Transparency = enabled and 0 or stat.originalTransparency
			stat.part.Reflectance = enabled and 0 or stat.originalReflectance
		end
		self.enabled = not self.enabled
	end
	
	-- public properties
	this.get.enabled = true
	
	-- public methods
	this.get.setEnabled = true
end)

return false