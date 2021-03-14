-- Zytharian (roblox: Legend26)

-- Services
local projectRoot = game:GetService("ServerScriptService")
local RS          = game:GetService("ReplicatedStorage")
local debris      = game:GetService("Debris")

-- Include
local Access = require(projectRoot.Modules.AccessManagement)

-- Configuration
local tools = { RS.StunnerModels["AD Stunner"], RS["Gate Remote"] }
local giverPart = workspace["1_HQ_Network"].StunnerGiverPart
local maxClickDistance = 8
local toolInWorkspaceLifetime = 60

--[[
	Dependencies: AccessManagement; Modules.Utilities; class EventPropagator
]]

--------
-- Header end
--------

-- Includes
local Util = require(projectRoot.Modules.Utilities)
local Classes = require(projectRoot.Modules.ClassSystem)

game.Players.PlayerAdded:connect(function (player)
	player.CharacterAdded:connect(function (character)
		if Access.IsPrivilegedUser(player) then
			for _,tool in pairs(tools) do
				local copy = tool:Clone()
				copy.Parent = player:FindFirstChild"Backpack"
			end
		end
	end)
end)

-- Click event
repeat wait() until Classes.ClassExists"EventPropagator"

local event = Classes.new 'EventPropagator'("ClickDetector", "MouseClick")
local click = Instance.new("ClickDetector", giverPart)

event.eventFired:Connect(function (player, instance)
	if not Util.playerAlive(player) or not player:FindFirstChild"Backpack" then return end

	for _,tool in pairs(tools) do
		if not player.Character:FindFirstChild(tool.Name) and not player.Backpack:FindFirstChild(tool.Name) then
			local copy = tool:Clone()
			copy.Parent = player.Backpack
		end
	end
end)
click.MaxActivationDistance = maxClickDistance
event:addObject(click)

-- Clean up tools that have been lying around for a while
local workspaceTools = {} -- [Rbx::Tool] = timeAddedToWorkspace

workspace.ChildAdded:connect(function (obj)
	if not obj:IsA"Tool" or obj.Name ~= tool.Name then return end
	workspaceTools[obj] = tick()
end)

workspace.ChildRemoved:connect(function (obj)
	if not obj:IsA"Tool" or obj.Name ~= tool.Name then return end
	workspaceTools[obj] = nil
end)

while true do
	local t = tick()
	for obj,addTime in next, workspaceTools do
		if addTime + toolInWorkspaceLifetime < t then
			workspaceTools[obj] = nil
			obj:Destroy()
		end
	end
	wait(5)
end