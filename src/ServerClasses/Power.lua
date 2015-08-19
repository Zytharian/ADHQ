-- Services
local projectRoot = game:GetService("ServerScriptService")

-- Includes
local cs = require(projectRoot.Modules.ClassSystem)

-- Configuration
local powerMonitorSurfaceGui = game.ReplicatedStorage.PowerMonitorSurfaceGui
local powerMonitorSurfaceGuiName = "PowerMonitorSurfaceGui"
local crystalColor = BrickColor.new("Brick yellow")

--[[
	init(Rbx::Model model)

	Properties:
		bool powerEnabled
		
	Methods:
		void endCountdown()
		
	Events:
		powerStateChanged(bool powerEnabled)
		
	Callbacks:
		void
		
]]

--------
-- Header end
--------

cs.class 'Power' (function (this) 

	--[[
		Internal properties:
			Rbx::Model model
			
			bool monitorAlertEnabled
			number auxPowerTime

			Panel panel
			Switch switch1
			Switch switch2
			
			bool countdownRunning
			bool countdownEnabled
			
			table monitors
			table crystals
	]]
	
	this.member.auxPowerTime = 120
	this.member.monitorAlertEnabled = false
	this.member.countdownRunning = false
	this.member.countdownEnabled = false
	this.member.powerEnabled = true
	
	function this:init (model)
		self.model = model
		
		self.panel = cs.new 'Panel' (self.model.Override.FrontPanel)
		self.switch1 = cs.new 'Switch' (self.model.Override.Model.Switch1)
		self.switch2 = cs.new 'Switch' (self.model.Override.Model.Switch2)
	
		self.monitors = {}
		self.crystals = self.model.Override.Model.CrystalBox:GetChildren()
		
		self.powerStateChanged = cs.new 'Signal' ()
	
		self.switch1.switchStateChanged:Connect(function (isDown)
			self:switchChanged(isDown)
		end)
		self.switch1:setIndicator(BrickColor.Green(), BrickColor.Green())
	end
	
	function this.member:monitorAlert(enabled)
		if self.monitorAlertEnabled == enabled then return end
		self.monitorAlertEnabled = enabled
		
		if enabled then
			self.monitors = {}
			for _,screenModel in next, self.model.Monitors:GetChildren() do
				local gui = powerMonitorSurfaceGui:Clone()
				gui.Name = powerMonitorSurfaceGuiName
				gui.Adornee = screenModel:FindFirstChild"Screen"

				for _, guiPart in next, gui.Frame:GetChildren() do
					guiPart.Visible = false
				end

				gui.Parent = screenModel
				table.insert(self.monitors, gui)
			end
			
			self:runMonitorAnimation()
		else
			for i,v in next, self.monitors do
				v:Destroy()
			end
		end
	end
	
	function this.member:runMonitorAnimation() 
		local stateMax = #powerMonitorSurfaceGui.Frame:GetChildren()
		
		for i = 1, stateMax do
			wait(math.random(50, 250) / 100)		
			for _, gui in next, self.monitors do
				if not gui.Parent then return end -- Monitors disabled
			
				if gui.Frame:FindFirstChild(i) then
					gui.Frame[i].Visible = true
				end
			end
		end
	
	end
	
	function this.member:setMonitorCount(count)
		local stateMax = #powerMonitorSurfaceGui.Frame:GetChildren()
		
		for _, gui in next, self.monitors do
			if gui.Frame:FindFirstChild(stateMax) then
				gui.Frame[stateMax].Text = count .. "s"
			end
		end
	end
	
	function this.member:switchChanged(isDown)
		if isDown then
			self:runCountdownAsync()
		else
			self:endCountdown()
		end
	end
	
	function this.member:endCountdown()
		self:monitorAlert(false)
	
		self.countdownEnabled = false
		self:setCrystalEnablePercent(1)
		self.switch1:setIndicator(BrickColor.Green(), BrickColor.Green())
			
		if not self.powerEnabled then
			self.powerEnabled = true
			self.powerStateChanged:Fire(true)
		end
	end
	
	function this.member:setCrystalEnablePercent(percent)
		local increment = 100 / #self.crystals / 100
		
		for i,v in next, self.crystals do
			if v.BrickColor == crystalColor then -- The neon crystals have a specific color
				if increment * i > percent then
					v.Material = Enum.Material.SmoothPlastic
				else
					v.Material = Enum.Material.Neon
				end
			end
		end
	end
	
	function this.member:runCountdownAsync()	
		if self.countdownRunning then return end
	
		self:monitorAlert(true)
	
		self.countdownEnabled = true
		self.countdownRunning = true
		
		self.switch1:setIndicator(BrickColor.Yellow(), BrickColor.Yellow())
	
		coroutine.wrap(function () 
			local countdownTime = self.auxPowerTime
			
			while self.countdownEnabled and countdownTime > 0 do
				countdownTime = countdownTime - 1
				self:setMonitorCount(countdownTime)
				
				self:setCrystalEnablePercent(countdownTime / self.auxPowerTime)
				
				wait(1)
			end
			
			if self.countdownEnabled then
				self.powerEnabled = false
				self.countdownEnabled = false
				self.powerStateChanged:Fire(false)
				self:monitorAlert(false)
				self:setCrystalEnablePercent(0)
				self.switch1:setIndicator(BrickColor.Red(), BrickColor.Red())
			end
			
			self.countdownRunning = false
		end)()
	end
	
	-- public properties
	this.get.powerEnabled = true
	
	-- public methods
	this.get.endCountdown = true
	
	-- public events
	this.get.powerStateChanged = true
	
end)

return false