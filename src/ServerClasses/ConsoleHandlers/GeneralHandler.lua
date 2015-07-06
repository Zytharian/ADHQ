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
		bool handleCommand(Section section, Enum::ConsoleType conType, table dat, Rbx::Player player)
			True on command success, false otherwise.
		
		table getBatchInfo(Section section, Enum::ConsoleType conType, Rbx::Player player)
	Events:
		networkUpdate(...)
		
	Callbacks:
		void
		
]]

--------
-- Header end
--------

local alarmFlag = Instance.new("BoolValue", RS)
alarmFlag.Name = "FLAG_AlarmPlaying"

cs.class 'GeneralHandler' : extends "ConsoleHandler"  (function (this) 

	--[[
		Internal properties:
			bool inRedAlert
			bool redAlertImplRunning
			
	]]

	function this:init ()
		self.name = "General"
		self.inRedAlert = false
		self.redAlertImplRunning = false
	end
	
	function this.member:handleCommand(section, conType, dat, player)
		if conType == LEnums.ConsoleType:GetItem"Local" then
			return false
		end
		
		if dat.tab == "Base Alerts" then
			if dat.index == 1 then -- State
				if dat.newState then -- normal
					self.network:setMode(LEnums.SectionMode:GetItem"Normal")
					alarmFlag.Value = false
					self.inRedAlert = false
				else -- lockdown
					self.network:setMode(LEnums.SectionMode:GetItem"Lockdown")
					alarmFlag.Value = true
					if not self.redAlertImplRunning then
						self.inRedAlert = true
						self:executeRedAlert()
					end
				end
				self.networkUpdate:Fire({tab = dat.tab; index = 3; newState = dat.newState}) -- update alarm
			elseif dat.index == 2 then -- Alert
				if self.network:getMode() == LEnums.SectionMode:GetItem"Unpowered" then
					return false -- no power to do anything
				end
				
				if not dat.newState then -- Red alert
					if self.redAlertImplRunning then
						return true -- already in red alert
					end
					self.inRedAlert = true
					self:executeRedAlert()
				else -- Normal 
					self.inRedAlert = false
				end
			elseif dat.index == 3 then
				if self.network:getMode() == LEnums.SectionMode:GetItem"Unpowered" then
					return false -- no power to do anything
				end
				
				if dat.newState then
					alarmFlag.Value = false
				else
					alarmFlag.Value = true
				end
			else
				print("Bad id (general handler - base alerts): " .. tostring(dat.index))
				return false
			end
			self.networkUpdate:Fire({tab = dat.tab; index = dat.index; newState = dat.newState})
			return true
		end
		
		if conType == LEnums.ConsoleType:GetItem"Control" then
			return false
		end
		
		if dat.tab == "Core" then
			if dat.index == 1 then -- Reset
				self.network:setMode(LEnums.SectionMode:GetItem"Normal")
				if self.network:getTrain() ~= nil then
					self.network:getTrain():setEnabled(true)
				end
				alarmFlag.Value = false
				self.inRedAlert = false
				return true
			elseif dat.index == 2 and self.network:getTrain() then -- Train enable/disable
				local enabled = self.network:getTrain():isEnabled()
				if (enabled and dat.newState) or (not enabled and not dat.newState) then
					return true -- already in that state
				end
				self.network:getTrain():setEnabled(not enabled)
			elseif (not self.network:getTrain() and dat.index == 3) or (self.network:getTrain() and dat.index == 4) then -- 
				if not _G.Access.IsPrivilegedUser(player) then
					return false
				end
				
				self.network.lockoutEnabled = dat.newState
				
				return true
			else
				return false
			end
			self.networkUpdate:Fire({tab = dat.tab; index = dat.index; newState = dat.newState})
			return true
		end
		
	end
	
	function this.member:getBatchInfo(section, conType, player)
		local toReturn = {}
		
		-- Base monitor
		local baseMon = {}
		
		for _,v in next, self.network:getSections() do
			table.insert(baseMon, {CEnums.ScreenType.Section, v.name })
			table.insert(baseMon, {CEnums.ScreenType.Section, "  Status: " .. v:getMode().Name })
		end
		
		toReturn["Base Monitor"] = baseMon
		
		-- Gate monitor
		-- TODO
		--local gateMon = {}
		
		--toReturn["Gate Monitor"] = gateMon
		
		if conType == LEnums.ConsoleType:GetItem"Local" then
			return toReturn
		end
		
		-- Base alerts (Control+)
		local baseAlert = {}
		
			-- Base State
		table.insert(baseAlert, {CEnums.ScreenType.OnlineOffline, "Base State", self.network:getMode() ~= LEnums.SectionMode:GetItem"Lockdown" , "Normal", "Global Lockdown" })
			
			-- Base Alert
		table.insert(baseAlert, {CEnums.ScreenType.OnlineOffline, "Alert State", not self.inRedAlert , "Green", "Red" })
		
			-- Alarm
		table.insert(baseAlert, {CEnums.ScreenType.OnlineOffline, "Alarm", not alarmFlag.Value, "Off", "Sounding" })
		
		toReturn["Base Alerts"] = baseAlert
		
		if conType == LEnums.ConsoleType:GetItem"Control" then
			return toReturn
		end
		
		-- Core (Core+)
		local core = {}
		
			-- Reset
		table.insert(core, {CEnums.ScreenType.OnlineOffline, "Reset" , true, "Do Reset","Reset Complete"})
		
			-- Train disable
		if self.network:getTrain() then
			table.insert(core, {CEnums.ScreenType.OnlineOffline, "Train", self.network:getTrain():isEnabled(), "Enabled", "Disabled"})
		end
		
		if _G.Access.IsPrivilegedUser(player) then
			table.insert(core, {CEnums.ScreenType.Section, "Privileged"})
			table.insert(core, {CEnums.ScreenType.OnlineOffline, "Lockout", self.network.lockoutEnabled, "Enabled", "Disabled"})
		end
		
		toReturn["Core"] = core
		
		
		return toReturn		
	end
	
	function this.member:executeRedAlert()
		if self.redAlertImplRunning then
			error("Red alert already running")
		end
		self.redAlertImplRunning = true
		
		coroutine.wrap(function ()
			local RED = Color3.new(1, 0, 0)
			local NORMAL = Color3.new(1, 248/255, 220/255)
		
			local sections = self.network:getSections()
			for _,v in next, sections do
				v:setLightingColor(RED)
			end
		
			while self.inRedAlert do
				for _,v in next, sections do
					if v:getMode() ~= LEnums.SectionMode:GetItem"Unpowered" then
						v:setLightingEnabled(false)
					end
				end
				wait(2)
				if not self.inRedAlert then
					break
				end
				for _,v in next, sections do
					if v:getMode() ~= LEnums.SectionMode:GetItem"Unpowered" then
						v:setLightingEnabled(true)
					end
				end
				wait(2)
			end
			
			for _,v in next, sections do
				if v:getMode() ~= LEnums.SectionMode:GetItem"Unpowered" then
					v:setLightingEnabled(true)
				end
				
				v:setLightingColor(NORMAL)
			end
			
			self.redAlertImplRunning = false
		end)()
		
	end
	
	this.get.name = true
	this.get.handleCommand = true
	this.get.getBatchInfo = true
	this.get.networkUpdate = true
end)

return false