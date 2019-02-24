-- Zytharian (roblox: Legend26)

-- Services
local projectRoot = game:GetService("ServerScriptService")
local RS = game:GetService("ReplicatedStorage")

-- Includes
local cs = require(projectRoot.Modules.ClassSystem)
local Access = require(projectRoot.Modules.AccessManagement)
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

	]]

	function this:init ()
		self.name = "General"
		self.inRedAlert = false
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
					self:setRedAlert(false)
				else -- lockdown
					self.network:setMode(LEnums.SectionMode:GetItem"Lockdown")
					alarmFlag.Value = true
					self:setRedAlert(true)
				end
				self.networkUpdate:Fire({tab = dat.tab; index = 3; newState = dat.newState}) -- update alarm
			elseif dat.index == 2 then -- Alert
				self:setRedAlert(not dat.newState)
			elseif dat.index == 3 then
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
				self:setRedAlert(false)
				return true
			elseif dat.index == 2 and self.network:getTrain() then -- Train enable/disable
				local enabled = self.network:getTrain():isEnabled()
				if (enabled and dat.newState) or (not enabled and not dat.newState) then
					return true -- already in that state
				end
				self.network:getTrain():setEnabled(not enabled)
			elseif (not self.network:getTrain() and dat.index == 3) or (self.network:getTrain() and dat.index == 4) then --
				if not Access.IsPrivilegedUser(player) then
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

		if Access.IsPrivilegedUser(player) then
			table.insert(core, {CEnums.ScreenType.Section, "Privileged"})
			table.insert(core, {CEnums.ScreenType.OnlineOffline, "Lockout", self.network.lockoutEnabled, "Enabled", "Disabled"})
		end

		toReturn["Core"] = core


		return toReturn
	end

	function this.member:setRedAlert(enabled)
		if self.inRedAlert == enabled then return end
		self.inRedAlert = enabled

		local RED = Color3.new(1, 100/255, 100/255)

		local sections = self.network:getSections()
		for _,v in next, sections do
			v:setLightingColor(enabled and RED or nil)
		end
	end

	this.get.name = true
	this.get.handleCommand = true
	this.get.getBatchInfo = true
	this.get.networkUpdate = true
end)

return false