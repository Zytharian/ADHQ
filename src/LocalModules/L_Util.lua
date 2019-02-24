-- Zytharian (roblox: Legend26)

-- A stripped down local version of the server utilities module.
-- Note: For now, keep server and local util modules in sync.

-- Exported object
local UTIL = {}

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

-- return exported object
return UTIL