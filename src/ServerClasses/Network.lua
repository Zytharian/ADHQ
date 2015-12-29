-- Services
local projectRoot = game:GetService("ServerScriptService")

-- Includes
local Classes = require(projectRoot.Modules.ClassSystem)
local Util = require(projectRoot.Modules.Utilities)
local LEnums = require(projectRoot.Modules.Enums)

--[[
	init(string name, table sectionList, table transporterList, Train train, table rings)

	Properties:
		readonly string name
		bool lockoutEnabled

	Methods:
		table getSections()
		Section getSection(string name)
		table getTransporters()
		table getRings()
		Train getTrain()
		Power getPower()
		LEnums::SectionMode getMode()
		void setMode(LEnums::SectionMode mode)
	Events:
		lockoutChanged(bool lockoutEnabled)
]]

Classes.class 'Network' (function (this) 

	--[[
		Internal properties:
			Rbx::Model model
			table sections
			table transporters
			table rings
			Train train
			LEnums::SectionMode mode
			string ringAddress
			Power power
	]]

	function this:init (name, sectionList, transporterList, train, rings, power)
		self.name = name
		self.sections = Util.shallowCopyTable(sectionList)
		self.transporters =  Util.shallowCopyTable(transporterList)
		self.train = train
		self.rings = rings
		self.mode = LEnums.SectionMode:GetItem"Normal"
		self.power = power
		
		if self.power then
			self.power.allowPowerdownSequence = (function ()
				return not self.lockoutEnabled
			end)
			
			self.power.powerStateChanged:Connect(function (enabled)
				if self.lockoutEnabled then
					return
				end
				
				self:setMode(LEnums.SectionMode:GetItem(enabled and "Normal" or "Unpowered"))
			end)
		end
		
		self.lockoutEnabled = false
		self.lockoutChanged = Classes.new 'Signal' ()
	end
	
	-- Getters
	function this.member:getTransporters()
		return Util.shallowCopyTable(self.transporters)
	end
	
	function this.member:getSections() 
		return Util.shallowCopyTable(self.sections)
	end
	
	function this.member:getRings()
		return Util.shallowCopyTable(self.rings)
	end
	
	function this.member:getSection(name)
		for _,v in next, self.sections do
			if v.name == name then
				return v
			end
		end
	end
	
	function this.member:getTrain()
		return self.train
	end
	
	function this.member:getPower()
		return self.power
	end
	
	function this.member:getMode()
		return self.mode
	end
	
	function this.member:setMode(mode)
		local sMode = LEnums.SectionMode
		
		if mode == sMode:GetItem"Unpowered" then
			for _,v in next, self:getSections() do
				v:setMode(LEnums.SectionMode:GetItem"Unpowered")
			end
			for _,v in next, self:getTransporters() do
				v:setMode(LEnums.DeviceMode:GetItem"Unpowered")
			end
			for _,v in next, self:getRings() do
				v.isEnabled = false
			end
		elseif mode == sMode:GetItem"Normal" then
			for _,v in next, self:getSections() do
				v:setMode(LEnums.SectionMode:GetItem"Normal")
			end
			for _,v in next, self:getTransporters() do
				v:setMode(LEnums.DeviceMode:GetItem"Normal")
			end
			for _,v in next, self:getRings() do
				v.isEnabled = true
			end
		elseif mode == sMode:GetItem"Lockdown" then
			for _,v in next, self:getSections() do
				v:setMode(LEnums.SectionMode:GetItem"Lockdown")
			end
			for _,v in next, self:getTransporters() do
				v:setMode(LEnums.DeviceMode:GetItem"GeneralLock")
			end
			for _,v in next, self:getRings() do
				v.isEnabled = false
			end
		else
			error("Bad mode " .. tostring(mode))
		end
		
		self.mode = mode
	end
	
	-- public properties
	this.get.name = true
	this.get.lockoutEnabled = true
	
	function this.set:lockoutEnabled (index, value)	
		if self.lockoutEnabled == value then
			return
		end
		
		self.lockoutEnabled = value
		
		if value then
			self.power:endCountdown()
		end
		self.lockoutChanged:Fire(value)
	end

	-- public methods
	this.get.getSections = true
	this.get.getRings = true
	this.get.getSection = true
	this.get.getTransporters = true
	this.get.getTrain = true
	this.get.setMode = true
	this.get.getMode = true
	this.get.getPower = true
	
	-- public events
	this.get.lockoutChanged = true
end)

return false