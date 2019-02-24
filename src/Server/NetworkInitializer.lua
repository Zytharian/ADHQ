-- Zytharian (roblox: Legend26)

-- Services
local projectRoot = game:GetService("ServerScriptService")

-- Includes
require(projectRoot.ClassLoader)
local Classes = require(projectRoot.Modules.ClassSystem)
local Util = require(projectRoot.Modules.Utilities)

-- Configuration
local DEBUG = true
local DOORS_ENABLED = true
local TRANSPORTERS_ENABLED = true
local CONSOLES_ENABLED = true
local TRAIN_ENABLED = true
local OVERRIDE_ENABLED = true
local RING_INTERFACE_ENABLED = true
local TELESTAIRS_ENABLED = true
local POWER_ENABLED = true

--------
-- Header end
--------

local netModel = workspace["1_HQ_Network"]
local networkModels = {netModel.Main, netModel.Island, netModel.Hidden}
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
	local stairsList = {}
	local power = nil

	dPrint("-> Creating sections", DEBUG)
	for _,section in next,  model.Sections:GetChildren() do

		local doorList = {}
		local lightList = {}
		local consoleList
		local windowGuard

		if DOORS_ENABLED and section:FindFirstChild"Doors" then
			for _,door in next, section.Doors:GetChildren() do
				local doorClass = Classes.new 'Door' (door)
				table.insert(doorList, doorClass)
			end
		end

		lightList.neons = {}
		lightList.lights = {}
		if section:FindFirstChild"Lighting" then
			for _,v in next, Util.findAll(section.Lighting, "Light") do
				lightList.lights[v] = v.Color
			end
			for _,v in next, Util.findAll(section.Lighting, "BasePart") do
				if v.Material == Enum.Material.Neon then
					lightList.neons[v] = v.BrickColor
				end
				if v.Name == "TrueLight" then -- Hide massive gray TrueLight parts
					v.Transparency = 1
				end
			end
		end

		consoleList = section:FindFirstChild"Consoles" and section.Consoles:GetChildren() or {}

		if section:FindFirstChild"Windows" then
			windowGuard = Classes.new 'WindowGuard' (section.Windows)
		end

		local sectionClass = Classes.new 'Section' (section.Name, doorList, lightList, consoleList, windowGuard)
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

	if TELESTAIRS_ENABLED and model:FindFirstChild("TeleStairs") then
		dPrint("-> Creating telestairs", DEBUG)
		for _,stairset in next, model.TeleStairs:GetChildren() do
			local stairClass = Classes.new 'TeleStairs' (stairset)
			table.insert(stairsList, stairClass)

			dPrint("-> -> created telesairs " .. model.Name.. "::" .. stairClass.name, DEBUG)
		end
		--Linker
		for _,step in next, stairsList do
			if (not step.paired) then
				local tid = step.targetid
				for _,step2 in next, stairsList do
					local sid = step2.id
					if(sid == tid) then
						step:pairMe(step2)
						step2:pairMe(step)
					end
				end
			end
		end
	end

	if RING_INTERFACE_ENABLED and model:FindFirstChild"Rings" then
		dPrint("-> Creating rings", DEBUG)

		for _,rings in next, model.Rings:GetChildren() do
			local ringsClass = Classes.new 'Rings' (rings)
			table.insert(ringsList, ringsClass)
		end
	end

	if POWER_ENABLED and model:FindFirstChild"Power" then
		power = Classes.new 'Power' (model.Power)
	end

	local networkClass = Classes.new 'Network' (model, sectionList, transporterList, train, ringsList, power)

	if CONSOLES_ENABLED then
		local consoleManager = Classes.new 'ConsoleManager' (networkClass)

		dPrint("-> Created console manaager", DEBUG)
	end

	if OVERRIDE_ENABLED then
		if model:FindFirstChild"Override" then
			local override = Classes.new 'Override'(model.Override, networkClass)

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
