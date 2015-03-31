-- Services
local projectRoot = game:GetService("ServerScriptService")

-- Includes
local Classes = require(projectRoot.Modules.ClassSystem)
local Util = require(projectRoot.Modules.Utilities)
local LEnums = require(projectRoot.Modules.Enums)

--[[
	init(string name, table sectionList, table transporterList)

	Properties:
		readonly string name

	Methods:
		table getSections()
		Section getSection(string name)
		table getTransporters()
		Train getTrain()
		PowerSystem getPowerSysten()
		LEnums::SectionMode getMode()
		void setMode(LEnums::SectionMode mode)
	Events:

]]

Classes.class 'Network' (function (this) 

	--[[
		Internal properties:
			table sections
			table transporters
			Train train
			PowerSystem powerSystem
			LEnums::SectionMode mode
	]]

	function this:init (name, sectionList, transporterList, train, powerSystem)
		self.name = name
		self.sections = Util.shallowCopyTable(sectionList)
		self.transporters =  Util.shallowCopyTable(transporterList)
		self.train = train
		self.powerSystem = powerSystem
		self.mode = LEnums.SectionMode:GetItem"Normal"
	end
	
	-- Getters
	function this.member:getTransporters()
		return Util.shallowCopyTable(self.transporters)
	end
	
	function this.member:getSections() 
		return Util.shallowCopyTable(self.sections)
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
	
	function this.member:getPowerSysten()
		return self.PowerSystem
	end
	
	function this.member:getMode()
		return self.mode
	end
	
	function this.member:setMode(mode)
		local sMode = LEnums.SectionMode
		
		if self.mode == mode then
			return
		elseif mode == sMode:GetItem"Unpowered" then
			for _,v in next, self:getSections() do
				v:setMode(LEnums.SectionMode:GetItem"Unpowered")
			end
			for _,v in next, self:getTransporters() do
				v:setMode(LEnums.DeviceMode:GetItem"Unpowered")
			end
		elseif mode == sMode:GetItem"Normal" then
			for _,v in next, self:getSections() do
				v:setMode(LEnums.SectionMode:GetItem"Normal")
			end
			for _,v in next, self:getTransporters() do
				v:setMode(LEnums.DeviceMode:GetItem"Normal")
			end
		elseif mode == sMode:GetItem"Lockdown" then
			for _,v in next, self:getSections() do
				v:setMode(LEnums.SectionMode:GetItem"Lockdown")
			end
			for _,v in next, self:getTransporters() do
				v:setMode(LEnums.DeviceMode:GetItem"GeneralLock")
			end
		else
			error("Bad mode " .. tostring(mode))
		end
		
		self.mode = mode
	end
	
	-- public properties
	this.get.name = true
	
	-- public methods
	this.get.getSections = true
	this.get.getSection = true
	this.get.getTransporters = true
	this.get.getTrain = true
	this.get.getPowerSysten = true
	this.get.setMode = true
	this.get.getMode = true
end)

return false