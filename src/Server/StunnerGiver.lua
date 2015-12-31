-- Zytharian (roblox: Legend26)

-- Services
local projectRoot = game:GetService("ServerScriptService")
local RS          = game:GetService("ReplicatedStorage")
local debris      = game:GetService("Debris")

-- Configuration
local tool = RS.StunnerModels["AD Stunner"]
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
local access = _G.Access

while not access do
	wait()
	access = _G.Access
end
repeat wait() until Classes.ClassExists"EventPropagator"

local event = Classes.new 'EventPropagator'("ClickDetector", "MouseClick")
local click = Instance.new("ClickDetector", giverPart)

event.eventFired:Connect(function (player, instance)
	if not Util.playerAlive(player) or not player:FindFirstChild"Backpack" then return end
	if player.Character:FindFirstChild(tool.Name) or player.Backpack:FindFirstChild(tool.Name) then return end
	
	local copy = tool:Clone()
	copy.Parent = player.Backpack
end)
click.MaxActivationDistance = maxClickDistance
event:addObject(click)

game.Players.PlayerAdded:connect(function (player)
	player.CharacterAdded:connect(function (character)
		if _G.Access.IsPrivilegedUser(player) then
			local copy = tool:Clone()
			copy.Parent = player:FindFirstChild"Backpack"
		end
	end)
end)

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