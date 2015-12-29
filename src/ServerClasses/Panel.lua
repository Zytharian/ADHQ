-- Zytharian (roblox: Legend26)

-- Services
local projectRoot = game:GetService("ServerScriptService")

-- Includes
local cs = require(projectRoot.Modules.ClassSystem)

--[[
	init(Rbx::BasePart panel)

	Properties:
		void
		
	Methods:
		void
		
	Events:
		void
		
	Callbacks:
		void
		
]]

--------
-- Header end
--------

cs.class 'Panel' (function (this) 

	--[[
		Internal properties:
			Rbx::BasePart panel
			bool debounce
			bool isOpen
			number smooth
	]]

	this.member.debounce = false
	this.member.isOpen = false
	this.member.smooth = 3
	
	function this:init (panel)
		self.panel = panel
		
		local cd = Instance.new("ClickDetector", panel)
		cd.MaxActivationDistance = 8
		
		local propagator = cs.new 'EventPropagator' ("ClickDetector", "MouseClick")
		propagator:addObject(cd)
		
		propagator.eventFired:Connect(function ()
			self:changeState()
		end)
		
	end
	
	function this.member:changeState()
		if self.debounce then return end
		self.debounce = true
		
		local size = self.panel.Size.Y
		local cf = CFrame.new(0, (self.isOpen and 1 or -1) / self.smooth, 0)
		for i=1, size * self.smooth do
			self.panel.CFrame = self.panel.CFrame * cf
			wait()
		end
		
		self.isOpen = not self.isOpen
		self.debounce = false		
	end
	
end)

return false