--awm "andy6a6", telestairs v3.0 - using Legend26's LuaCS (c: 2015-08-16, u: 2015-08-17)

-- Services
local projectRoot = game:GetService("ServerScriptService")

-- Includes
local Classes = require(projectRoot.Modules.ClassSystem)
local Util = require(projectRoot.Modules.Utilities)

--[[
	init(Rbx::Model model)

	Properties:
		readonly string name
		readonly int id
		readonly int tardget id
		readonly bool paired
		readonly Rbx::BasePart tpad

	Methods:
		void pairMe(TeleStairs)

	Events:


]]

--------
-- Header end
--------


Classes.class 'TeleStairs' (function (this)


	function this:init (model)

		--Configuration
		self.min_required_displacement = 2.4
		self.scan_interval = 0.1
		self.regionHeight = 10

		--Identity & Self Knowledge
		self.model = model
		self.id = model.id.Value
		self.tpad = self.model.Step
		self.targetid = model.tid.Value
		self.name = model.Name .. ("(id "..self.id..")")

		--World Knowledge
		self.corners = model.Corners
		self.trigger = model.Trigger.Position
		self.p1 = self.corners.c1.Position
		self.p2 = self.corners.c2.Position
		self.Region = nil

		--Internals
		self.isRunning = false
		self.paired = false
		self.metadata = {}

		self:initRegion()
		self.tpad.Touched:connect(function() self:metaMonitor() if self.isRunning == false then self:cycleCheck() end end)
	end

	function this.member:initRegion()
		--Ensures correct bounds for region...
			self.Region = Region3.new(Vector3.new(
									(self.p1.X<self.p2.X and self.p1.X or self.p2.X),
									self.p1.Y,
									(self.p1.Z<self.p2.Z and self.p1.Z or self.p2.Z)
								),
								Vector3.new(
									(self.p1.X>self.p2.X and self.p1.X or self.p2.X),
									self.p2.Y+self.regionHeight,
									(self.p1.Z>self.p2.Z and self.p1.Z or self.p2.Z)
								))
		end

	function this.member:pairMe(tab)
		if(not self.paired) then
			self.target = tab
			self.paired = true
		end
	end

	function this.member:metadataLookup(player)
	--//is the current player known?
		for _,element in pairs (self.metadata) do
			--//If Yes, does their data need reseting?
			if(element[1] == player) then
				if(element[3]) then
					if(element[1].Character ~=nil and element[1].Character.Torso~=nil) then
						element[2] = element[1].Character.Torso.Position
						element[3] = false
					end
				end
				element[4] = true
				return element
			end
		end
		--//Otherwise make their record
		self.metadata[#self.metadata+1] = {player, player.Character.Torso.Position, false, true}
		return self.metadata[#self.metadata]
	end

	--//Sets player metadata reset flag to true.
	function this.member:wipeMeta(who)
		for _,element in pairs (self.metadata) do
			if(element[1] == who) then
				element[3] = true
			end
		end
	end

	--//is the player in the region still?
	function this.member:hasLeftRegion(element)
		for _,Part in pairs (game.Workspace:FindPartsInRegion3(self.Region, nil, 100)) do
			if(element[1]==nil or element[1].Character == nil or Part == element[1].Character.Torso) then
				return false
			end
		end
		return true

	end

	--//Ensures player metadata is wipped if they exit the region.
	function this.member:metaMonitor()
		for _,element in pairs (self.metadata) do
			if(element[4] == true) then
				if(self:hasLeftRegion(element)) then
					self:wipeMeta(element[1])
					element[4] = false
				end
			end
		end
	end

	--Teleport
	function this.member:Teleport(playerRef)
		self.Pad1=self.tpad
		self.Pad2=self.target.tpad

		if(playerRef == nil or playerRef.Character == nil) then
			return
		end

		local player = playerRef.Character

		if(player~=nil and player.Torso ~= nil) then
			local RelativePos = self.Pad1.CFrame:toObjectSpace(player.Torso.CFrame)
			player.Torso.CFrame = self.Pad2.CFrame:toWorldSpace(RelativePos)
		end
	end

	--//Judge player's intention
	function this.member:DisplacementCalculation(meta)
		--//Get information
		if(meta == nil or meta[1] == nil or meta[2] == nil or meta[1].Character.Torso == nil) then return end

		local iPos = meta[2]
		local cPos = meta[1].Character.Torso.Position
		local Displacement_Trigger_Current = (self.trigger - cPos).magnitude
		local Displacement_Trigger_Initial = (self.trigger - iPos).magnitude
		local Displacement_Current_Initial = (Vector2.new(cPos.X, cPos.Z) - Vector2.new(iPos.X, iPos.Z)).magnitude --ignore jumping...

		--// Is the player closer to the target than they initially where, and is the displacement from their initial position great enough?
		if((Displacement_Trigger_Current < Displacement_Trigger_Initial) and Displacement_Current_Initial > self.min_required_displacement ) then
			self:Teleport(meta[1])
			self:wipeMeta(meta[1])
			return true
		else
			return false
		end
	end

	--Check Region for parts...
	function this.member:cycleCheck()
	self.isRunning = true
	while(not game.Workspace:IsRegion3Empty(self.Region)) do
		wait(self.scan_interval)
		for _,Part in pairs (game.Workspace:FindPartsInRegion3(self.Region, nil, 100)) do
			if(Part.Name == "Torso") then
					local player = game.Players:GetPlayerFromCharacter(Part.Parent)
					if(player ~= nil) then
						self:DisplacementCalculation(self:metadataLookup(player))
					end
			end
			self:metaMonitor()
		end
	end
	self.isRunning = false;
	end

	-- public properties
	this.get.name = true
	this.get.id = true
	this.get.targetid = true
	this.get.paired = true
	this.get.tpad = true

	-- public methods
	this.get.pairMe = true


end)
return false

--awm "andy6a6", telestairs v3.0.1 - using Legend26's LuaCS (c: 2015-08-16, u: 2015-08-17)