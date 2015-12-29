-- Services
local projectRoot = game:GetService("ServerScriptService")
local RS = game:GetService("ReplicatedStorage")

-- Includes
local Classes = require(projectRoot.Modules.ClassSystem)
local Util = require(projectRoot.Modules.Utilities)
local LEnums = require(projectRoot.Modules.Enums)

--[[
	init(Rbx::Model model)

	Properties:
		readonly string name
		
	Methods:
		void setMode(Enum DeviceMode)
		Enum::DeviceMode getMode()
		Rbx::CFrame getAdjustedRefCFrame()
		void doTeleport(Transporter destination)
		void linkTransporter(Transporter other)
		bool isActive()

	Events:

	
]]

--------
-- Header end
--------

if not RS:FindFirstChild"CR_TeleportRequest" then
	Instance.new("RemoteEvent", RS).Name = "CR_TeleportRequest"
end

Classes.class 'Transporter' (function (this) 

	--[[
		Internal properties:
			string name
			Rbx::Model model
			Door mainDoor
			Door shutter
			bool isRunning
			Enum::DeviceMode mode
			table linkedTransporters
			EventPropagator buttonProp
			table destinationButtons
				-- {TextButton = Transporter destination}
			number numLinkedTo
			Elevator elevator
			Rbx::TextButton optionButton
	]]

	function this:init (model)
		self.model = model
		self.name = model.Name
		self.isRunning = false
		self.mode = LEnums.DeviceMode:GetItem"Normal"
		self.linkedTransporters = {}
		self.numLinkedTo = 0
		
		RS.TransporterSurfaceGui:Clone().Parent = model.Unit.Display
		model.PrimaryPart = model.Unit.Ref
		
		-- Create outer door
		self.mainDoor = Classes.new 'Door' (model.Unit.Inner)
		
		-- Create shutter
		self.shutter = Classes.new 'Door' (model.Unit.Shutter)
		self.shutter:setMode(LEnums.DeviceMode:GetItem"InterfaceDisabled")
		self.shutter:changeStateAsync(true)
	
		-- Set up shutter's gui
		self.buttonProp = Classes.new 'EventPropagator' ("TextButton", "MouseButton1Click")
		
		self.optionButton = model.Unit.Display.TransporterSurfaceGui.Options.Transport
		self.buttonProp:addObject(self.optionButton)
		
		self.destinationButtons = {}

		self.buttonProp.eventFired:Connect(function (player, button)
			self:onButtonClicked(player, button)
		end)
		
		self.elevator = Classes.new 'Elevator' (model)
		if not self.elevator.isElevator then
			return
		end
		
		self.elevator.floorChangeComplete:Connect(function ()
			self:doModeAttrib(self.mode)
		end)
		
		self.elevator.allowFloorChange = (function ()
			if self.isRunning or self.mode ~= LEnums.DeviceMode:GetItem"Normal" then
				return
			end
			
			-- Close shutter and inner door
			self.mainDoor:setMode(LEnums.DeviceMode:GetItem"LocalLock")
			self.shutter:changeStateAsync(false)
			repeat wait() until not self.mainDoor.isOpen and not self.shutter.isOpen 
				and not self.mainDoor.isRunning and not self.shutter.isRunning
			
			return self:getPlayersInside()
		end)
		
	end

	function this.member:onButtonClicked(player, button)
		if button == self.optionButton then
			self.model.Unit.Display.TransporterSurfaceGui.Main.Elevator.Visible = false
			self.model.Unit.Display.TransporterSurfaceGui.Main.Transporter.Visible = true
			return
		end
		
		local destination  = self.destinationButtons[button]
		if not destination or self.mode ~= LEnums.DeviceMode:GetItem"Normal" 
			or destination:getMode() ~= LEnums.DeviceMode:GetItem"Normal" 
			or self:isActive() or destination:isActive() then
			
			return
		end
		
		-- Do both async
		coroutine.wrap(function ()
			self:doTeleport(destination)
		end)()
		
		destination:doTeleport(self)	
	end
	
	function this.member:doTeleport(destination)
		if self:isActive() then
			return
		end
		self.isRunning = true
		
		-- Close and lock doors
		self.mainDoor:setMode(LEnums.DeviceMode:GetItem"LocalLock")
		self.shutter:changeStateAsync(false)
		
		repeat wait() until not self.mainDoor.isOpen and not self.shutter.isOpen 
			and not self.mainDoor.isRunning and not self.shutter.isRunning

		-- Transport players
		for _,v in next, self:getPlayersInside() do
			local newCF = destination:getAdjustedRefCFrame():toWorldSpace(
				self:getAdjustedRefCFrame():toObjectSpace(v.Character.Torso.CFrame))
				
			if RS:FindFirstChild"CR_TeleportRequest" then
				RS.CR_TeleportRequest:FireClient(v, {newCF})
			else
				error("No RS.CR_TeleportRequest remote event")
			end
		end
		
		wait(2)
		
		self.isRunning = false
		
		self:doModeAttrib(self.mode)
	end
	
	function this.member:getMode()
		return self.mode
	end
	
	function this.member:setMode(mode)
		if self.mode == mode then 
			return
		end
		
		self:doModeAttrib(mode)
		self.elevator:setMode(mode)
		self.mode = mode
	end
	
	function this.member:doModeAttrib(mode)
		local deviceMode = LEnums.DeviceMode
	
		if mode == deviceMode:GetItem"Unpowered" then
			if not self.isRunning and not self.elevator.isRunning then
				self.mainDoor:setMode(deviceMode:GetItem"Unpowered")
			end
			
			for _,v in next, self.model.Unit.Display.TransporterSurfaceGui:GetChildren() do
				v.Visible = false
			end
			
			self:setLightingEnabled(false)
			
		elseif mode == deviceMode:GetItem"Normal" then
			if not self.isRunning and not self.elevator.isRunning then
				self.mainDoor:setMode(deviceMode:GetItem"Normal")
				self.shutter:changeStateAsync(true)
			end
			
			for _,v in next, self.model.Unit.Display.TransporterSurfaceGui:GetChildren() do
				v.Visible = true
			end
			
			self:setLightingEnabled(true)
			
		elseif mode == deviceMode:GetItem"LocalLock" then
			if not self.isRunning and not self.elevator.isRunning then
				self.mainDoor:setMode(deviceMode:GetItem"LocalLock")
				self.shutter:changeStateAsync(false)
			end
			self.model.Unit.Display.TransporterSurfaceGui.Background.Visible = true
			self:setLightingEnabled(true)
			
		elseif mode == deviceMode:GetItem"GeneralLock" then
			if not self.isRunning and not self.elevator.isRunning then
				self.mainDoor:setMode(deviceMode:GetItem"GeneralLock")
				self.shutter:changeStateAsync(false)
			end
			self.model.Unit.Display.TransporterSurfaceGui.Background.Visible = true
			self:setLightingEnabled(true)
			
		else
			error("Unknown door mode: " .. tostring(mode))
		end
	end
	
	function this.member:setLightingEnabled(enabled)
		if self.model.Unit:FindFirstChild"Light" then
			self.model.Unit.Light.RealLight.SurfaceLight.Enabled = enabled
			self.model.Unit.Light.Neon.Material = enabled and Enum.Material.Neon or Enum.Material.Plastic 
		end
	end
	
	function this.member:getAdjustedRefCFrame()
		return self.model.PrimaryPart.CFrame + Vector3.new(0,4,0)
	end
	
	function this.member:linkTransporter(other)
		if self.linkedTransporters[other]  then
			error("Attempted double link to " .. other.name)
		end
		
		self.linkedTransporters[other] = true
		self.numLinkedTo = self.numLinkedTo + 1
	
		-- Add button on gui
		local button = self.model.Unit.Display.TransporterSurfaceGui.Main.Template:Clone()
		button.Parent = self.model.Unit.Display.TransporterSurfaceGui.Main.Transporter
		button.Position = UDim2.new(0, 0, 0, 75*(self.numLinkedTo - 1))
		button.Visible = true
		button.Text = "||| " .. other.name
		
		self.destinationButtons[button] = other
		self.buttonProp:addObject(button)
	end
	
	function this.member:getPlayersInside()
		-- Create region
		local R3 = Util.getRegion3Around(self:getAdjustedRefCFrame(), Vector3.new(6, 4, 12))
		
		-- Get players
		return Util.getPlayersInRegion3(R3, self.model)
	end
	
	function this.member:isActive()
		return self.isRunning or self.elevator.isRunning
	end
	
	-- public properties
	this.get.name = true
	
	-- public methods
	this.get.getMode = true
	this.get.setMode = true
	this.get.doTeleport = true
	this.get.linkTransporter = true
	this.get.getAdjustedRefCFrame = true
	this.get.isActive = true
end)

return false