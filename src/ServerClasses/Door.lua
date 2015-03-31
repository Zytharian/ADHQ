-- Services
local projectRoot = game:GetService("ServerScriptService")

-- Includes
local Classes = require(projectRoot.Modules.ClassSystem)
local LEnums = require(projectRoot.Modules.Enums)

--[[
	init(Rbx::Model doorModel EventPropagator clickPropagator)

	Properties:
		readonly string name
		readonly bool isOpen
		readonly bool isRunning

	Methods:
		void changeOpenState()
		void changeStateAsync(bool haveOpen)
		void setMode(Enum DeviceMode)
		Enum::DeviceMode getMode()

	Events:
		controllerUsed(Rbx::Player user)
		
]]

Classes.class 'Door' (function (this) 

	--[[
		Internal properties:
			Rbx::Model model
			boolean isOpen
			boolean isRunning
			table clickers
			DeviceMode mode
			EventPropagator propagator
	]]

	function this:init (model)
		self.name = model.Name
		self.model = model
		self.isOpen = false
		self.isRunning = false
		self.clickers = {}
		self.mode = LEnums.DeviceMode:GetItem"Normal"
		self.controllerUsed = Classes.new 'Signal' ()
		
		local hasController = self.model:FindFirstChild"Control" 
		
		if hasController then
			self.propagator = Classes.new 'EventPropagator' ("ClickDetector", "MouseClick")
			
			for i,v in next, model.Control:GetChildren() do
				if v.Name:find"Main" then
					local CD = Instance.new("ClickDetector", v)
					CD.MaxActivationDistance = 8
					table.insert(self.clickers, CD)
					
					self.propagator:addObject(CD)
				end
			end
		
			self.propagator.eventFired:Connect(function (player, object)
				self.controllerUsed:Fire()
				if self.mode == LEnums.DeviceMode:GetItem"Normal" then
					self:changeOpenState()
				end
			end)
		end
		
		local onTouched = (function ()
			self.controllerUsed:Fire()
			if self.mode == LEnums.DeviceMode:GetItem"Normal" and not self.isOpen then
				self:changeOpenState()
				wait(5)
				if self.isOpen and self.mode == LEnums.DeviceMode:GetItem"Normal" then
					self:changeOpenState()
				end
			end
		end)
		
		local hasCustomTouch = self.model:FindFirstChild"CustomTouch" and true or false
		local doorList = {Left = true, Right = true, Up = true, Down = true, Rotate = true, PartialRotate = true}
		for _,v in next, model:GetChildren() do
			if doorList[v.Name] and v:FindFirstChild"Main" then
				v.PrimaryPart = v.Main
			
				if not hasController and not hasCustomTouch then
					v.PrimaryPart.Touched:connect(onTouched)
				end
			
			elseif v.Name == "CustomTouch" then
				v.Touched:connect(onTouched)
			end
		end
		
		--
		if self.model:FindFirstChild"ForceField" then
			self.isOpen = not self.model.ForceField.Main.CanCollide
		end
		
	end
	
	function this.member:changeOpenState()
		if self.isRunning then 
			return
		end
		self.isRunning = true
		self.isOpen = not self.isOpen
		
		local smooth = 3
		
		if self.model:FindFirstChild"Left" or self.model:FindFirstChild"Right" then
			self:openStateImpl_Horizontal(smooth)
		elseif self.model:FindFirstChild"Up" or self.model:FindFirstChild"Down" then
			self:openStateImpl_Vertical(smooth)
		elseif self.model:FindFirstChild"Rotate" then
			self:openStateImpl_Rotate(smooth)
		elseif self.model:FindFirstChild"PartialRotate" then
			self:openStateImpl_PartialRotate(smooth)
		elseif self.model:FindFirstChild"ForceField" then
			self:openStateImpl_ForceField()
		end
		
		self.isRunning = false
	end
	
	-- TODO: Improve animation
	function this.member:openStateImpl_ForceField()
		local part = self.model.ForceField.Main
		
		-- remember that self.isOpen has already been changed
		for i = (self.isOpen and 6 or 10), (self.isOpen and 10 or 6), (self.isOpen and 1 or -1) do
			part.Transparency = i / 10
			wait()
		end
		
		part.CanCollide = not self.isOpen
	end
	
	function this.member:openStateImpl_Horizontal(smooth)
		local ref = nil
		
		local hasLeft = self.model:FindFirstChild"Left"
		local hasRight = self.model:FindFirstChild"Right"
		
		if hasLeft then
			ref = self.model.Left.PrimaryPart
		else
			ref = self.model.Right.PrimaryPart
		end
		
		local refNum = ref.Size.Z --ref.Size.x > ref.Size.y and ref.Size.x or ref.Size.y
		
		for i=1, refNum * smooth do
			local CF = (ref.CFrame*CFrame.Angles(0,0,math.pi/2)).lookVector * (1/smooth)
			if not hasLeft and hasRight then
				CF = -CF
			end
			
			if hasLeft then
				self.model.Left:SetPrimaryPartCFrame(
					self.model.Left.PrimaryPart.CFrame + (self.isOpen and CF or -CF))
			end
		
			if hasRight then
				self.model.Right:SetPrimaryPartCFrame(
					self.model.Right.PrimaryPart.CFrame + (self.isOpen and -CF or CF))
			end
			
			wait()
		end
	end
	
	function this.member:openStateImpl_Vertical(smooth)
		local ref
	
		local hasUp = self.model:FindFirstChild"Up"
		local hasDown = self.model:FindFirstChild"Down"
		
		if hasUp then
			ref = self.model.Up.PrimaryPart
		else
			ref = self.model.Down.PrimaryPart
		end
		
		local refNum = ref.Size.Y
		
		local CF = Vector3.new(0,1/smooth,0)
		for i=1, refNum * smooth do
			if hasUp then
				self.model.Up:SetPrimaryPartCFrame(
					self.model.Up.PrimaryPart.CFrame + (self.isOpen and CF or -CF))
			end
			
			if hasDown then
				self.model.Down:SetPrimaryPartCFrame(
					self.model.Down.PrimaryPart.CFrame + (self.isOpen and -CF or CF))
			end
			
			wait()
		end
	
	end
	
	-- TODO: calculate values using smooth
	function this.member:openStateImpl_Rotate(smooth)		
		local Angle = CFrame.Angles(0, 0, math.rad(self.isOpen and 2 or -2))
		for i=1, 45 do
			for i,v in next, self.model:GetChildren() do
				if v.Name == "Rotate" then
					v:SetPrimaryPartCFrame(v.PrimaryPart.CFrame * Angle)
				end
			end
			wait()
		end
	
	end
	
	-- TODO: calculate values using smooth
	function this.member:openStateImpl_PartialRotate(smooth)		
		local Angle = CFrame.Angles(math.rad(self.isOpen and -4 or 4), 0, 0)
		for i=1, 40 do
			for i,v in next, self.model:GetChildren() do
				if v.Name == "PartialRotate" then
					v:SetPrimaryPartCFrame(v.PrimaryPart.CFrame * Angle)
				end
			end
			wait()
		end
	
	end
	
	function this.member:setMode(mode)
		self.mode = mode
		
		local DeviceMode = LEnums.DeviceMode
		local mains
		local hasController = self.model:FindFirstChild"Control" and self.model.Control:FindFirstChild"Main1" 
			and self.model.Control:FindFirstChild"Main2"and self.model.Control:FindFirstChild"Main3"
		if hasController then
			mains = {
				self.model.Control.Main1;
				self.model.Control.Main2;
				self.model.Control.Main3;
			}
		end
		if mode == DeviceMode:GetItem"Unpowered" then
			if not hasController then return end
			mains[1].BrickColor = BrickColor.Black()
			mains[2].BrickColor = BrickColor.Black()
			mains[3].BrickColor = BrickColor.Black()
		elseif mode == DeviceMode:GetItem"Normal" then 
			if hasController then 
				mains[1].BrickColor = BrickColor.new("Medium blue")
				mains[2].BrickColor = BrickColor.new("Medium blue")
				mains[3].BrickColor = BrickColor.new("Medium blue")
			else
				self:changeStateAsync(false)
			end
		elseif mode == DeviceMode:GetItem"LocalLock" then
			if self.isOpen then
				self:changeStateAsync(false)
			end
			
			if not hasController then return end
			mains[1].BrickColor = BrickColor.Red()
			mains[2].BrickColor = BrickColor.Red()
			mains[3].BrickColor = BrickColor.Red()
		elseif mode == DeviceMode:GetItem"GeneralLock" then
			if self.isOpen then
				self:changeStateAsync(false)
			end
		
			if not hasController then return end
			mains[1].BrickColor = BrickColor.Black()
			mains[2].BrickColor = BrickColor.Red()
			mains[3].BrickColor = BrickColor.Red()
		elseif mode == DeviceMode:GetItem"InterfaceDisabled" then
			if not hasController then return end
			mains[1].BrickColor = BrickColor.new("Medium blue")
			mains[2].BrickColor = BrickColor.Black()
			mains[3].BrickColor = BrickColor.Black()
		else
			self.mode = DeviceMode:GetItem"Normal"
			error("Unknown door mode: " .. tostring(mode))
		end
	end
	
	function this.member:changeStateAsync(haveOpen)
		coroutine.wrap(function ()
			while self.isRunning do wait() end
			if self.isOpen ~= haveOpen then
				self:changeOpenState()
			end
		end)()
	end
	
	function this.member:getMode()
		return self.mode
	end
	
	-- public properties
	this.get.name = true
	this.get.isOpen = true
	this.get.isRunning = true
	
	-- public methods
	this.get.changeOpenState = true
	this.get.setMode = true
	this.get.getMode = true
	this.get.changeStateAsync = true
	
	-- public events
	this.get.controllerUsed = true
end)

return false