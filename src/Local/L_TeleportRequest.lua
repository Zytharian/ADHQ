-- Zytharian (roblox: Legend26)

-- Services
local Replicated = game:GetService("ReplicatedStorage")

-- Internal vars
local netModel = workspace:WaitForChild("1_HQ_Network")
local event = Replicated:WaitForChild("CR_TeleportRequest")
local player = game.Players.LocalPlayer

local isTeleporting = false

event.OnClientEvent:connect(function (args)
	if isTeleporting then
		return
	end
	isTeleporting = true
	
	local walkSpeed = 16
	if player.Character and player.Character:FindFirstChild"Humanoid" then
		walkSpeed = player.Character.Humanoid.WalkSpeed
		player.Character.Humanoid.WalkSpeed = 0
	end
	
	local gui = Instance.new("ScreenGui", player.PlayerGui)
	local frame = Instance.new("Frame", gui)
	frame.BackgroundTransparency = 1
	frame.BackgroundColor3 = Color3.new(1,1,1)
	frame.Position = UDim2.new(0,-50,0,-50)
	frame.Size = UDim2.new(1,100,1,100)

	for i=0, 90, 4.5 do
		gui.Frame.BackgroundTransparency = math.cos(math.rad(i))
		wait()
	end

	if args[1] and player.Character and player.Character:FindFirstChild"Torso" then
		player.Character.Torso.CFrame = args[1]
	end

	for i=90, 0, -4.5 do
		gui.Frame.BackgroundTransparency = math.cos(math.rad(i))
		wait()
	end

	gui:Destroy()
	
	if player.Character and player.Character:FindFirstChild"Humanoid" then
		player.Character.Humanoid.WalkSpeed = walkSpeed
	end
	
	isTeleporting = false
end)