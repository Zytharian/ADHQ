-- Services
local projectRoot = game:GetService("ServerScriptService")

-- Includes
local cs = require(projectRoot.Modules.ClassSystem)
local Util = require(projectRoot.Modules.Utilities)

-- Configuration
local DEBUG = false

--[[
	init(string name, table sectionList, table transporterList)

	Properties:
		[readonly] bool isMoving
		
	Methods:
		void setEnabled(bool enabled)
		bool isEnabled()
		
	Events:
		void
		
	Callbacks:
		void
		
]]

--------
-- Header end
--------

cs.class 'Train' (function (this) 

	--[[
		Internal properties:
			Rbx::Model model
	]]

	function this:init (model)
		self.model = model
	
		--
		self.isMoving = false
		self.enabled = true
		local eventProp = cs.new 'EventPropagator' ("TextButton", "MouseButton1Down")
	
		--
		self.pointA = model["TrainUnit"].Train.MainBulk.ActualBase.Bric.Position
		self.pointB = model["TrainUnit@EndPos"].Train.MainBulk.ActualBase.Bric.Position
		model["TrainUnit@EndPos"]:Destroy()
		
		self.pointAControl = model["CallerUnit-Main"].TouchScreen.SurfaceGui
		self.pointBControl = model["CallerUnit-Island"].TouchScreen.SurfaceGui
		
		self.pointAControl["Error Message"]:Destroy()
		self.pointBControl["Error Message"]:Destroy()
		
		self.partList = Util.findAll(model.TrainUnit, "BasePart")
		self.trainBase = model.TrainUnit.Train.MainBulk.ActualBase.Bric
		
		self.currentPoint = self.pointA
		self:guiSetStatus(self.currentPoint)
		--
		eventProp:addObject(self.pointAControl.MainRegion.CallButton)
		eventProp:addObject(self.pointBControl.MainRegion.CallButton)
		
		eventProp.eventFired:Connect(function (player, obj)
			if self.isMoving or not self.enabled then
				return
			end
			
			wait(5)
			
			self:moveTrain(self.currentPoint == self.pointA and self.pointB or self.pointA)
		end)

		--
		self.pointAProgress = self.pointAControl.MainRegion.ProgressBar.Bar:GetChildren()
		self.pointBProgress = self.pointBControl.MainRegion.ProgressBar.Bar:GetChildren()
		
		table.sort(self.pointAProgress, function (a, b) return a.Position.X.Scale < b.Position.X.Scale end)
		table.sort(self.pointBProgress, function (a, b) return a.Position.X.Scale < b.Position.X.Scale end)
		
		self:guiSetPosition(self.pointA, 1)
	end
	
	function this.member:moveTrain(point)
		if self.isMoving or not self.enabled or self.currentPoint == point then 
			return
		end
		self.isMoving = true
		
		local welds = {}
		Util.Welding.addSuperList(welds)
		
		-- Create temporary part
		-- NOTE: This addresses an issue where first person camera will move
		-- the welded part with the camera locally for some reason.
		-- NOTE: May require FilteringEnabled for this to work properly. Untested.
		local moveWith = Instance.new("Part")
		moveWith.Name = "MoveWithTemporary"
		moveWith.Transparency = 1
		moveWith.CanCollide = false
		moveWith.Anchored = true
		moveWith.Parent = self.model
		moveWith.CFrame = self.model.Ref.CFrame
		
		local moveWith2 = moveWith:Clone()
		moveWith2.Parent = self.model
		moveWith.CFrame = self.model.Ref.CFrame
		
		-- Weld players to moveWith part
		local players = self:getPlayersInside()
		for _,v in next, players do
			if v.Character and v.Character:FindFirstChild"Torso" then
				Util.Welding.weld(v.Character.Torso, moveWith2, welds)
			end
		end
		Util.Welding.weld(moveWith2, moveWith, welds, "Motor")
		moveWith2.Anchored = false
		
		-- Weld train to base
		for _,v in next, self.partList do
			if v ~= self.trainBase then
				Util.Welding.weld(v, self.trainBase, welds)
				v.Anchored = false
			end
		end
		Util.Welding.weld(self.trainBase, self.model.Ref, welds, "Motor")
		self.trainBase.Anchored = false
		
		self:guiSetStatus(nil) -- moving
		
		-- Move reference part
		local diff = point.X - self.currentPoint.X
		local smooth = 1
		
		local change = Vector3.new( (diff > 0 and 1 or -1)/smooth, 0, 0)
		local steps = math.abs(diff*smooth) 
		for i=1, steps do
			self.model.Ref.CFrame = self.model.Ref.CFrame + change
			moveWith.CFrame = self.model.Ref.CFrame
			self:guiSetPosition(point, i / steps)			
			wait()
		end
		
		-- This is for the bug mentioned above. Camera forces players to end up
		-- far away or in weird places.
		local positions = {}
		for i,v in next, players do
			if v.Character and v.Character:FindFirstChild"Torso" then
				positions[v.Character.Torso] = v.Character.Torso.CFrame
			end
		end
		
		-- Remove welds, anchor elevator
		for _,v in next, self.partList do
			v.Anchored = true
		end
		
		Util.Welding.removeSuperList(welds)
		for i,v in next, welds do
			i:Destroy()
		end
		
		for i,v in next, positions do
			i.CFrame = v
		end
		
		moveWith:Destroy()
		moveWith2:Destroy()
		
		self.currentPoint = point
		self.isMoving = false
		self:guiSetStatus(self.currentPoint)
	end
	
	function this.member:guiSetStatus(point)
		local text
		if not point then
			if self.currentPoint == self.pointA then
				text = "In Transit: Base -> Island"
			else -- point B
				text = "In Transit: Island -> Base"
			end
		elseif point == self.pointA then
			text = "At Base"
			self.pointAControl.MainRegion.CallButton.Text = "Send"
			self.pointBControl.MainRegion.CallButton.Text = "Call"
		else -- point B
			text = "At Island"
			self.pointAControl.MainRegion.CallButton.Text = "Call"
			self.pointBControl.MainRegion.CallButton.Text = "Send"
		end

		self.pointAControl.MainRegion.ActState.Text = text
		self.pointBControl.MainRegion.ActState.Text = text
	end
	
	local _WHITE, _GREEN = Color3.new(1,1,1), Color3.new(0,1,0)
	function this.member:guiSetPosition(destination, percentage)
		local numPoints = #self.pointAProgress
		local point = math.floor((numPoints - 1) * percentage + 0.5) + 1

		if destination == self.pointB then
			point = numPoints - (point - 1)
		end
	
		if self.pointAProgress[point].BackgroundColor3 == _GREEN then
			return -- no updates needed
		end
	
		for _,v in next, self.pointAProgress do
			v.BackgroundColor3 = _WHITE
		end
		for _,v in next, self.pointBProgress do
			v.BackgroundColor3 = _WHITE
		end
		self.pointAProgress[point].BackgroundColor3 = _GREEN
		self.pointBProgress[point].BackgroundColor3 = _GREEN
	end
	
	function this.member:getPlayersInside()
		-- Create region
		local R3 = Util.getRegion3Around(self:getAdjustedRefCFrame(), Vector3.new(10, 4, 70))
		
		-- Get players
		return Util.getPlayersInRegion3(R3, self.model)
	end
	
	function this.member:getAdjustedRefCFrame()
		return self.trainBase.CFrame + Vector3.new(0,4,0)
	end
	
	function this.member:setEnabled(isEnabled)
		self.enabled = isEnabled and true or false
	end
	
	function this.member:isEnabled()
		return self.enabled
	end
	
	this.get.isMoving = true
	this.get.setEnabled = true
	this.get.isEnabled = true
end)

return false