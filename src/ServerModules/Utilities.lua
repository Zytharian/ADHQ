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
		if v.Character and v.Character:FindFirstChild"Torso" 
			and v.Character:FindFirstChild"Humanoid" and v.Character.Humanoid.Health > 0 then
			
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
	if not character or not character:FindFirstChild"Humanoid" or character.Humanoid.Health == 0 
	   or not character:FindFirstChild"Torso" or not character.Torso:IsA"BasePart" then
		
		return false
	end
	
	return true
end)

UTIL.playerNearModel = (function (player, model, maxDistanceFromAnyPart)
	if not player.Character or not player.Character:FindFirstChild"Torso" then
		return false
	end

	local torsoPos = player.Character.Torso.Position
	
	for _,v in next, UTIL.findAll(model, "BasePart") do
		if (torsoPos - v.Position).magnitude < maxDistanceFromAnyPart then
			return true
		end
	end
	
	return false
end)

-- Welding util module
UTIL.Welding = {}
UTIL.Welding._superList = {} -- { table = true }

UTIL.Welding.weld = (function (P0, P1, list, CustomJointName)
	local weld = Instance.new(CustomJointName or "Weld", game.JointsService)
	weld.Part0, weld.Part1 = P0, P1
	weld.C1 = weld.Part1.CFrame:toObjectSpace(weld.Part0.CFrame) 
	
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