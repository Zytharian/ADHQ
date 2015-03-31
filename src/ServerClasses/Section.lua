-- Services
local projectRoot = game:GetService("ServerScriptService")

-- Includes
local Classes = require(projectRoot.Modules.ClassSystem)
local LEnums = require(projectRoot.Modules.Enums)
local Util = require(projectRoot.Modules.Utilities)

--[[
	Initializer init(string name)

	Properties:
		readonly string name
		readonly bool ligtsEnabled
	
	Methods:
		table getDoors()
		Door getDoor(string name)
		void setLightingColor(Color3 color)
		void setLightingEnabled(bool enabled)
		void setMode(LEnums::SectionMode mode)
		LEnums::SectionMode getMode()
		
	Events:

]]

Classes.class 'Section' (function (this) 

	--[[
		Internal properties:
			table doors
			table lights
			LEnums::SectionMode
	]]

	function this:init (name, doors, lights, consoleModels)
		self.name = name
		self.doors = doors
		self.lights = lights
		self.ligtsEnabled = true
		
		if not consoleModels then
			self.consoleModels = {}
		else
			self.consoleModels = consoleModels
		end
		
		self.mode = LEnums.SectionMode:GetItem"Normal"
	end
	
	-- Getters
	function this.member:getDoors() 
		return Util.shallowCopyTable(self.doors)
	end
	
	function this.member:getDoor(name)
		for _,v in next, self.doors do
			if v.name == name then
				return v
			end
		end
	end
	
	function this.member:getConsoleModels()
		return Util.shallowCopyTable(self.consoleModels)
	end
	
	function this.member:setLightingColor(color)
		for _,v in next, self.lights do
			v.Color = color
		end
	end
	
	function this.member:setLightingEnabled(enabled)
		for _,v in next, self.lights do
			v.Enabled = enabled
		end
		self.ligtsEnabled = enabled
	end
	
	function this.member:setMode(sectionMode)
		if sectionMode == LEnums.SectionMode:GetItem"Unpowered" then
			self:setLightingEnabled(false)
			for _,v in next, self.doors do
				v:setMode(LEnums.DeviceMode:GetItem"Unpowered")
			end
		elseif sectionMode == LEnums.SectionMode:GetItem"Normal" then
			self:setLightingEnabled(true)
			for _,v in next, self.doors do
				v:setMode(LEnums.DeviceMode:GetItem"Normal")
			end
		elseif sectionMode == LEnums.SectionMode:GetItem"Lockdown" then
			self:setLightingEnabled(true)
			for _,v in next, self.doors do
				v:setMode(LEnums.DeviceMode:GetItem"GeneralLock")
			end
		else
			error("Bad section mode")
		end
		
		self.mode = sectionMode
	end
	
	function this.member:getMode()
		return self.mode
	end
	
	-- public properties
	this.get.name = true
	this.get.lightsEnabled = true
	
	-- public methods
	this.get.getDoors = true
	this.get.getDoor = true
	this.get.getConsoleModels = true
	this.get.setLightingColor = true
	this.get.setLightingEnabled = true
	this.get.setMode = true
	this.get.getMode = true
end)

return false