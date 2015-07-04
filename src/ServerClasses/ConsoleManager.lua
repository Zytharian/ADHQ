-- Services
local projectRoot = game:GetService("ServerScriptService")
local RS = game:GetService("ReplicatedStorage")

-- Includes
local Classes = require(projectRoot.Modules.ClassSystem)
local Util = require(projectRoot.Modules.Utilities)
local LEnums = require(projectRoot.Modules.Enums)
local CEnums = require(RS.CommandEnums)

-- Configuration
local DEBUG = true
local CORE_ACCESS_SECTIONS = {Core = true}
local CONTROL_ACCESS_SECTIONS = {ControlRoom = true, ["Admin Building"] = true}
local INTERACT_DISTANCE_LIMIT = 7

--[[
	init(Network network)

	Properties:
		void

	Methods:
		void

	Events:
		void
]]

local numConsoles = 0
local numNetworks = 0

local lastGetBatch
local lastRunCommand

do
	local remoteFunctions = {"GetBatchInformation", "RunCommand"}
	local remoteEvents = {"NetworkUpdate"}

	for _,v in next, remoteFunctions do
		local remote = Instance.new("RemoteFunction", RS)
		remote.Name = "CON_F_" .. v
	end

	for _,v in next, remoteEvents do
		local remote = Instance.new("RemoteEvent", RS)
		remote.Name = "CON_E_" .. v
	end
end

Classes.class 'ConsoleManager' (function (this)

	--[[
		Internal properties:
			Network network
			table consoles
				{ id = {consoleType = Enum::ConsoleType, model = Rbx::Model, section = Section} }
			number networkId
	]]

	function this:init (network)
		self.network = network

		numNetworks = numNetworks + 1
		self.networkId = numNetworks

		self.consoles = {}

		self.limiter = Classes.new "RateLimiter" ()
		self.limiter:setSecondsBetweenCommands(0.7)

		self.consoleHandlers = {
			Classes.new "GeneralHandler" (network);
			Classes.new "SectionHandler" (network);
			Classes.new "TransporterHandler" (network);
		}

		for i=1, #self.consoleHandlers do
			local handler = self.consoleHandlers[i]
			self.consoleHandlers[handler.name] = handler
			self.consoleHandlers[i] = nil
		end

		self:doConsoleSetup()

		self:remoteHooks()
		self:updates()
	end

	function this.member:remoteHooks()

		local fallbackBatch = lastGetBatch
		lastGetBatch =  (function (player, id)
			local console = self.consoles[id]
			if not console then
				Util.Debug.print("Bad id (" .. tostring(id) .. ") from player " .. player.Name, DEBUG)

				if fallbackBatch then
					Util.Debug.print("Passing on...", DEBUG)
					return fallbackBatch(player, id)
				end

				return nil
			end

			if not Util.playerAlive(player) or not Util.playerNearModel(player, console.model, INTERACT_DISTANCE_LIMIT) then
				return
			end
			
			if console.section:getMode() == LEnums.SectionMode:GetItem"Unpowered" then
				return nil, nil, nil, "NO POWER"
			elseif self.network.lockoutEnabled and not _G.Access.IsPrivilegedUser(player) then
				return nil, nil, nil, "CONSOLE LOCKOUT"
			end 

			local dat = {}
			local conType

			for i,v in next, self.consoleHandlers do
				dat[i] = v:getBatchInfo(console.section, console.consoleType, player)
			end

			if console.consoleType == LEnums.ConsoleType:GetItem"Core" then
				conType = CEnums.ConsoleType.Core
			elseif console.consoleType == LEnums.ConsoleType:GetItem"Control" then
				conType = CEnums.ConsoleType.Control
			else -- Local type
				conType = CEnums.ConsoleType.Local
			end

			return dat, conType, self.networkId
		end)
		RS.CON_F_GetBatchInformation.OnServerInvoke = lastGetBatch

		local fallbackRun = lastRunCommand
		lastRunCommand = (function (player, id, handler, dat)
			local console = self.consoles[id]

			if not console then
				Util.Debug.print("Bad console id (" .. tostring(id) .. ") from player " .. player.Name, DEBUG)

				if fallbackRun then
					Util.Debug.print("Passing on...", DEBUG)
					return fallbackRun(player, id, handler, dat)
				end

				return
			end

			if not Util.playerAlive(player) or not Util.playerNearModel(player, console.model, INTERACT_DISTANCE_LIMIT) then
				return
			end
			
			if console.section:getMode() == LEnums.SectionMode:GetItem"Unpowered" then
				return
			elseif self.network.lockoutEnabled and not _G.Access.IsPrivilegedUser(player) then
				return
			end

			if not self.limiter:withinLimit(player) then
				return
			end
			self.limiter:registerPlayerCommand(player)

			if not self.consoleHandlers[handler] then
				Util.Debug.print("Bad handler id (" .. tostring(handler) ..") from player " .. player.Name, DEBUG)
				return
			elseif type(dat) ~= "table" or not dat.index or not dat.tab or type(dat.newState) ~= "boolean" then
				Util.Debug.print("Bad dat (" .. tostring(dat) .. ") from player " .. player.Name, DEBUG)
				return
			end

			local success = self.consoleHandlers[handler]:handleCommand(
				console.section,
				console.consoleType,
				dat,
				player
			)

			return success
		end)
		RS.CON_F_RunCommand.OnServerInvoke = lastRunCommand

	end

	function this.member:doConsoleSetup()
		for _,s in next, self.network:getSections() do
			local access
			if CORE_ACCESS_SECTIONS[s.name] then
				access = LEnums.ConsoleType:GetItem"Core"
			elseif CONTROL_ACCESS_SECTIONS[s.name] then
				access = LEnums.ConsoleType:GetItem"Control"
			else
				access = LEnums.ConsoleType:GetItem"Local"
			end

			for _,m in next, s:getConsoleModels() do
				numConsoles = numConsoles + 1
				self.consoles[numConsoles] = {
					consoleType = access;
					model = m;
					section = s;
				}

				local val = Instance.new("IntValue", m)
				val.Name = "CON_Console"
				val.Value = numConsoles
			end
		end
	end

	function this.member:updates()
		for i,v in next, self.consoleHandlers do
			v.networkUpdate:Connect(function (...)
				RS.CON_E_NetworkUpdate:FireAllClients(i, self.networkId, ...)
			end)
		end
	end

end)

return false