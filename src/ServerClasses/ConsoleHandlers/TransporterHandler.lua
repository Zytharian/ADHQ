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

cs.class 'TransporterHandler' : extends "ConsoleHandler"  (function (this) 

	--[[
		Internal properties:
			Network network
	]]

	function this:init (network)
		self.name = "Transporters"
	end
	
	function this.member:handleCommand(section, conType, dat)
		if conType == LEnums.ConsoleType:GetItem"Local" then
			return false
		end
		
		if dat.tab == "Transporters" then
			local trans = self.network:getTransporters()[dat.index / 2]
			if not trans then
				return false
			end
			trans:setMode(dat.newState and LEnums.DeviceMode:GetItem"Normal" or LEnums.DeviceMode:GetItem"LocalLock")
		elseif dat.tab == "Rings" then
			local rings = self.network:getRings()[dat.index / 2]
			if not rings then
				return false
			end
			rings.isEnabled = dat.newState
		else
			return false
		end

		self.networkUpdate:Fire({tab = dat.tab; index = dat.index; newState = dat.newState}) 		
		return true
	end
	
	function this.member:getBatchInfo(section, conType)
		if conType == LEnums.ConsoleType:GetItem"Local" then
			return nil
		end
		
		local transporters = {}
		
		for i,v in next, self.network:getTransporters() do
			local currentState = v:getMode() ~= LEnums.DeviceMode:GetItem"LocalLock"
		
			table.insert(transporters, {CEnums.ScreenType.Section, v.name})
			table.insert(transporters, {CEnums.ScreenType.OnlineOffline, "Status", currentState, "Unlocked", "Locked"})
		end
		
		local rings = {}
		for i,v in next, self.network:getRings() do
			table.insert(rings, {CEnums.ScreenType.Section, v.name})
			table.insert(rings, {CEnums.ScreenType.OnlineOffline, "Status", v.isEnabled, "Enabled", "Disabled"})
		end
		
		return {Transporters = transporters, Rings = rings}
	end
	
	this.get.name = true
	this.get.handleCommand = true
	this.get.getBatchInfo = true
	this.get.networkUpdate = true
end)

return false