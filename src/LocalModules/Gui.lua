-- Zytharian (roblox: Legend26)

-- Services
local replicated = game:GetService("ReplicatedStorage")

-- Includes
local CEnums = require(replicated.CommandEnums)

-- Exported object
local GUI = {}

--------
-- Header end
--------

local netModel = workspace["1_HQ_Network"]
local savedGui = script.ConsoleGui

GUI.createSignaler = (function ()
	local this = {}
	local connections = {}
	
	this.connect = (function (f)
		table.insert(connections, f)
	end)
	
	this.fire = (function (...)
		for _,v in next, connections do
			v(...)
		end
	end)
	
	return this
end)

GUI.createGuiView = (function (player)
	local this = {}
	local tabData = {}
	
	local gui = savedGui:Clone()
	gui.Parent = player.PlayerGui
	
	gui.Screen.InnerTab:ClearAllChildren()
	gui.Screen.OuterTab:ClearAllChildren()
	gui.Screen.Screen:ClearAllChildren()
	
	local currentInnerFrame
	local currentOuterButton
	
	local currentInnerButton
	local currentScreenFrame
	
	local activeTextColor = Color3.new(1, 170/255, 0)
	local inactiveTextColor = Color3.new(0, 170/255, 1)
	
	local green = Color3.new(0, 170/255, 0)
	local red =  Color3.new(1, 0, 0)
	
	local viewTypes = {
		Section = 1;
		Toggle = 2;
	}
	
	-- Interface	
	this.setMouseoverInteract = (function (visible, x, y)
		gui.Interact.Visible = visible
		if x and y then
			gui.Interact.Position = UDim2.new(0, x, 0, y)
		end
	end)
	
	this.openScreen = (function ()
		if this.isScreenOpen() then
			error("Screen already open")
		end
		
		gui.Screen.Visible = true
		gui.Status.Visible = true
	end)
	
	this.closeScreen = (function ()
		if not this.isScreenOpen() then
			error("Screen already closed")
		end
		
		gui.Screen.Visible = false
		gui.Status.Visible = false

		gui.Screen.InnerTab:ClearAllChildren()
		gui.Screen.OuterTab:ClearAllChildren()
		gui.Screen.Screen:ClearAllChildren()
		tabData = {}
	end)
	
	this.isScreenOpen = (function ()
		return gui.Screen.Visible
	end)
	
	this.setStatus = (function (text)
		gui.Status.Text = text
	end)

	this.createOuterTab = (function (name)
		local frame = Instance.new("ScrollingFrame", gui.Screen.InnerTab)
		frame.Size = UDim2.new(1,0,1,0)
		frame.BackgroundTransparency = 1 
		frame.Visible = false
		
		local id = #tabData + 1
		tabData[id] = {frame = frame, name = name}
		
		local tab = gui.Screen.TabTemplate:Clone()
		tab.Parent = gui.Screen.OuterTab
		tab.Text = "|||" .. name
		tab.Position = UDim2.new(0,0,0, tab.Size.Y.Offset*(id - 1))
		tab.Visible = true
		
		tab.MouseButton1Down:connect(function ()
			if currentInnerFrame then
				currentInnerFrame.Visible = false
				currentOuterButton.TextColor3 = inactiveTextColor
			end
			
			if currentScreenFrame then
				currentScreenFrame.Visible = false
				currentInnerButton.TextColor3 = inactiveTextColor
			end
			
			frame.Visible = true
			tab.TextColor3 = activeTextColor
			currentInnerFrame = frame
			currentOuterButton = tab
		end)
		
		return id
	end)
	
	this.createInnerTab = (function (name, outerId)
		local frame = Instance.new("ScrollingFrame", gui.Screen.Screen)
		frame.Size = UDim2.new(1,0,1,0)
		frame.BackgroundTransparency = 1 
		frame.Visible = false
		
		local id = #tabData[outerId] + 1
		tabData[outerId][id] = { frame = frame, name = name }
		
		local tab = gui.Screen.TabTemplate:Clone()
		tab.Parent = tabData[outerId].frame
		tab.Text = "|||" .. name
		tab.Position = UDim2.new(0,0,0, tab.Size.Y.Offset*(id - 1))
		tab.Visible = true
		tabData[outerId].frame.CanvasSize = UDim2.new(0, 0, 0, tabData[outerId].frame.CanvasSize.Y.Offset + 30)
		
		tab.MouseButton1Down:connect(function ()
			if currentScreenFrame then
				currentScreenFrame.Visible = false
				currentInnerButton.TextColor3 = inactiveTextColor
			end
			
			frame.Visible = true
			tab.TextColor3 = activeTextColor
			currentScreenFrame = frame
			currentInnerButton = tab
		end)
		
		return id
	end)
	
	this.addHeader = (function (text, outerId, innerId)
		local dat = tabData[outerId][innerId]
		local screen = dat.frame
		local template = gui.Screen.SectionTemplate:Clone()
		
		template.Text = text
		template.Position = UDim2.new(0, 0, 0, #dat * 30)
		template.Visible = true
		template.Parent = screen
		
		table.insert(dat, {screenType = viewTypes.Section, textLabel = template})
		
		screen.CanvasSize = UDim2.new(0, 0, 0, screen.CanvasSize.Y.Offset + 30)
	end)
	
	this.addToggle = (function (text, outerId, innerId, currentState, attemptChange, onState, offState)
		local dat = tabData[outerId][innerId]
		local screen = dat.frame
		local template = gui.Screen.ToggleTemplate:Clone()
		
		onState = onState or "Online"
		offState = offState or "Offline"
		currentState = currentState or false
		
		template.TextLabel.Text = text
		template.Position = UDim2.new(0, 0, 0, #dat * 30)
		template.Visible = true
		template.Parent = screen
		
		template.TextButton.MouseButton1Down:connect(function ()
			local newState = not currentState
			local success = attemptChange(newState)
			
			if not success or currentState == newState then
				return 
			end
			
			-- Changing something may close the screen (ex. unpowering current console)
			if gui.Screen.Visible then
				currentState = newState
				template.TextButton.Text = currentState and onState or offState
				template.TextButton.TextColor3 = currentState and green or red
			end
		end)
		
		local changeState = (function (newState)
			currentState = newState
			template.TextButton.Text = currentState and onState or offState
			template.TextButton.TextColor3 = currentState and green or red
		end)
		
		template.TextButton.Text = currentState and onState or offState
		template.TextButton.TextColor3 = currentState and green or red
		
		table.insert(dat, {screenType = viewTypes.Toggle; changeState = changeState})
		
		screen.CanvasSize = UDim2.new(0, 0, 0, screen.CanvasSize.Y.Offset + 30)
	end)
	
	this.changeState = (function (outerId, innerId, index, newState)
		local dat = tabData[outerId][innerId]
		
		if dat and dat.screenType == viewTypes.Section then
			dat.textLabel.Text = newState
		elseif dat and dat[index].screenType == viewTypes.Toggle then
			dat[index].changeState(newState)
		elseif not dat and tabData[outerId][1][index] == viewTypes.Toggle then
			tabData[outerId][1][index].changeState(newState)
		end
	end)
	
	this.getOuterIdByName = (function (name)
		for id, val in next, tabData do
			if val.name == name then
				return id
			end
		end
		
		print("Bad outer name: " .. tostring(name))
		return nil
	end)
	
	this.getInnerIdByName = (function (outerId, name)
		local tab = tabData[outerId]
		for i=1, #tab do
			if tab[i].name == name then
				return i
			end
		end
		
		print("Bad inner name: " .. tostring(name))
		return nil
	end)
	
	this.closedPressed = GUI.createSignaler()
	
	-- Initial event hooks
	gui.Screen.Close.MouseButton1Down:connect(function ()
		this.closedPressed.fire()
	end)
	
	return this
end)

GUI.createGuiModel = (function (view, player)
	local this = {}
	
	local interacting = false
	local currentNetId = 0
	local currentConsoleId = 0
	
	local constructScreen = (function (outId, innerId, pageDat, consoleId, handler, innerName)
		for i,v in next, pageDat do
			if v[1] == CEnums.ScreenType.Section then
				view.addHeader(v[2], outId, innerId)
			elseif v[1] == CEnums.ScreenType.OnlineOffline then
				view.addToggle(v[2], outId, innerId, v[3], function (newState)
					return replicated.CON_F_RunCommand:InvokeServer(
						consoleId, 
						handler, 
						{tab = innerName, index = i, newState = newState}
					)
				end, v[4], v[5])
			end
		end
	end)
	
	local updateConnection
	local networkUpdateHandler = (function (handler, networkId, dat)
		if currentNetId ~= networkId then
			return
		end
		
		if handler then
			local outId = view.getOuterIdByName(handler)
			view.changeState(outId, view.getInnerIdByName(outId, dat.tab), dat.index, dat.newState)
		else 
			-- lockout; dat = nil
			if not dat then
				local consoleId = currentConsoleId
				this.stopInteract()
				this.interact(consoleId)
				return
			end
		
			-- unpowered; dat = table of console ids that have been disabled in this case
			for _,id in next, dat do
				if id == currentConsoleId then
					local consoleId = currentConsoleId
					this.stopInteract()
					this.interact(consoleId)
					return
				end
			end
		end
	end)
	
	this.isInteracting = (function ()
		return interacting
	end)
	
	this.interact = (function (id)
		if interacting then
			error("Already interacting")
		end
		interacting = true
		currentConsoleId = id
	
		-- Get batch info
		local remote = replicated:FindFirstChild"CON_F_GetBatchInformation"
		if not remote then
			error("No CON_F_GetBatchInformation")
		end
		
		local data, consoleType, networkId, status = remote:InvokeServer(id)
		
		if not data or not consoleType or not networkId then
			if status then
				view.setStatus("ERROR: " .. status)
			else
				view.setStatus("ERROR: No status known")
			end
			view.openScreen()
			return
		end
		
		currentNetId = networkId
		
		-- Do stuff with batch info
		for outName, inDat in next, data do
			local outId = view.createOuterTab(outName)
			for inName, pageDat in next, inDat do
				local inId = view.createInnerTab(inName, outId)
				
				-- Create others and hook events
				constructScreen(outId, inId, pageDat, id, outName, inName)
			end
		end
		
		updateConnection = replicated.CON_E_NetworkUpdate.OnClientEvent:connect(networkUpdateHandler)
		
		local statusString = "ConsoleType: " .. consoleType .. "; NetId: " .. currentNetId .. "; ConsoleId: " .. currentConsoleId
		if status then
			statusString = statusString .. "; Status: " .. status
		end
		view.setStatus(statusString)
		
		if view.isScreenOpen() then
			print("WARNING: Screen already open.")
			return
		end
		
		view.openScreen()
	end)
	
	this.stopInteract = (function ()
		if not interacting then
			error("Not interacting")
		end
		
		view.closeScreen()
		
		if updateConnection then
			updateConnection:disconnect()
			updateConnection = nil
		end
		currentNetId = 0
		
		interacting = false
	end)
	
	view.closedPressed.connect(function ()
		if interacting then
			this.stopInteract()
		end
	end)
	
	return this
end)

GUI.createGuiManager = (function (model, view, player)
	local this = {}
	
	this.beginConsoleInteraction = (function (id)
		model.interact(id)
	end)
	
	this.endConsoleInteraction = (function ()
		model.stopInteract()
	end)
	
	this.setMouseoverInteract = (function (visible, x, y)
		view.setMouseoverInteract(visible, x, y)
	end)
	
	this.interactingWithConsole = (function ()
		return model.isInteracting()
	end)

	
	return this
end)

GUI.createGui = (function (player)
	local view = GUI.createGuiView(player)
	local model = GUI.createGuiModel(view, player)
	local manager = GUI.createGuiManager(model, view, player)
	
	return manager
end)

return GUI