-- Zytharian (roblox: Legend26)

-- Services
local projectRoot = game:GetService("ServerScriptService")
local RS = game:GetService("ReplicatedStorage")

-- Includes
local Classes = require(projectRoot.Modules.ClassSystem)

--[[
	init(string objectType, string eventName)

	Properties:

	Methods:
		addObject(Rbx::Instance object)

	Events:
		eventFired(Rbx::Player player, Rbx::Instance object,  ...)
		
]]

local registry = {}
	-- {string compoundedName = #registered}

Classes.class 'EventPropagator' (function (this) 

	--[[
		Internal properties:
			string objectType
			string compoundedName
			table objects
			Signal eventFired
			Rbx::RemoteEvent rbxEvent
	]]

	function this:init (objectType, eventName)
		self.objectType = objectType
		
		self.objects = {}
		self.eventFired = Classes.new 'Signal' ()
		
		self.compoundedName = "EP_"..objectType.."_"..eventName
		
		if not registry[self.compoundedName] then
			registry[self.compoundedName] = 0
			self.rbxEvent = Instance.new("RemoteEvent", RS)
			self.rbxEvent.Name = self.compoundedName
		else
			self.rbxEvent = RS:FindFirstChild(self.compoundedName)
		end
		
		self.rbxEvent.OnServerEvent:connect(function (player, args)
			if type(args[1] ) ~= "number" or args[1] < 1 or args[1] > registry[self.compoundedName] then
				return
			end
			args[1] = self.objects[args[1]]
			
			if not args[1] then
				return
			end
			
			self.eventFired:Fire(player, unpack(args))
		end)
	end

	function this.member:addObject(object)
		if not object:IsA(self.objectType) then
			error("Wrong object type. Expected '" .. self.objectType .. "' got '" .. object.ClassName .. "'")
		end
		
		registry[self.compoundedName]  = registry[self.compoundedName] + 1
		
		local objVal = Instance.new("IntValue", object)
		objVal.Value = registry[self.compoundedName]
		objVal.Name = self.compoundedName
		self.objects[registry[self.compoundedName]] = object
	end
	
	-- public methods
	this.get.addObject = true
	
	-- public events
	this.get.eventFired = true	
end)

return false