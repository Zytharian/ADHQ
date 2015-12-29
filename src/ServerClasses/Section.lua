-- Zytharian (roblox: Legend26)

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
		readonly bool lightsEnabled
		readonly WindowGuard windowGuard

	Methods:
		table getDoors()
		Door getDoor(string name)
		void setLightingColor(Color3 color)
		void setLightingEnabled(bool enabled)
		void setMode(LEnums::SectionMode mode)
		LEnums::SectionMode getMode()

	Events:
		modeChanged(LEnums::SectionMode)

]]

Classes.class 'Section' (function (this)

	--[[
		Internal properties:
			table doors
			table lights
			table consoles
			LEnums::SectionMode
			
			for lights -- {lights = {Rbx::Light = Rbx::Color3}; neons = {Rbx::BasePart = Rbx::BrickColor}
	]]

	function this:init (name, doors, lights, consoles, windowGuard)
		self.name = name
		self.doors = doors
		self.lights = lights
		self.windowGuard = windowGuard
		self.lightsEnabled = true

		self.consoles = consoles

		self.mode = LEnums.SectionMode:GetItem"Normal"
		self.modeChanged = Classes.new 'Signal' ()
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
		return Util.shallowCopyTable(self.consoles)
	end

	function this.member:setLightingColor(color)
		for light,original in next, self.lights.lights do
			light.Color = color and color or original
		end
	end

	function this.member:setLightingEnabled(enabled)
		for light,_ in next, self.lights.lights do
			light.Enabled = enabled
		end
		for part,originalColor in next, self.lights.neons do
			part.Material = enabled and Enum.Material.Neon or Enum.Material.SmoothPlastic
			part.BrickColor = enabled and originalColor or BrickColor.Black()
		end
		self.lightsEnabled = enabled
	end

	function this.member:setMode(sectionMode)
		if sectionMode == LEnums.SectionMode:GetItem"Unpowered" then
			self:setLightingEnabled(false)
			for _,v in next, self.doors do
				v:setMode(LEnums.DeviceMode:GetItem"Unpowered")
			end
			self:setConsoleLights(false)
		elseif sectionMode == LEnums.SectionMode:GetItem"Normal" then
			self:setLightingEnabled(true)
			for _,v in next, self.doors do
				v:setMode(LEnums.DeviceMode:GetItem"Normal")
			end
			self:setConsoleLights(true)
		elseif sectionMode == LEnums.SectionMode:GetItem"Lockdown" then
			self:setLightingEnabled(true)
			for _,v in next, self.doors do
				v:setMode(LEnums.DeviceMode:GetItem"GeneralLock")
			end
			self:setConsoleLights(true)
		else
			error("Bad section mode")
		end

		self.mode = sectionMode
		self.modeChanged:Fire(self.mode)
	end

	function this.member:setConsoleLights(enabled)
		for i,v in next, self.consoles do
			local unit = v:FindFirstChild"Unit"

			local controls = unit and unit:FindFirstChild"Controls" or nil
			local buttons = controls and controls:FindFirstChild"Buttons" or nil

			local neon = unit and unit:FindFirstChild"Neon" or nil
			
			if buttons then
				for _,part in next, buttons:GetChildren() do
					part.Material = enabled and Enum.Material.Neon or Enum.Material.SmoothPlastic
				end
			end
			if neon then
				for _,part in next, neon:GetChildren() do
					part.Material = enabled and Enum.Material.Neon or Enum.Material.SmoothPlastic
				end
			end
		end
	end

	function this.member:getMode()
		return self.mode
	end

	-- public properties
	this.get.name = true
	this.get.lightsEnabled = true
	this.get.windowGuard = true

	-- public methods
	this.get.getDoors = true
	this.get.getDoor = true
	this.get.getConsoleModels = true
	this.get.setLightingColor = true
	this.get.setLightingEnabled = true
	this.get.setMode = true
	this.get.getMode = true
	this.get.modeChanged = true
end)

return false