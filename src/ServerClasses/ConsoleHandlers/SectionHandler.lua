-- Zytharian (roblox: Legend26)

-- Services
local projectRoot = game:GetService("ServerScriptService")
local RS = game:GetService("ReplicatedStorage")

-- Includes
local cs = require(projectRoot.Modules.ClassSystem)
local CEnums = require(RS.CommandEnums)
local LEnums = require(projectRoot.Modules.Enums)

-- Configuration
local DEBUG = false

--[[
	init(Network network)

	Properties:
		string name
		
	Methods:
		bool handleCommand(Section section, Enum::ConsoleType conType, table dat)
			True on command success, false otherwise.
		
		table getBatchInfo(Section section, Enum::ConsoleType conType)
	Events:
		networkUpdate(...)
		
	Callbacks:
		void
		
]]

--------
-- Header end
--------

cs.class 'SectionHandler' : extends "ConsoleHandler" (function (this) 

	--[[
		Internal properties:
			Network network
	]]

	function this:init (network)
		self.name = "Sections"
	end
	
	function this.member:handleCommand(section, conType, dat)	
		if conType ~= LEnums.ConsoleType:GetItem"Local" then
			for _,v in next, self.network:getSections() do
				if v.name == dat.tab then
					section = v
					break
				end
				
			end
		end
		
		if dat.index == 1 then -- State
			if section:getMode() == LEnums.SectionMode:GetItem"Unpowered" then
				return false -- No power to modify anything
			end
			
			if dat.newState then
				section:setMode(LEnums.SectionMode:GetItem"Normal")
			else
				section:setMode(LEnums.SectionMode:GetItem"Lockdown")
			end
		elseif dat.index == 2 then -- Lights
			if section:getMode() == LEnums.SectionMode:GetItem"Unpowered" then
				return false
			end
			section:setLightingEnabled(dat.newState)
		elseif dat.index == 3 then -- Power		
			if section:getMode() == LEnums.SectionMode:GetItem"Lockdown" then
				self.networkUpdate:Fire({tab = dat.tab; index = 1; newState = true}) -- Update state
			end
			
			if dat.newState then
				section:setMode(LEnums.SectionMode:GetItem"Normal")
			else
				section:setMode(LEnums.SectionMode:GetItem"Unpowered")
			end
			self.networkUpdate:Fire({tab = dat.tab; index = 2; newState = dat.newState}) -- Update light
		elseif dat.index == 4 and section.windowGuard then
			if section:getMode() == LEnums.SectionMode:GetItem"Unpowered" then
				return false -- No power to modify anything
			end
			
			section.windowGuard:setEnabled(dat.newState)
		end
		if dat.index <= 3 or (dat.index == 4 and section.windowGuard) then
			self.networkUpdate:Fire({tab = dat.tab; index = dat.index; newState = dat.newState})
			return true
		elseif section:getMode() == LEnums.SectionMode:GetItem"Unpowered" then
			return false -- No power to modify anything.
		end
		
		local trueIndex = dat.index - (section.windowGuard and 4 or 3)
		local doorId = math.ceil(trueIndex / 3)
		local door = section:getDoors()[doorId]
		local option = trueIndex - (doorId - 1)* 3
		
		if option == 2 then
			if dat.newState then
				door:changeStateAsync(true)
			else
				door:changeStateAsync(false)
			end
		elseif option == 3 then
			if dat.newState then
				door:setMode(LEnums.DeviceMode:GetItem"Normal")
			else
				door:setMode(LEnums.DeviceMode:GetItem"LocalLock")
				self.networkUpdate:Fire({tab =  dat.tab; index = dat.index - 1; newState = false})
			end
		else
			print("Bad option " .. tostring(option))
			return false
		end
		
		self.networkUpdate:Fire({tab = dat.tab; index = dat.index; newState = dat.newState})
		return true
	end
	
	function this.member:getBatchInfo(section, conType)
		local toReturn = {}
		
		local sectionList
		if conType == LEnums.ConsoleType:GetItem"Local" then
			sectionList = {section}
		else
			sectionList = self.network:getSections()
		end
		
		for _,s in next,  sectionList do
			local t = {}
			
			-- State
			table.insert(t, {CEnums.ScreenType.OnlineOffline, "State", s:getMode() ~= LEnums.SectionMode:GetItem"Lockdown", "Normal", "Lockdown" })
			
			-- Lights
			table.insert(t, {CEnums.ScreenType.OnlineOffline, "Lights", s.lightsEnabled})
			
			-- Power
			table.insert(t, {CEnums.ScreenType.OnlineOffline, "Power", s:getMode() ~= LEnums.SectionMode:GetItem"Unpowered"})
			
			-- Window Guard
			if s.windowGuard then
				table.insert(t, {CEnums.ScreenType.OnlineOffline, "Window Tint", s.windowGuard.enabled })
			end
			
			for _,d in next, s:getDoors() do
				table.insert(t, {CEnums.ScreenType.Section, "Door: " .. d.name })
				table.insert(t, {CEnums.ScreenType.OnlineOffline, "Open State", d.isOpen, "Open", "Closed" })
				table.insert(t, {CEnums.ScreenType.OnlineOffline, "Lock", d:getMode() ~= LEnums.DeviceMode:GetItem"LocalLock" , "Unlocked", "Locked" })
			end
		
			toReturn[s.name] = t
		end
		
		return toReturn 
	end
	
end)

return false