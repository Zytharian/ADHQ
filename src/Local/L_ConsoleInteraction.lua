-- Zytharian (roblox: Legend26)

-- Services
local Replicated = game:GetService("ReplicatedStorage")

-- Includes
local GuiLib = require(Replicated.Gui)

-- Configuration
local DEBUG = false
local INTERACT_DISTANCE_LIMIT = 6

--------
-- Header end
--------

local netModel = workspace:WaitForChild("1_HQ_Network")
local player = game.Players.LocalPlayer
local mouse = player:GetMouse()

local consoles = {}
local gui = GuiLib.createGui(player)
	-- { Rbx::Model console = id }

-- General utility functions
getAll = (function (Obj, SearchFor)
	local Tbl = {}
	for _,v in next, Obj:GetChildren() do
		if v:IsA(SearchFor)  then
			Tbl[#Tbl+1] = v
		else
			for _,x in next, getAll(v, SearchFor) do
				Tbl[#Tbl+1] = x
			end
		end
	end
	return Tbl
end)

isAlive = (function ()
	return player.Character and player.Character:FindFirstChild"Humanoid" 
		and player.Character.Humanoid.Health > 0 and player.Character:FindFirstChild"Torso" 
end)

-- Mouse setup
local currentConsole, currentConsoleId, currentConsolePart = nil, nil, nil

mouse.Move:connect(function ()
	local obj = mouse.Target
	if not obj or gui.interactingWithConsole() or not isAlive() then 
		gui.setMouseoverInteract(false)
		currentConsole = nil
		return
	end
	
	for i, v in next, consoles do
		if obj:IsDescendantOf(i) then
			-- Check distance
			if (player.Character.Torso.Position - obj.Position).magnitude > INTERACT_DISTANCE_LIMIT then
				break
			end
			
			gui.setMouseoverInteract(true, mouse.X + 10, mouse.Y + 10)
			currentConsole = i
			currentConsoleId = v
			currentConsolePart = obj
			return
		end
	end
	
	-- if none found
	gui.setMouseoverInteract(false)
	currentConsole = nil
end)

mouse.Button1Up:connect(function ()
	if not currentConsole or gui.interactingWithConsole() then 
		return 
	end
	gui.setMouseoverInteract(false)
	
	if DEBUG then
		print("Interacting with console (id:" .. currentConsoleId .. ") " .. currentConsole:GetFullName())
	end
	
	gui.beginConsoleInteraction(currentConsoleId)
	
	-- Keep checking distance
	while gui.interactingWithConsole() and isAlive() 
		and (player.Character.Torso.Position - currentConsolePart.Position).magnitude < INTERACT_DISTANCE_LIMIT do
		
		wait()
	end
	
	if gui.interactingWithConsole() then
		gui.endConsoleInteraction()
	end
end)

-- Console registering
registerNewConsole = (function (consoleId)
	if consoleId.Name:sub(1,4) ~= "CON_" then
		return
	end
	
	if DEBUG then
		print(script.Name .. " :: Added console (id: " .. consoleId.Value .. ") "  .. consoleId:GetFullName())
	end
	
	consoles[consoleId.Parent] = consoleId.Value
end)

netModel.DescendantAdded:connect(function (obj)
	if obj.ClassName == "IntValue" then
		registerNewConsole(obj)
	end
end)

for i,v in next, getAll(netModel, "IntValue") do
	registerNewConsole(v)
end