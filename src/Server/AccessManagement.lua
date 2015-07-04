local privilegedUsers = {
	"Atlantiscorp";
	"Legend26";
	"andy6a6";
	"Yolopanher";
	"Ganondude";
	"flames911";
	"ArmyModder";
	"eumesmo92";
	"Player1";
}

local Access = {}

Access.IsPrivilegedUser = (function (player)
	for _, privlegedName in next, privilegedUsers do
		if privlegedName:lower() == player.Name:lower() then
			return true
		end
	end
	
	return false
end)

_G.Access = Access