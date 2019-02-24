-- Zytharian (roblox: Legend26)

-- Services
local projectRoot = game:GetService("ServerScriptService")
local RS          = game:GetService("ReplicatedStorage")
local debris      = game:GetService("Debris")

-- Configuration
local toolName        = "AD Stunner"
local unlimitedReload = 1 -- seconds
local limitedReload   = 4 -- seconds
local shotDistance    = 600 -- studs
local shotSpeed       = 300 -- studs per second
local stunHandle      = RS.StunnerModels.Stunner_stun
local hitSound        = "http://www.roblox.com/asset/?id=157325701"
local fireSound       = "http://www.roblox.com/asset/?id=201858072"
local killHandle      = RS.StunnerModels.Stunner_kill
local stunDuration    = 10 -- seconds
local particleTextre  = "http://www.roblox.com/asset/?id=337883100"
local gravityConstant = -196.2/5 -- official gravity constant of roblox: 196.2

--[[
	Dependencies: Modules.AccessManagement; Modules.Utilities
]]

--------
-- Header end
--------

-- Includes
local Util = require(projectRoot.Modules.Utilities)
local Access = require(projectRoot.Modules.AccessManagement)

-- Remotes
local remoteRegister   = Instance.new("RemoteFunction", RS)
local remoteFire       = Instance.new("RemoteFunction", RS)
local remoteModeChange = Instance.new("RemoteFunction", RS)

remoteRegister.Name   = "STUN_Register"
remoteFire.Name       = "STUN_Fire"
remoteModeChange.Name = "STUN_ModeChange"

-- Registry
local toolRegistry = {}
-- [Rbx::Tool] = {player = Rbx::Player, limited = boolean, reloadOffset = number; killMode = boolean,
--					conn = Rbx::connection};

-- Functions
Raycast = (function (origin, direction, distance, ignoreList)
	local ray = Ray.new(origin, direction * distance)

	local part, hitPoint = workspace:FindPartOnRayWithIgnoreList(ray, ignoreList)
	return part, hitPoint
end)

RaycastIgnoreNonCollides = (function (origin, direction, distance, ignoreList)
	local part, hitPoint
	while true do
		part, hitPoint = Raycast(origin, direction, distance, ignoreList)
		if part and not part.CanCollide and not GetHumanoidAndCharacter(part) then
			table.insert(ignoreList, part)
		else
			break
		end
	end
	return part, hitPoint
end)

CreateBullet = (function (brickColor)
	local b = Instance.new("Part")
	local p = Instance.new("PointLight", b)
	local m = Instance.new("SpecialMesh", b)

	b.Anchored = true
	b.archivable = false
	b.CanCollide = false
	b.TopSurface = Enum.SurfaceType.Smooth
	b.BottomSurface = Enum.SurfaceType.Smooth
	b.formFactor = Enum.FormFactor.Custom

	b.Transparency = 0.4
	b.BrickColor = brickColor
	b.Material = Enum.Material.Neon
	b.Size = Vector3.new(0.2,0.2,2)

	m.MeshType = Enum.MeshType.Sphere

	p.Color = brickColor.Color
	p.Range = 10

	return b
end)

CreateSplashParticles = (function ()
	local p1 = Instance.new("ParticleEmitter")

	p1.Color = ColorSequence.new(Color3.new(115/255, 164/255, 1), Color3.new(100/255, 11/255, 1))
	p1.Texture = particleTextre
	p1.LightEmission = 1
	p1.Size = NumberSequence.new(1.2)
	p1.Transparency = NumberSequence.new(0.7)
	p1.ZOffset = 0.8

	p1.Acceleration = Vector3.new(0, -0.5, 0)
	p1.LockedToPart = true
	p1.EmissionDirection = Enum.NormalId.Top

	p1.Lifetime = NumberRange.new(1, 1.5)
	p1.Rate = 15
	p1.Rotation = NumberRange.new(20)
	p1.RotSpeed = NumberRange.new(30)
	p1.Speed = NumberRange.new(0.8)

	local p2 = p1:Clone()
	p2.Color = ColorSequence.new(Color3.new(131/255, 175/255, 1), Color3.new(0, 0, 127/255))
	p2.EmissionDirection = Enum.NormalId.Bottom
	p2.Lifetime = NumberRange.new(1,2)

	local light = Instance.new("PointLight")
	light.Color = Color3.new(0.2, 0.2, 1)
	light.Range = 10

	return p1, p2, light
end)

CreateFireParticles = (function ()
	local fire = Instance.new("Fire")
	fire.Size = 4
	fire.Heat = 0

	local light = Instance.new("PointLight")
	light.Color = Color3.new(1, 0.2, 0.2)
	light.Range = 10

	return fire, light
end)

Stun = (function (human, character)
	local torso = Util.playerCharacterMainPart(character)
	if not torso then return end

	local p1, p2, light = CreateSplashParticles()
	p1.Parent = torso
	p2.Parent = torso
	debris:AddItem(p1, 0.5)
	debris:AddItem(p2, 0.5)

	local bodyGyro = Instance.new("BodyGyro", torso)
	bodyGyro.maxTorque = Vector3.new(4e+004,0,0)
	bodyGyro.cframe = CFrame.fromAxisAngle(Vector3.new(0,0,1),math.pi/2)
	human.PlatformStand = true
	human.WalkSpeed = 0

	local changedConnection = human.Changed:connect(function (prop)
		if prop == "PlatformStand" and not human.PlatformStand then
			human.PlatformStand = true
		end
	end)
	local addedConnction = character.ChildAdded:connect(function (obj)
		if obj:IsA("Tool") and obj:FindFirstChild("Handle") then
			wait() -- o/w we get the stupid "Something unexpectedly set the parent of" error.
			obj.Parent = workspace
		end
	end)
	for _,v in next, character:GetChildren() do
		if v:IsA("Tool") and v:FindFirstChild("Handle") then
			v.Parent = workspace
			v.Handle.CFrame = v.Handle.CFrame + Vector3.new(2, 0, 0)
		end
	end
	wait(stunDuration)
	changedConnection:disconnect()
	addedConnction:disconnect()

	bodyGyro:Destroy()

	human.PlatformStand = false
	human.WalkSpeed = 16
end)

Incinerate = (function (human, character)
	human.Health = 0
	wait()

	-- Might be a shield keeping it alive or something
	if human.Health ~= 0 then return end

	local toDelete = {["Pants"]=true, ["Shirt"]=true, ["BodyColors"]=true}
	for _,v in next, character:GetChildren() do
		if toDelete[v.ClassName] then
			v:Destroy()
		end
	end

	local fire, light = CreateFireParticles()
	fire.Parent = Util.playerCharacterMainPart(character)
	light.Parent = Util.playerCharacterMainPart(character)

	for _,v in next, character:GetChildren() do
		if v:IsA"BasePart" then
			if math.random(0, 1) == 1 then
				v.BrickColor = BrickColor.Red()
			else
				v.BrickColor = BrickColor.new("Bright orange")
			end
		end
	end
	for i = 5, 20 do
		wait(0.1)
		fire.Size = i
	end
	for _,v in next, character:GetChildren() do
		if v:IsA"BasePart" then
			if math.random(0, 1) == 1 then
				v.BrickColor = BrickColor.Black()
			else
				v.BrickColor = BrickColor.Gray()
			end
		end
	end
end)

GetHumanoidAndCharacter = (function (part)
	if not part then
		return
	end

	while part.Parent and part.Parent ~= workspace do
		part = part.Parent
		for i,v in next, part:GetChildren() do
			if v:IsA"Humanoid" then
				return v, part
			end
		end
	end
end)

Fire = (function (tool, mouseHitPos)
	if tool.Handle:FindFirstChild"Sound" then
		tool.Handle.Sound:Play()
	end

	local ignoreList = {toolRegistry[tool].player.Character}
	local part, hitPoint = nil, nil

	local killMode = toolRegistry[tool].killMode
	local bullet = CreateBullet(killMode and BrickColor.Red() or BrickColor.Blue())

	bullet.CFrame = CFrame.new(tool.Handle.Position, mouseHitPos)
	bullet.Parent = workspace

	local direction = (mouseHitPos - tool.Handle.Position).unit
	local velocity = direction * shotSpeed
	local origin = bullet.CFrame
	local totalTime = 0
	local ignoreList = {toolRegistry[tool].player.Character, bullet}
	repeat
		local frameLength = wait()
		totalTime = totalTime + frameLength

		local offset = velocity*totalTime + Vector3.new(0, gravityConstant, 0)*0.5*(totalTime^2)

		local currentCF = bullet.CFrame
		local newCF = origin + offset

		bullet.CFrame = newCF

		local ignoreListCopy = Util.shallowCopyTable(ignoreList)
		local difference = newCF.p - currentCF.p
		part, hitPoint = RaycastIgnoreNonCollides(currentCF.p, difference.unit, difference.magnitude, ignoreListCopy)

		if part then
			break
		end
	until (bullet.CFrame.p - origin.p).magnitude > shotDistance

	bullet.Transparency = 1
	bullet.CFrame = CFrame.new(hitPoint)
	bullet.Size = Vector3.new(0.2, 0.2, 0.2)
	bullet.PointLight:Destroy()

	local impactSoundInst = Instance.new("Sound", bullet)
	impactSoundInst.SoundId = hitSound
	impactSoundInst:Play()

	local human, character = GetHumanoidAndCharacter(part)
	if human then
		bullet:Destroy()
		if killMode then
			Incinerate(human, character)
		else
			Stun(human, character)
		end
		bullet:Destroy()
	else -- hit effect
		if killMode then
			local fire, light = CreateFireParticles()
			fire.Parent = bullet
			light.Parent = bullet

			wait(0.25)
			fire.Enabled = false
		else
			local p1, p2, light = CreateSplashParticles()
			p1.Parent = bullet
			p2.Parent = bullet
			light.Parent = bullet

			wait(0.25)
			p1.Enabled = false
			p2.Enabled = false
		end

		debris:AddItem(bullet, 1)
	end
end)

RegistrationValidateTool = (function (player, tool)
	-- Basic tool validation
	if not tool or not tool:IsA"Tool" or not tool.Parent or tool.Name ~= toolName then
		return false
	end

	-- Make sure it's actually the player's tool
	if tool.Parent ~= player.Character and tool.Parent ~= player.Backpack then
		return false
	end

	-- No double registering
	if toolRegistry[tool] and toolRegistry[tool].player == player then
		return false
	end

	return true
end)

ValidateRemoteArgumnts = (function (player, tool)
	local reg = toolRegistry[tool]
	if not reg or reg.player ~= player or not tool:FindFirstChild("Handle") or tool.Parent ~= player.Character
		or not Util.playerAlive(player) then

		return false
	end

	return true
end)

ReplaceHandle = (function (tool, replacement)
	if tool:FindFirstChild("Handle") then
		tool.Handle:Destroy()
	end

	replacement = replacement:Clone()
	replacement.Anchored = false
	replacement.Name = "Handle"
	replacement.Parent = tool

	local shootSound = Instance.new("Sound", replacement)
	shootSound.SoundId = fireSound

	if tool.Parent == toolRegistry[tool].player.Character then
		local human, character = GetHumanoidAndCharacter(tool)
		human:UnequipTools()
		human:EquipTool(tool)
	end
end)

remoteRegister.OnServerInvoke = (function (player, tool)
	local pass, result = pcall(RegistrationValidateTool, player, tool)
	if not pass or not result then
		return
	end

	if toolRegistry[tool] then
		toolRegistry[tool].conn:disconnect()
		toolRegistry[tool] = nil
	end

	toolRegistry[tool] = {
		player       = player;
		limited      = not Access.IsPrivilegedUser(player);
		reloadOffset = 0;
		killMode     = false;
		conn         = nil;
	}
	-- Tool dropped or deleted check
	toolRegistry[tool].conn = tool.Changed:connect(function (prop)
		if prop ~= "Parent" then
			return
		end

		local reg = toolRegistry[tool]
		if (reg.player.Character and tool.Parent ~= reg.player.Character)
			and (reg.player:FindFirstChild"Backpack" and tool.Parent ~= reg.player.Backpack) then
			reg.conn:disconnect()
			toolRegistry[tool] = nil
		end
	end)

	ReplaceHandle(tool, stunHandle)

	if toolRegistry[tool] then
		return true, toolRegistry[tool].limited
	else
		return
	end
end)

remoteFire.OnServerInvoke = (function (player, tool, hitPos)
	if not ValidateRemoteArgumnts(player, tool) or toolRegistry[tool].reloadOffset > tick() then
		return false
	end

	coroutine.wrap(function ()
		Fire(tool, hitPos)
	end)()

	local reloadTime = toolRegistry[tool].limited and limitedReload or unlimitedReload
	toolRegistry[tool].reloadOffset = tick() + reloadTime

	return reloadTime -- fire confirmation
end)

remoteModeChange.OnServerInvoke = (function (player, tool, changeMode, changeFlashLight)
	if not ValidateRemoteArgumnts(player, tool) then
		return
	end

	local spot = tool.Handle:FindFirstChild("SpotLight")
	if spot and not spot:IsA("SpotLight") then
		spot = nil
	end

	if changeFlashLight and spot then
		spot.Enabled = not spot.Enabled
	elseif changeMode then
		local reg = toolRegistry[tool]
		local replacement = reg.killMode and stunHandle or killHandle

		ReplaceHandle(tool, replacement)
		tool.Handle.SpotLight.Enabled = spot and spot.Enabled or false

		reg.killMode = not reg.killMode
	end
end)

game.Players.PlayerRemoving:connect(function (leavingPlayer)
	for tool, dat in next, toolRegistry do
		if dat.player == leavingPlayer then
			toolRegistry[tool] = nil
		end
	end
end)