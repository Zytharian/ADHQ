-- Zytharian (roblox: Legend26)

-- Services
local Replicated = game:GetService("ReplicatedStorage")

-- Include
local Util = require(Replicated.Util)

-- Internal vars
local flag = Replicated:WaitForChild("FLAG_AlarmPlaying")
local player = game.Players.LocalPlayer

local soundId = "http://www.roblox.com/asset/?id=167108295"

local sound = Instance.new("Sound")
sound.SoundId = soundId
sound.Volume = 0.15 -- Keep within 0.1 and 0.25

flag.Changed:connect(function ()
	local enabled = flag.Value
	if enabled then
		sound.Looped = true
		sound:Play()
	else
		sound.Looped = false
	end
end)

if flag.Value then
	sound.Looped = true
	sound:Play()
end

local mainPart
repeat
	wait()
	mainPart = Util.playerCharacterMainPart(player.Character)
until mainPart
sound.Parent = mainPart