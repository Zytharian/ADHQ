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
local DEBUG = false

initClasses = (function (obj)
	for _,v in next, obj:GetChildren() do
		print("-> Init class " .. v.Name)
		numClasses = numClasses + 1
		require(v)
		initClasses(v)
	end
end)

dPrint("Initializing classes", DEBUG)
initClasses(script)
dPrint("Classes initialized: #" .. numClasses, DEBUG)

return false