-- Zytharian (roblox: Legend26)

local privilegedUsers = {
	-- AD Owner
	[1916739] = true; -- Atlantiscorp

	-- AD HC
	[1222116] = true; -- Andy6a6
	[1614232] = true; -- Eumesmo92
	[1021552] = true; -- Legend26
	[6845272] = true; -- Myriden
	[1022526] = true; -- Yolopanther

	-- Other
	[6544405] = false; -- ArmyModder
	[1374878] = false; -- Flames911
	[32427  ] = false; -- Ganondude
	[1661611] = false; -- TheSmartRat

	-- Test
	[-1     ] = true; -- Server test player
}

local ACCESS = {}

ACCESS.IsPrivilegedUser = (function (player)
	for id,_ in next, privilegedUsers do
		if id == player.userId then
			return true
		end
	end

	return false
end)

ACCESS.HasCommandAccess = (function (player)
	for id,val in next, privilegedUsers do
		if id == player.userId and val then
			return true
		end
	end

	return false
end)

return ACCESS