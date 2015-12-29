-- Zytharian (roblox: Legend26)

-- Services
local projectRoot = game:GetService("ServerScriptService")

-- Includes
local cs = require(projectRoot.Modules.ClassSystem)

-- Configuration
local DEBUG = false

--[[
	init(string name, table sectionList, table transporterList)

	Properties:
		readonly string name
		bool isEnabled
		
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

cs.class 'Rings' (function (this) 

	--[[
		Internal properties:
			Rbx::Model model
			string address
	]]

	function this:init (model)
		self.model = model
		self.name = model.Name
		
		self.address = model.Rings.Address.Value
		
		self:setEnabled(true)
	end
	
	function this.member:setEnabled(value)
		if value then
			self.model.Rings.Address.Value = self.address
			self.model.Panel.RingDisabled.Value = false
		else
			self.model.Rings.Address.Value = ""
			self.model.Panel.RingDisabled.Value = true
		end
		
		self.isEnabled = value
	end
	
	-- public properties
	this.get.name = true
	this.get.isEnabled = true
	
	function this.set:isEnabled(property, value)
		if type(value) ~= "boolean" then
			error("isEnabled expects a boolean, got " .. tostring(value))
		end
		
		self:setEnabled(value)
	end
end)

return false