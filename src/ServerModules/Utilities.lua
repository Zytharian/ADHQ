-- Zytharian (roblox: Legend26)

-- Exported object
local UTIL = {}

UTIL.findAll = (function (object, className)
	local found = {}
	for _,v in next, object:GetChildren() do
		if v:IsA(className) then
			table.insert(found, v)
		else
			local recur = UTIL.findAll(v, className)
			for _,v in next, recur do
				table.insert(found, v)
			end
		end
	end
	return found
end)

UTIL.shallowCopyTable = (function (tbl)
	local cpy = {}
	for i,v in next, tbl do
		cpy[i] = v
	end
	return cpy
end)

UTIL.getRegion3Around = (function (ref, size)
	local mid = ref.p
	local dist = ref * (size* .5) - mid
	dist = Vector3.new(math.abs(dist.x), math.abs(dist.y), math.abs(dist.z))

	local Vec1 = mid - dist
	local Vec2 = mid + dist

	return Region3.new(Vec1, Vec2)
end)

UTIL.getPlayersInRegion3 = (function (region, ignore)
	local partList = workspace:FindPartsInRegion3(region, ignore, 100)
	local list = {}

	for _,v in next, game.Players:GetPlayers() do
		if UTIL.playerAlive(v) then
			for _,part in next, partList do
				if part:IsDescendantOf(v.Character) then
					table.insert(list, v)
					break
				end
			end
		end
	end

	return list
end)

UTIL.playerAlive = (function (player)
	local character = player.Character
	if not character
		or not character:FindFirstChild"Humanoid"
		or character.Humanoid.Health == 0
		or not UTIL.playerCharacterMainPart(character)
	then

		return false
	end

	return true
end)

UTIL.playerNearModel = (function (player, model, maxDistanceFromAnyPart)
	local main = UTIL.playerCharacterMainPart(player.Character)

	if not main then
		return false
	end

	local torsoPos = main.Position
	for _,v in next, UTIL.findAll(model, "BasePart") do
		if (torsoPos - v.Position).magnitude < maxDistanceFromAnyPart then
			return true
		end
	end

	return false
end)

UTIL.playerCharacterMainPart = (function (character)
	if not character or not character:IsA("Model") then
		return nil
	end

	if character.PrimaryPart then
		return character.PrimaryPart
	end

	local hrp = character:FindFirstChild("HumanoidRootPart")
	if hrp and hrp:IsA("BasePart") then
		return hrp
	end

	local torso = character:FindFirstChild("Torso")
	if torso and torso:IsA("BasePart") then
		return torso
	end

	return nil
end)

-- Welding util module
UTIL.Welding = {}
UTIL.Welding._superList = {} -- { table = true }

UTIL.Welding.weld = (function (P0, P1, list, CustomJointName)
	local weld

	weld = Instance.new(CustomJointName or "Weld")
	weld.C1 = P1.CFrame:toObjectSpace(P0.CFrame)
	weld.Part0 = P0
	weld.Part1 = P1
	weld.Parent = game.JointsService

	if list then
		list[weld] = true
	end

	return weld
end)

UTIL.Welding.addSuperList = (function (list)
	UTIL.Welding._superList[list] = true
end)

UTIL.Welding.removeSuperList = (function (list)
	UTIL.Welding._superList[list] = nil
end)

game.JointsService.DescendantRemoving:connect(function (c)
	for list,_ in next, UTIL.Welding._superList do
		if list[c] then
			list[UTIL.Welding.weld(c.Part0, c.Part1, nil, c.ClassName)] = true
			list[c] = nil
		end
	end
end)

-- Debug util module
UTIL.Debug = {}

UTIL.Debug.print = (function (message, isDebug)
	if isDebug then
		print(message)
	end
end)

-- return exported object
return UTIL