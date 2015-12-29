-- Zytharian (roblox: Legend26)

-- Services
local Replicated = game:GetService("ReplicatedStorage")

-- Configuration
local DEBUG = false

-- Internal vars
local netModel = workspace:WaitForChild("1_HQ_Network")

local events = {}
local waiters = {}

getAll = (function (Obj, SearchFor)
	local Tbl = {}
	for _,v in next, Obj:GetChildren() do
		if v:IsA(SearchFor)  then
			Tbl[#Tbl+1] = v
		else
			for _,x in next, getAll(v, SearchFor) do
				Tbl[#Tbl+1] = x
			end
		end
	end
	return Tbl
end)

registerNewEvents = (function (eventIdValue)
	if eventIdValue.Name:sub(1,3) ~= "EP_" then
		return
	end
	
	local curEv
	
	for i,v in next, events do
		if v.remoteEvent.Name == eventIdValue.Name then
			curEv = v
			break
		end
	end
	
	if not curEv then
		if DEBUG then
			print(script.Name .. " :: " .. "No RemoteEvent for " .. eventIdValue:GetFullName())
		end
		table.insert(waiters, eventIdValue)
		return
	end
	
	if not eventIdValue.Parent:IsA(curEv.className) then
		if DEBUG then
			print (script.Name .. " :: Warning: incompatible classname. Expected " .. curEv.className 
				.. " got " .. eventIdValue.Parent.ClassName .. "@" .. eventIdValue.Parent:GetFullName())
		end
		return
	end
	
	eventIdValue.Parent[curEv.eventName]:connect(function (...)
		if DEBUG then
			print(script.Name .. " :: Event fired " .. eventIdValue.Name .. " id: " .. eventIdValue.Value)
		end
		
		curEv.remoteEvent:FireServer {eventIdValue.Value, ...}
	end)
end)

registerNewRemote = (function (obj)
	if obj.ClassName == "RemoteEvent" and obj.Name:sub(1,3) == "EP_" then
		
		local className, eventName = obj.Name:match("EP_(%w+)_(%w+)")
		table.insert(events, {
			["className"] = className;
			["eventName"] = eventName;
			["remoteEvent"] = obj;		
		})	
		
		for i,v in next, waiters do
			if v.Name == obj.Name then
				table.remove(waiters, i)
				registerNewEvents(v)
			end
		end
		
	end
end)

for _,v in next, Replicated:GetChildren() do
	registerNewRemote(v)
end

for i,v in next, getAll(netModel, "IntValue") do
	registerNewEvents(v)
end

netModel.DescendantAdded:connect(function (obj)
	if obj.ClassName == "IntValue" then
		registerNewEvents(obj)
	end
end)

Replicated.DescendantAdded:connect(function (obj)
	registerNewRemote(obj)
end)