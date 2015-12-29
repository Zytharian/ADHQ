-- Services
local projectRoot = game:GetService("ServerScriptService")
local RS = game:GetService("ReplicatedStorage")

-- Includes
local cs = require(projectRoot.Modules.ClassSystem)
local LEnums = require(projectRoot.Modules.Enums)
local Util = require(projectRoot.Modules.Utilities)

-- Configuration
local DEBUG = false
local replicatedAlarmFlagName = "FLAG_AlarmPlaying"

--[[
	init(Rbx::Model model, Network network)

	Properties:
		void

	Methods:
		void

	Events:
		void

	Callbacks:
		void

]]

--------
-- Header end
--------

cs.class 'Override' (function (this)

	--[[
		Internal properties:
			Rbx::Model model
			Network network
			EventPropagator propagator
			boolean isUp
			boolean debounce
	]]

	function this:init (model, network)
		self.model = model
		self.network = network
		self.propagator = cs.new 'EventPropagator'("ClickDetector", "MouseClick")
		self.isUp = true
		self.maxDistanceFromButton = 5
		self.debounce = false

		local CD = Instance.new("ClickDetector", model.Button)
		CD.MaxActivationDistance = 8
		self.propagator:addObject(CD)

		self.propagator.eventFired:Connect(function (player, object)
			if Util.playerAlive(player) and _G.Access.IsPrivilegedUser(player) then
				self:resetNetwork()
			end
		end)

		self.model.PrimaryPart = self.model.Button

		-- Move below
		self:move()

		-- Poll player movements
		coroutine.wrap(function() self:pollPlayerMovements() end)()
	end

	function this.member:move()
		local smooth = 3
		local refNum = 3 -- studs the override is tall

		local CF = Vector3.new(0,1/smooth * (self.isUp and -1 or 1),0)
		for i=1, refNum * smooth do
			self.model:SetPrimaryPartCFrame(self.model.PrimaryPart.CFrame + CF)
			wait()
		end
		
		self.isUp = not self.isUp
	end

	function this.member:resetNetwork()
		if self.debounce then
			return 
		end
		self.debounce = true
		
		self.network.lockoutEnabled = true
		self.network:setMode(LEnums.SectionMode:GetItem"Unpowered")
		
		-- Turn off the alarm if applicable
		if RS:FindFirstChild(replicatedAlarmFlagName) then
			RS[replicatedAlarmFlagName].Value = false
		end
		
		self.model.Button.BrickColor = BrickColor.Red()
		for i,v in next, self.model:GetChildren() do
			if v.Name == "Glow" then
				v.BrickColor = BrickColor.Red()
			end
		end
		
		wait(8)
		
		local lightNormal = Color3.new(1, 248/255, 220/255)
		for _,v in next, self.network:getSections() do
			v:setLightingColor(lightNormal)
		end
		self.network:setMode(LEnums.SectionMode:GetItem"Normal")
		if self.network:getTrain() ~= nil then
			self.network:getTrain():setEnabled(true)
		end
		if self.network:getPower() ~= nil then
			self.network:getPower():endCountdown()
		end
		
		self.model.Button.BrickColor = BrickColor.Blue()
		for i,v in next, self.model:GetChildren() do
			if v.Name == "Glow" then
				v.BrickColor = BrickColor.new("Deep blue")
			end
		end
		
		self.debounce = false
	end

	function this.member:pollPlayerMovements()
		while true do
			wait(1)
			
			local playerNear = false
			for i,v in next, game.Players:GetPlayers() do
				if Util.playerAlive(v) and _G.Access.IsPrivilegedUser(v) then
					if (v.Character.Torso.Position - self.model.Button.Position).magnitude < self.maxDistanceFromButton then
						playerNear = true
						break
					end
				end
			end
			
			if not self.debounce then
				if playerNear and not self.isUp then
					self:move()
				elseif not playerNear and self.isUp then
					self:move()
				end
			end
			
		end
	end
	
end)

return false