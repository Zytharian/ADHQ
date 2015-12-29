-- Zytharian (roblox: Legend26)

-- Services
local projectRoot = game:GetService("ServerScriptService")

-- Includes
local Classes = require(projectRoot.Modules.ClassSystem)
local LEnums = require(projectRoot.Modules.Enums)
local Util = require(projectRoot.Modules.Utilities)

--[[
	init(Rbx::Model model)

	Properties:
		readonly bool isRunning
		readonly bool isElevator
		
	Methods:

	Events:
		void floorChangeComplete()
		void setMode(LEnums::DeviceMode mode)
		
	Callbacks:
		table allowFloorChange()
]]

Classes.class 'Elevator' (function (this) 

	--[[
		Internal properties:
			Rbx::Model model
			table outerDoors
				-- { { Door , Vector3 pos, Rbx::TextButton} }
			Rbx::TextButton optionButton
			EventPropagator buttonProp
			LEnums::DeviceMode mode
	]]

	function this:init (model)
		self.model = model
		self.isRunning = false
		self.floorChangeComplete = Classes.new 'Signal' ()
		
		self.model.Unit.PrimaryPart = self.model.Unit.Ref
		
		self.mode = LEnums.DeviceMode:GetItem"Normal"
		
		-- Elevator?
		local outerDoorModels = model.Doors:GetChildren()
		
		self.isElevator = #outerDoorModels > 1
		self.outerDoors = {}
		
		if not self.isElevator then
			self.outerDoors[1] = {Classes.new 'Door' (model.Doors.OuterDoor), model.Doors.OuterDoor.Main.Position}
			self.outerDoors[1][1]:changeStateAsync(true) -- initially open
			self.outerDoors[1][1]:setMode(LEnums.DeviceMode:GetItem"InterfaceDisabled")
			self.currentOuter = self.outerDoors[1]
		else
			for _,v in next, outerDoorModels do
				table.insert(self.outerDoors, {Classes.new 'Door' (v), v.Main.Position})
			end
			
			-- Seal doors on other floors
			for _,v in next, self.outerDoors do
				v[1]:setMode(LEnums.DeviceMode:GetItem "InterfaceDisabled")
				
				if math.abs(v[2].Y - model.Unit.Ref.Position.Y) < 0.5 then
					self.currentOuter = v
					self.currentOuter[1]:changeStateAsync(true) -- initally open
				else
					v[1]:changeStateAsync(false) -- initally closed
				end
			end
			
			if not self.currentOuter then
				error("No current floor detected for elevator " .. model:GetFullName())
			end
			
			-- Set up elevator gui
			self.buttonProp = Classes.new 'EventPropagator' ("TextButton", "MouseButton1Click")
			
			self.optionButton = model.Unit.Display.TransporterSurfaceGui.Options.Elevator
			self.buttonProp:addObject(self.optionButton)
			
			self.buttonProp.eventFired:Connect(function (player, button)
				self:onButtonClick(player, button)
			end)
			
			-- Populate list of floors
			table.sort(self.outerDoors, function(a,b) return a[2].Y > b[2].Y end)
			for i,v in next, self.outerDoors do
				-- Add button
				local button = self.model.Unit.Display.TransporterSurfaceGui.Main.Template:Clone()
				button.Parent = self.model.Unit.Display.TransporterSurfaceGui.Main.Elevator
				button.Position = UDim2.new(0, 0, 0, 75*(i- 1))
				button.Visible = true
				button.Text = "||| Go to floor " .. (#self.outerDoors - i + 1)
				v[3] = button
				self.buttonProp:addObject(button)
				
				v[1].controllerUsed:Connect(function (player)
					self:changeFloor(v)
				end)
			end
			
		end
	end
	
	function this.member:onButtonClick(player, button)
		if self.isRunning or self.mode ~= LEnums.DeviceMode:GetItem"Normal" then
			return
		end
	
		if button == self.optionButton then
			self.model.Unit.Display.TransporterSurfaceGui.Main.Elevator.Visible = true
			self.model.Unit.Display.TransporterSurfaceGui.Main.Transporter.Visible = false
			return
		end
		
		if not self.isElevator then
			return
		end
		
		local data
		for _,v in next, self.outerDoors do
			if v[3] == button then
				data = v
				break
			end
		end
		if not data then 
			return
		end
	
		self:changeFloor(data)
	end
	
	function this.member:changeFloor(data)
		if not self.isElevator or self.isRunning or self.currentOuter == data or self.mode ~= LEnums.DeviceMode:GetItem"Normal" then
			return
		end
		self.isRunning = true
		
		-- See if floor change allowed, check result
		local players = self.allowFloorChange()
		if not players then
			return
		end
		
		-- Close outer door 
		self.currentOuter[1]:changeOpenState()
		self.currentOuter[1]:changeStateAsync(false)
		repeat wait() until not self.currentOuter[1].isRunning and not self.currentOuter[1].isOpen
		
		local welds = {}
		Util.Welding.addSuperList(welds)
		
		-- No need for this since roblox improved platform physics
		-- Weld players to moveWith part
		--for _,v in next, players do
		--	if v.Character and v.Character:FindFirstChild"Torso" then
		--		Util.Welding.weld(v.Character.Torso, moveWith, welds) -- self.model.Unit.PrimaryPart, welds)
		--	end
		--end
		
		-- Weld all elevator parts to reference part
		for _,v in next, Util.findAll(self.model.Unit, "BasePart") do
			if v ~= self.model.Unit.RefferenceSite and v ~= self.model.Unit.PrimaryPart then
				Util.Welding.weld(v, self.model.Unit.PrimaryPart, welds)
				v.Anchored = false
			end
		end
		Util.Welding.weld(self.model.Unit.PrimaryPart, self.model.Unit.RefferenceSite, welds, "Motor")
		self.model.Unit.PrimaryPart.Anchored = false
		
		wait() -- welds/motors take a frame to actually create/delete properly
		-- Move reference part. instantly if no players inside
		local diff = data[2].Y - self.currentOuter[2].Y
		if #players == 0 then
			self.model.Unit.RefferenceSite.CFrame = self.model.Unit.RefferenceSite.CFrame + Vector3.new(0, diff, 0)
		else
			local smooth = 6

			local change = Vector3.new(0, (diff > 0 and 1 or -1)/smooth, 0)
			for i=1, math.abs(diff*smooth) do
				self.model.Unit.RefferenceSite.CFrame = self.model.Unit.RefferenceSite.CFrame + change
				wait()
			end		
		end
		
		-- Remove welds, anchor elevator
		for _,v in next, Util.findAll(self.model.Unit, "BasePart") do
			v.Anchored = true
		end
		
		Util.Welding.removeSuperList(welds)
		for i,v in next, welds do
			i:Destroy()
		end
		
		-- Open new outer door
		self.currentOuter = data	
		self.isRunning = false
		
		self:doModeAttrib(self.mode)
		
		self.floorChangeComplete:Fire()
	end

	function this.member:setMode(mode)
		if self.mode == mode then 
			return
		end
			
		self:doModeAttrib(mode)
		self.mode = mode
	end
	
	function this.member:doModeAttrib(mode)
		local deviceMode = LEnums.DeviceMode
		
		if mode == deviceMode:GetItem"Unpowered" then
			if not self.isRunning then
				self.currentOuter[1]:setMode(deviceMode:GetItem"Unpowered")
				
				for i,v in next, self.outerDoors do
					if v ~= self.currentOuter then
						v[1]:setMode(deviceMode:GetItem"Unpowered")
					end
				end
			end
		elseif mode == deviceMode:GetItem"Normal" then
			if not self.isRunning then
				self.currentOuter[1]:setMode(deviceMode:GetItem"InterfaceDisabled")
				self.currentOuter[1]:changeStateAsync(true)
				
				for i,v in next, self.outerDoors do
					if v ~= self.currentOuter then
						v[1]:setMode(deviceMode:GetItem"InterfaceDisabled")
						v[1]:changeStateAsync(false)
					end
				end
			end
		elseif mode == deviceMode:GetItem"LocalLock" then
			if not self.isRunning then
				self.currentOuter[1]:setMode(deviceMode:GetItem"LocalLock")
				
				for i,v in next, self.outerDoors do
					if v ~= self.currentOuter then
						v[1]:setMode(deviceMode:GetItem"LocalLock")
					end
				end
			end
		elseif mode == deviceMode:GetItem"GeneralLock" then
			if not self.isRunning then
				self.currentOuter[1]:setMode(deviceMode:GetItem"GeneralLock")
				
				for i,v in next, self.outerDoors do
					if v ~= self.currentOuter then
						v[1]:setMode(deviceMode:GetItem"GeneralLock")
					end
				end
			end
		else
			error("Bad elevator mode")
		end
		
	end
	
	-- public properties
	this.get.isRunning = true
	this.get.isElevator = true
	this.get.setMode = true
	
	-- public events
	this.get.floorChangeComplete = true
	
	-- public callbacks
	this.get.allowFloorChange = true
	this.set.allowFloorChange = true
	
end)

return false