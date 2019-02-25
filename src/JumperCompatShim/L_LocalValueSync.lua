-- Zytharian (roblox: Legend26)

-- Description:
-- Quick and dirty Jumper compatibility shim

wait(0.2)

local NAME = "BOUNDARY_VALUE_SYNC"
local gui = script.Parent
local model = gui.Model.Value
local remoteFn = model[NAME]

--
--
-- We just need to send our changes to the server.
-- Roblox will handle the server's changes automatically.

function hook(obj)
	if (not obj:IsA("ValueBase")) then
		return
	end

	print(NAME .. ": got " .. obj.Name .. " as " .. obj.ClassName)

	obj.Changed:Connect(function ()
		remoteFn:InvokeServer(obj.Name, obj.Value)
	end)
	obj.ChildAdded:Connect(function (child)
		if (child.Name == "DO_NOT_REPLICATE") then
			return
		end

		wait() -- Prevent the "Something unexpectedly tried to set the parnt" error
		child:Destroy()

		remoteFn:InvokeServer(obj.Name, child.Value, child.ClassName)
	end)
end

for _,obj in pairs(model:GetChildren()) do
	hook(obj)
end
