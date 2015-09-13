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
			asyncTransitors
	]]

	function this:init (windowModel)
		self.paneStats = {}
		self.enabled = false
		self.asyncTransitors = 0
		
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
			self:transitionPartAsync(stat, enabled)
		end
		self.enabled = not self.enabled
	end
	
	function this.member:transitionPartAsync(stat, enabled)
		coroutine.wrap(function ()
			local oldT, oldR, newT, newR
			if enabled then
				oldT = stat.originalTransparency
				oldR = stat.originalReflectance
				newT = 0
				newR = 0
			else
				newT = stat.originalTransparency
				newR = stat.originalReflectance
				oldT = 0
				oldR = 0
			end
			
			local count = 30
			for i = 1, count do
				local percent = i / count
				stat.part.Transparency = self:lerp(oldT, newT, percent)
				stat.part.Reflectance = self:lerp(oldR, newR, percent)
			
				wait()
			end
			
		end)()
	end
	
	function this.member:lerp(begin, ending, percent)
		return (1-percent)*begin + percent*ending
	end
	
	-- public properties
	this.get.enabled = true
	
	-- public methods
	this.get.setEnabled = true
end)

return false