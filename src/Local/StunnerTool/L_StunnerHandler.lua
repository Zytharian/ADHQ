-- Zytharian (roblox: Legend26)

-- Services
local RS = game:GetService("ReplicatedStorage")
local inputService = game:GetService("UserInputService")

-- Remotes
local remoteRegister   = RS:WaitForChild("STUN_Register")
local remoteFire       = RS:WaitForChild("STUN_Fire")
local remoteModeChange = RS:WaitForChild("STUN_ModeChange")

-- Configuration
local toolName   = "AD Stunner"
local normalIcon = "rbxasset://textures\\GunCursor.png"
local reloadIcon = "rbxasset://textures\\GunWaitCursor.png"
local DEBUG      = false

-- Internal variables
local tool    = script.Parent
local player  = game.Players.LocalPlayer
local mouse   = nil
local ui      = tool:WaitForChild("StunnerUI")
local uiClone = nil

local equipped = false
local reloadOffset, reloadTime = 0, 0
local toolLimited = false

PrintMsg = (function (msg, isError)
	if DEBUG then
		if isError then
			error("[Stunner]: " .. msg)
		else
			print("[Stunner]: " .. msg)
		end
	end
end)

ToolEnabled = (function ()
	return reloadOffset < tick()
end)

DoReloadUI = (function ()
	local t = tick()
	if reloadOffset < t then
		return
	end
	
	uiClone.Reload.Progress.Size = UDim2.new(0, 0, 1, 0)
	uiClone.Reload.Visible = true
	repeat
		t = tick()
		local diff = reloadOffset - t
		local frac = 1 - (diff / reloadTime)
		uiClone.Reload.Progress.Size = UDim2.new(frac, 0, 1, 0)
		wait()
	until reloadOffset < t or not equipped
	if equipped then
		uiClone.Reload.Visible = false
		mouse.Icon = normalIcon
	end
end)

Equipped = (function (givenMouse)
	mouse = givenMouse
	mouse.Icon = ToolEnabled() and normalIcon or reloadIcon
	equipped = true
	
	uiClone = ui:Clone()
	if toolLimited then -- disable mode change button when limited
		uiClone.Mode.ModeButton.TextTransparency = 0.4
		uiClone.Mode.ModeButton.TextColor3 = Color3.new(175/255, 175/255, 175/255)
		uiClone.Mode.ModeButton.Selectable = false
	else
		uiClone.Mode.ModeButton.MouseButton1Down:connect(function ()
			remoteModeChange:InvokeServer(tool, true, false)
		end)
	end
	uiClone.Mode.FlashlightButton.MouseButton1Down:connect(function ()
		remoteModeChange:InvokeServer(tool, false, true)
	end)
	uiClone.Mode.Visible = true
	uiClone.Parent = player.PlayerGui
	
	DoReloadUI()
end)

Unequipped = (function ()
	mouse = nil
	equipped = false
	
	uiClone:Destroy()
	uiClone = nil
end)

Activated = (function ()
	local hitPos = mouse.Hit.p
	
	if ToolEnabled() then
		local newOffset = remoteFire:InvokeServer(tool, hitPos)
		if not newOffset then
			PrintMsg("Bad offset, tool not fired")
		else
			local t = tick()
			reloadOffset = newOffset + t
			reloadTime = newOffset

			DoReloadUI()
		end
	end
end)

InputBegan = (function (inputObject, gameProcessedEvent)
	if not equipped or gameProcessedEvent then
		return
	end
	
	if inputObject.KeyCode == Enum.KeyCode.E and not toolLimited then -- switch mode
		remoteModeChange:InvokeServer(tool, true, false)
	elseif inputObject.KeyCode == Enum.KeyCode.F then -- toggle flashlight
		remoteModeChange:InvokeServer(tool, false, true)
	end
end)

HookEvents = (function ()
	tool.Equipped:connect(Equipped)
	tool.Unequipped:connect(Unequipped)
	tool.Activated:connect(Activated)
	inputService.InputBegan:connect(InputBegan)
end)

RegisterTool = (function ()
	local success, isLimited = remoteRegister:InvokeServer(tool)
	if not success then
		PrintMsg("Failed to register tool", true)
	end
	
	toolLimited = isLimited
end)

-- Main
RegisterTool()
HookEvents()
PrintMsg("Registered")