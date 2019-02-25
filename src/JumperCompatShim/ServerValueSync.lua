-- Zytharian (roblox: Legend26)

-- Description:
-- Quick and dirty Jumper compatibility shim

local NAME = "BOUNDARY_VALUE_SYNC"
local model = script.Parent.Parent

local remoteFn = Instance.new("RemoteFunction")
remoteFn.Name = NAME
remoteFn.Parent = model

remoteFn.OnServerInvoke = (function (player, valueObject, value, childClass)
	-- Get the target, make sure it's a *Value object
	local target = type(valueObject) == "string" and model:FindFirstChild(valueObject) or nil
	if (not target) or (not target:IsA("ValueBase")) then
		return
	end
	-- Update the value
	pcall(function()
		if (not childClass) then
			if (target.Value == value) then
				return
			end
			target.Value = value
		else
			local child = Instance.new(childClass)
			if (not child:IsA("ValueBase")) then
				return
			end
			child.Name = "DO_NOT_REPLICATE"
			child.Value = value
			child.Parent = target
		end
	end)
end)
