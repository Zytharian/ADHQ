-- Zytharian (roblox: Legend26)

local privilegedUsers = {
	-- AD Owner
	1916739; -- Atlantiscorp

	-- AD HC
	1222116; -- Andy6a6
	1614232; -- Eumesmo92
	1021552; -- Legend26
	6845272; -- Myriden
	1022526; -- Yolopanther
	
	-- Other
	6544405; -- ArmyModder
	1374878; -- Flames911
	32427  ; -- Ganondude
	1661611; -- TheSmartRat
	
	-- Test
	-1     ; -- Server test player
}

local Access = {}

Access.IsPrivilegedUser = (function (player)
	for _, id in next, privilegedUsers do
		if id == player.userId then
			return true
		end
	end
	
	return false
end)

_G.Access = Access