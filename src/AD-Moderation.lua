-- Zytharian (roblox: Legend26)

--Ancient Domain Moderation System v2.3

--[[

Lvl 5 = AD owner, for debug purposes. Overrides all settings.
Lvl 4 = HC, game creator
Lvl 3 = C
Lvl 0 = visitors
Lvl -1= Banned

Commands:
!run LuaCode		-ypcalls the code passed. Used for debugging. (Lvl 5)
!shutdown			-Shutdown the server. (Lvl 4)
!ban PlayerName		-Bans the specified player from server. (Lvl 4)
!unban PlayerName	-Unbans the specified player from the server (Lvl 4)
!kill PlayerName	-Kills the specified player (Lvl 4)
!kick PlayerName	-Kicks the specified player from the server. (Lvl 3)
!adonly				-Makes the server private to AD members only. (Lvl 3)
!public				-Reverses the effect of adonly and makes the server available to all people. (Lvl 3)
!teleport From To	-Teleports one player to the other. (Lvl 3)
!help				-Gives a list of available commands. Only displays if the person has access to more than one command. (Lvl 0)

API:
	int _G.ADM.GetAD_Id()
		Returns the Id of the main Ancient Domain group

Change log:

Changes in version 2.3:
	Removed _G.ADM.GetGroupRank (New Player methods)
	Added _G.ADM.GetAD_Id
	Internal:
		Removed Users table in favor of rank based methods
		Created BannedPlayers table since Users table was removed

Changes in version 2.2:
	Bug fix where the first person to join the game doesn't get the GUI
	Small optimizations and cleanup and little fixes

Changes in version 2.1:
	Bug fix where one of the options also disabled another command
	Slight optimization when a player enters
	Changed Remove calls to Destroy
]]


AllowTeleport = true --!teleport
AllowShutdown = false --!shutdown
AllowKill = true --!kill

-------------
--Variables--
-------------

local Prefix = "!"

local Access = require(script.Parent.Modules.AccessManagement)

local AD_Id = 1092
local IsPRI = false --Kicks players that aren't in AD when true.

local RankRef = {
[255] = 5;	--Owner
[250] = 4;	--HC
[200] = 3;	--C
[0] = 0;	--Guest
}

local BannedPlayers = {}

local Commands = {
[0] = {};
[3] = {};
[4] = {};
[5] = {};
}

local API = {} --_G.ADM

---------------------
--General Functions--
---------------------

local GetSecurityLevel = (function (Plyr, DoNotInclueCreator)
	local Rank = Plyr:GetRankInGroup(AD_Id)

	if BannedPlayers[Plyr.Name:lower()] then
		return -1 --banned
	elseif not DoNotInclueCreator and Plyr.userId == game.CreatorId then
		if RankRef[Rank] > 4 then
			return RankRef[Rank]
		else
			return 4
		end
	elseif Access.HasCommandAccess(Plyr) then -- Game admins have rank 4
		return RankRef[250]
	end

	return RankRef[Rank] or 1 --1 = AD member
end)

local GetAvailableCommands = (function (Lvl)
	local Tbl = {} --NameOfCommand = FunctionOfCommand
	for i=0,Lvl do
		if Commands[i] then
			for i,v in next, Commands[i] do
				Tbl[i] = v
			end
		end
	end
	return Tbl
end)

local GiveGui = (function (Plyr)
	local Gui = Instance.new("ScreenGui")
		Gui.Name = "ADModeration"
	local Frm = Instance.new("Frame",Gui)
		Frm.Style = "RobloxRound"
		Frm.Size = UDim2.new(0,125,0,20)
		Frm.Position = UDim2.new(1,-210,1,-40)
		Frm.Visible = false
	local Title = Instance.new("TextLabel",Frm)
		Title.Text = "AD only Server"
		Title.Font = "ArialBold"
		Title.FontSize = "Size14"
		Title.Size = UDim2.new(1,0,1,0)
		Title.TextColor3 = Color3.new(1,1,1)
		Title.BackgroundTransparency = 1
	--local Img = Instance.new("ImageLabel",Gui)
	--	Img.Image = "http://www.roblox.com/asset/?id=46776566"
	--	Img.Size = UDim2.new(0,40,0,40)
	--	Img.Position = UDim2.new(1,-100,1,-50)
	--	Img.BackgroundTransparency = 1

	Gui.Frame.Visible = IsPRI
	Gui.Parent = Plyr:findFirstChild"PlayerGui"
end)

local UpdateGUIs = (function ()
	for i,v in next, game.Players:GetPlayers() do
		if v:findFirstChild"PlayerGui" and v.PlayerGui:findFirstChild"ADModeration" then
			local Gui = v.PlayerGui.ADModeration
			if Gui:findFirstChild"Frame" and Gui.Frame.ClassName == "Frame" then
				Gui.Frame.Visible = IsPRI
			end
		end
	end
end)

local GetPlayer = (function (s)
	local Plyr = nil
	for i,v in next, game.Players:GetPlayers() do
		if v.Name:lower():find(s:lower(),1,true) then --disable string patterns
			if not Plyr then
				Plyr = v
			else
				return nil --Ambiguous
			end
		end
	end
	return Plyr
end)

local MessagePlayer = (function (Plyr, Msg)
	local Gui = Instance.new"ScreenGui"
	local TextLabel = Instance.new("TextLabel",Gui)

	TextLabel.Text = tostring(Msg)
	TextLabel.Font = Enum.Font.ArialBold
	TextLabel.FontSize = Enum.FontSize.Size18
	TextLabel.BackgroundColor3 = Color3.new(77/255,77/255,77/255)
	TextLabel.TextColor3 = Color3.new(1,1,1)
	TextLabel.Position = UDim2.new(0, 0, 0.7, 0)
	TextLabel.Size = UDim2.new(1, 0, 0, 30)
	TextLabel.BorderSizePixel = 0

	Gui.Parent = Plyr:findFirstChild"PlayerGui"
	wait(5)
	Gui:Destroy()
end)

------------
--Commands--
------------

Commands[5].run = {(function (Plyr, Msg)
	local fn, LoadErr = loadstring("function run(adm) "..Msg.." end run(...)")
	if fn then
		local Status, RunErr = ypcall(fn,
			{
				Prefix=Prefix,AD_Id=AD_Id,IsPRI=IsPRI,Commands=Commands,RankRef=RankRef,API=API,Plyr=Plyr,
				GetSecurityLevel=GetSecurityLevel,GetAvailableCommands=GetAvailableCommands,
				GiveGui=GiveGui,UpdateGUIs=UpdateGUIs,GetPlayer=GetPlayer,MessagePlayer=MessagePlayer
			}
		)
		if not Status then
			MessagePlayer(Plyr,"Runtime error: "..RunErr)
		end
	else
		MessagePlayer(Plyr,"Compile error: "..LoadErr)
	end
end), "<LuaCode>"}

Commands[4].shutdown = (function (Plyr)
	if not AllowShutdown and GetSecurityLevel(Plyr) ~= 5 then return end
	Instance.new("StringValue",workspace).Value = ("A"):rep(2e5+1) --disconnect
	pcall(function () Instance.new("ManualSurfaceJointInstance") end) --crash server
	ypcall(wait, 0) --Another way to crash the server
end)

Commands[4].kill = {(function (Plyr, Msg)
	if not AllowKill and GetSecurityLevel(Plyr) ~= 5 then return end
	local To = GetPlayer(Msg)
	if not To then return end
	local sPlyr, sTo = GetSecurityLevel(Plyr), GetSecurityLevel(To)
	if To ~= Plyr and sTo >= sPlyr then return end
	if To.Character then
		local ObjV = Instance.new("ObjectValue",To.Character:findFirstChild"Humanoid")
		ObjV.Name = "creator"
		ObjV.Value = Plyr
		To.Character:BreakJoints()
	else
		local Mdl = Instance.new("Model", workspace)
		local Part = Instance.new("Part", Mdl)
		Part.Name = "Torso"
		local Hum = Instance.new("Humanoid", Mdl)
		To.Character = Mdl
	end
end), "<Player>"}

Commands[4].ban = {(function (Plyr,Msg)
	local To = GetPlayer(Msg)
	if not To then return end
	local sPlyr, sTo = GetSecurityLevel(Plyr), GetSecurityLevel(To)
	if sTo >= sPlyr then return end
	BannedPlayers[To.Name] = true
	To:Kick()
end), "<Player>"}

Commands[4].unban = {(function (Plyr,Msg)
	Msg = Msg:lower()
	local Fnd = nil
	for v in next, BannedPlayers do --Index is the player name in this table
		if v:lower():find(Msg,1,true) then
			if Fnd then
				return --Ambiguous
			else
				Fnd = v
			end
		end
	end
	if Fnd then
		BannedPlayers[Fnd] = nil
	end
end), "<Player>"}

Commands[3].kick = {(function (Plyr,Msg)
	local To = GetPlayer(Msg)
	if not To then return end
	local sPlyr, sTo = GetSecurityLevel(Plyr), GetSecurityLevel(To)
	if sTo >= sPlyr then return end
	To:Kick()
end), "<Player>"}

Commands[3].teleport = {(function (Plyr, Msg)
	if not AllowTeleport and GetSecurityLevel(Plyr) ~= 5 then return end
	local t,p1,p2,PlyrS,p1S = {},nil,nil,GetSecurityLevel(Plyr),nil
	for i in Msg:gmatch"[%w%p]+" do
		table.insert(t,i)
	end
	if #t == 1 then
		p1 = Plyr
		p2 = GetPlayer(t[1])
	elseif #t >= 2 then
		p1 = GetPlayer(t[1])
		p2 = GetPlayer(t[2])
	end
	local Ck = (function (p)
		if not p or not p.Character or not p.Character:findFirstChild"Torso"
		or p.Character.Torso.ClassName ~= "Part" then
			return false
		else
			return true
		end
	end)
	if p1 == p2 or not Ck(p1) or not Ck(p2) then return end
	p1S = GetSecurityLevel(p1)
	if Plyr ~= p1 and p1S >= PlyrS then return end
	for i,v in next, p1.Character:GetChildren() do
		if v.ClassName == "Humanoid" then
			v.Sit = false
			v.PlatformStand = false
		end
	end
	--p1.Character.Torso.Anchored = true
	--wait(0.25)
	p1.Character.Torso.CFrame = p2.Character.Torso.CFrame
	--p1.Character.Torso.Anchored = false
end), "<From> <To>"}

Commands[3].adonly = (function (Plyr)
	IsPRI = true
	UpdateGUIs()
end)

Commands[3].public = (function (Plyr)
	IsPRI = false
	UpdateGUIs()
end)

Commands[0].help = (function (Plyr)
	local SecLvl = GetSecurityLevel(Plyr)
	local Commands = GetAvailableCommands(SecLvl)
	if not AllowTeleport and Commands.teleport then
		Commands.teleport = nil
	end
	if not AllowShutdown and Commands.shutdown then
		Commands.shutdown = nil
	end
	if not AllowKill and Commands.kill then
		Commands.kill = nil
	end

	local Gui = Instance.new"ScreenGui"
	local Frame = Instance.new("Frame",Gui)
	local Close = Instance.new("ImageButton",Frame)
	local Title = Instance.new("TextLabel",Frame)
	local Border = Instance.new("Frame",Frame)

	local Color = Color3.new(221/255, 221/255, 221/255)

	Title.BackgroundTransparency = 1
	Title.TextColor3 = Color
	Title.TextXAlignment = Enum.TextXAlignment.Left
	Title.Font = Enum.Font.ArialBold
	Title.FontSize = Enum.FontSize.Size14
	Title.Size = UDim2.new(1, 0, 0, 25)
	Title.Text = "Commands " .. SecLvl

	Border.BackgroundTransparency = 0.2
	Border.BorderSizePixel = 0
	Border.Position = UDim2.new(0, 0, 0, 30)
	Border.Size = UDim2.new(1, 0, 0, 5)

	Close.BackgroundTransparency = 1
	Close.Image = "rbxasset://textures/ui/CloseButton.png"
	Close.Position = UDim2.new(1, -25, 0, 0)
	Close.Size = UDim2.new(0, 25, 0, 25)
	Close.MouseButton1Click:connect(function ()
		Gui:Destroy()
	end)

	local iterator = 0
	for i,v in next, Commands do
		local Label = Instance.new("TextLabel",Frame)
		Label.Size = UDim2.new(1,0,0,15)
		Label.Position = UDim2.new(0,0,0,(iterator * 15) + 35)
		Label.TextColor3 = Color
		Label.BackgroundTransparency = 1
		Label.FontSize = Enum.FontSize.Size10
		Label.TextXAlignment = Enum.TextXAlignment.Left
		if type(v) == "table" then
			Label.Text = Prefix..i.." "..v[2]
		else
			Label.Text = Prefix..i
		end
		iterator = iterator + 1
	end
	Frame.Style = Enum.FrameStyle.RobloxRound
	Frame.Size = UDim2.new(0,180,0,(iterator * 15) + 50)
	Frame.Position = UDim2.new(0.1,0,0.5,-Frame.Size.X.Offset / 2)
	Frame.Active = true
	Frame.Draggable = true

	if Plyr:findFirstChild"PlayerGui" then
		if Plyr.PlayerGui:findFirstChild"ADModeration Help" then
			Plyr.PlayerGui["ADModeration Help"]:Destroy()
		end
		Gui.Name = "ADModeration Help"
		Gui.Parent = Plyr.PlayerGui
	end
end)

-------
--API--
-------

API.GetAD_Id = (function ()
	return AD_Id
end)

---------
--Setup--
---------

_G.ADM = API
for i=1, #BannedPlayers do
	BannedPlayers[BannedPlayers[i]:lower()] = true
	BannedPlayers[i] = nil
end

--Initialize stuff--
game.Players.PlayerAdded:connect(function (Plyr)
	if (IsPRI and not Plyr:IsInGroup(AD_Id)) or GetSecurityLevel(Plyr) == -1 then
		Plyr:Destroy()
		return
	end
	if Plyr.Character then --GetSecurityLevel uses IsInGroup which is too slow. Thus the following check.
		wait(0.1)
		GiveGui(Plyr)
	end
	Plyr.CharacterAdded:connect(function (Char)
		wait(0.1)
		GiveGui(Plyr)
	end)
	Plyr.Chatted:connect(function (Msg)
		if Msg:sub(1,1) ~= Prefix then return end
		local Cmds = GetAvailableCommands(GetSecurityLevel(Plyr))
		local Args = Msg:match("%s(.+)") or ""
		for i,v in next, Cmds do
			if Msg:sub(2,#i+1):lower() == i:lower() then
				if type(v) == "table" then
					v[1](Plyr,Args)
				else
					v(Plyr,Args)
				end
				return
			end
		end
	end)
end)

--Legend26
