-- Services
local projectRoot = game:GetService("ServerScriptService")

-- Includes
require(projectRoot.ClassLoader)
local Classes = require(projectRoot.Modules.ClassSystem)
local Util = require(projectRoot.Modules.Utilities)

-- Configuration
local DEBUG = false
local DOORS_ENABLED = true
local TRANSPORTERS_ENABLED = true
local CONSOLES_ENABLED = true
local TRAIN_ENABLED = true
local OVERRIDE_ENABLED = true
local RING_INTERFACE_ENABLED = true

--------
-- Header end
--------

local netModel = workspace["1_HQ_Network"]
local networkModels = {netModel.Main, netModel.Island}
local dPrint = Util.Debug.print

local train
if TRAIN_ENABLED then
	train = Classes.new 'Train' (netModel.Shuttle)
end

createNetwork = (function (model)
	dPrint("Creating network " .. model.Name, DEBUG)
	
	local sectionList = {}
	local transporterList = {}
	local ringsList = {}
	
	dPrint("-> Creating sections", DEBUG)
	for _,section in next,  model.Sections:GetChildren() do
		
		local doorList = {}
		local lightList
		local consoleList
		
		if DOORS_ENABLED then
			for _,door in next, section.Doors:GetChildren() do
				local doorClass = Classes.new 'Door' (door)
				table.insert(doorList, doorClass)
			end
		end
		
		
		if section:FindFirstChild"Lighting" then
			lightList = Util.findAll(section.Lighting, "Light")
		else
			lightList = {}
		end
		
		consoleList = section:FindFirstChild"Consoles" and section.Consoles:GetChildren() or {}
		
		local sectionClass = Classes.new 'Section' (section.Name, doorList, lightList, consoleList)
		table.insert(sectionList, sectionClass)
		
		dPrint("-> -> created section " .. model.Name .. "::" .. sectionClass.name, DEBUG)
	end

	if TRANSPORTERS_ENABLED then
		dPrint("-> Creating transporters", DEBUG)
		for _,transporter in next, model.Transportation:GetChildren() do
			local transClass = Classes.new 'Transporter' (transporter)
			
			for _,v in next, transporterList do
				v:linkTransporter(transClass)
				transClass:linkTransporter(v)
			end
			
			table.insert(transporterList, transClass)
			
			dPrint("-> -> created transporter " .. model.Name.. "::" .. transClass.name, DEBUG)
		end
	end
	
	if RING_INTERFACE_ENABLED then
		dPrint("-> Creating rings", DEBUG)
		
		for _,rings in next, model.Rings:GetChildren() do
			local ringsClass = Classes.new 'Rings' (rings)
			table.insert(ringsList, ringsClass)
		end
	end
	
	local networkClass = Classes.new 'Network' (model, sectionList, transporterList, train, ringsList)
	
	if CONSOLES_ENABLED then
		local consoleManager = Classes.new 'ConsoleManager' (networkClass)
		
		dPrint("-> Created console manaager", DEBUG)
	end
	
	if OVERRIDE_ENABLED then
		if model:FindFirstChild"Override" then
			local override = new Classes.new 'Override'(model.Override, networkClass)
			
			dPrint("-> Created override", DEBUG)
		end
	end
	
	return networkClass
end)

_G.AllNetworks = {}
for _,v in next, networkModels do
	_G[v.Name] = createNetwork(v)
	table.insert(_G.AllNetworks, _G[v.Name])
end
