-- Zytharian (roblox: Legend26)

-- Initialize all the classes

local projectRoot = game.ServerScriptService

-- Includes
local Util = require(projectRoot.Modules.Utilities)

-- Initialize StandardClasses and ClassSystem
require(projectRoot.Modules.ClassSystem)
require(projectRoot.Modules.StandardClasses)

-- Initialize server classes
local numClasses = 0
local dPrint = Util.Debug.print
local DEBUG = true

initClasses = (function (obj)
	for _,v in next, obj:GetChildren() do
		dPrint("-> Init class " .. v.Name, DEBUG)
		numClasses = numClasses + 1
		require(v)
		initClasses(v)
	end
end)

dPrint("Initializing classes", DEBUG)
initClasses(script)
dPrint("Classes initialized: #" .. numClasses, DEBUG)

return false