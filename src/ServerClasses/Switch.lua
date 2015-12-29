-- Zytharian (roblox: Legend26)

-- Services
local projectRoot = game:GetService("ServerScriptService")

-- Includes
local cs = require(projectRoot.Modules.ClassSystem)

--[[
	init(Rbx::Model switch)

	Properties:
		readonly bool isDown
		
	Methods:
		void setIndicator([Rbx::BrickColor left, Rbx::BrickColor right])
		
	Events:
		switchStateChanged(bool isDown)
		
	Callbacks:
		void

]]

--------
-- Header end
--------

cs.class 'Switch' (function (this) 

	--[[
		Internal properties:
			Rbx::BasePart model
			bool debounce
			Rbx::BrickColor leftColor
			Rbx::BrickColor rightColor
	]]

	this.member.debounce = false
	this.member.isDown = false
	
	function this:init (switch)
		self.model = switch
		self.leftColor = self.model.IndicatorLight.PowerAvail.BrickColor
		self.rightColor = self.model.IndicatorLight.Status.BrickColor
		
		self.switchStateChanged = cs.new 'Signal' ()
		
		local cd = Instance.new("ClickDetector", self.model.Switch.Union)
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
		
		self.model.Switch.PrimaryPart = self.model.Switch.Part
		
		local angle = CFrame.Angles(0, math.rad(self.isDown and 4 or -4), 0)
		local pivot = self.model.Switch.Part.CFrame
		local part = self.model.Switch.Union
		for i=1, 37 do
			self.model.Switch:SetPrimaryPartCFrame(self.model.Switch.PrimaryPart.CFrame * angle)
			wait()
		end
		
		self.isDown = not self.isDown
		self.switchStateChanged:Fire(self.isDown)
		
		self.debounce = false		
	end
	
	function this.member:setIndicator(left, right)
		self.model.IndicatorLight.PowerAvail.BrickColor = left and left or self.leftColor
		self.model.IndicatorLight.Status.BrickColor = right and right or self.rightColor
	end
	
	-- public properties
	this.get.isDown = true
	
	-- public methods
	this.get.setIndicator = true
	
	-- public events
	this.get.switchStateChanged = true
	
end)

return false