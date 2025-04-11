if not isClient() or isServer() then return end

require "DebugUIs/DebugMenu/ISDebugMenu"

KnoxEventAdventureDebugWindow = ISPanel:derive("KnoxEventAdventureDebugWindow")

local function disableAllDebug()
	sendClientCommand("KnoxEventDebug", "DisableAllDebug", {})
end

local function sendSpawnNpc()
	print("Sending spawn NPC")
	sendClientCommand("KnoxEventDebug", "SpawnNpc", {});
end

local function sendSpawnGunNpc()
	print("Sending spawn gun NPC")
	sendClientCommand("KnoxEventDebug", "SpawnGunNpc", {});
end

local function sendSpawnNpcGroup()
	print("Sending trigger checkpoint attack event")
	sendClientCommand("KnoxEventDebug", "SpawnNpcGroup", {})
end

local function sendTriggerSafehouseEvent()
	print("Sending trigger checkpoint attack event")
	sendClientCommand("KnoxEventDebug", "SafehouseEvent", {})
end

local function sendNpcDriverTest()
	print("Sending trigger Npc Driver Test")
	sendClientCommand("KnoxEventDebug", "NpcDriverTest", {})
end

local function sendPlaceHolder1()
	print("Sending trigger debug placeholder 1")
	sendClientCommand("KnoxEventDebug", "PlaceHolder1", {})
end

local function sendPlaceHolder2()
	print("Sending trigger debug placeholder 2")
	sendClientCommand("KnoxEventDebug", "PlaceHolder2", {})
end

local function sendPlaceHolder3()
	print("Sending trigger debug placeholder 3")
	sendClientCommand("KnoxEventDebug", "PlaceHolder3", {})
end

local function sendLoadWaypoints()
       print("Sending LoadWaypoints")
       sendClientCommand("KnoxEventDebug", "LoadWaypoints", {})
end

local function sendExportWaypoints()
       print("Sending ExportWaypoints")
       sendClientCommand("KnoxEventDebug", "ExportWaypoints", {})
end

function KnoxEventAdventureDebugWindow:initialise()
	ISPanel.initialise(self)

	local padding = 10
	local yOffset = 4

	local y = padding+5

	local w = self.width/2-(padding*1.5)
	local h = 18

	-- Setup disable all debug button
	local disableAllDebugButton = ISButton:new(10, 15, w, h, "Disable all debug", nil, function() disableAllDebug() end)
	self:addChild(disableAllDebugButton)
	-- Setup disable all debug button
	local spawnGunNpc = ISButton:new(self.width - w - padding, y, w, h, "Spawn Gun Npc", nil, function() spawnGunNpc() end)
	self:addChild(spawnGunNpc)

	y = y + h;
	-- Setup spawn NPC button
	local spawnNpcButton = ISButton:new(10, y, w, h, "Spawn Npcs", nil, function() sendSpawnNpc() end)
	self:addChild(spawnNpcButton)
	-- Setup spawn npc group button
	local spawnNpcGroupButton = ISButton:new(self.width - w - padding, y, w, h, "Spawn NPC group", nil, function() sendSpawnNpcGroup() end)
	self:addChild(spawnNpcGroupButton)

	y = y + h;
	-- Setup trigger safehouse event button
	local triggerSafehouseEvent = ISButton:new(10, y, w, h, "Safehouse event", nil, function() sendTriggerSafehouseEvent() end)
	self:addChild(triggerSafehouseEvent)

	-- Setup extra debug placeholder 1
	local placeHolder1 = ISButton:new(self.width - w - padding, y, w, h, "Placeholder 1", nil, function() sendPlaceHolder1() end)
	self:addChild(placeHolder1)

	y = y + h;
	-- Setup extra debug placeholder 2
	local placeHolder2 = ISButton:new(10, y, w, h, "Placeholder 2", nil, function() sendPlaceHolder2() end)
	self:addChild(placeHolder2)

	-- Setup extra debug placeholder 3
	local placeHolder3 = ISButton:new(self.width - w - padding, y, w, h, "Placeholder 3", nil, function() sendPlaceHolder3() end)
	self:addChild(placeHolder3)

	y = y + h;
	-- Setup extra debug placeholder 1
	local waypointLoad = ISButton:new(10, y, w, h, "Load Waypoints", nil, function() sendLoadWaypoints() end)
	self:addChild(waypointLoad)

	-- Setup extra debug placeholder 2
	local waypointExport = ISButton:new(self.width - w - padding, y, w, h, "Export waypoints", nil, function() sendExportWaypoints() end)
	self:addChild(waypointExport)

	local newWindowHeight = y + (padding*4) + h
	self:setHeight(newWindowHeight)

	local closeButton = ISButton:new(0, newWindowHeight-padding-h, self.width, h, "Close", nil, function() self:close() end)
	self:addChild(closeButton)
end

local function KnoxEventAdventureOpenPanel()
	local x = ISDebugMenu.instance:getX()+ISDebugMenu.instance:getWidth()+5
	local y = ISDebugMenu.instance:getY()

	if not KnoxEventAdventureDebugWindow.instance then
		KnoxEventAdventureDebugWindow.instance = KnoxEventAdventureDebugWindow:new(x, y, 550, 200)
		KnoxEventAdventureDebugWindow.instance:initialise()
		KnoxEventAdventureDebugWindow.instance:addToUIManager()
		KnoxEventAdventureDebugWindow.instance:setVisible(true)
		return
	end

	if KnoxEventAdventureDebugWindow.instance:getIsVisible() then
		KnoxEventAdventureDebugWindow.instance:setVisible(false)
	else
		KnoxEventAdventureDebugWindow.instance:setVisible(true)
		KnoxEventAdventureDebugWindow.instance:setX(x)
		KnoxEventAdventureDebugWindow.instance:setY(y)
	end
end

local ISDebugMenu_setupButtons = ISDebugMenu.setupButtons
function ISDebugMenu:setupButtons()
	self:addButtonInfo("Knox Event Debug", function() KnoxEventAdventureOpenPanel() end, "MAIN")
	ISDebugMenu_setupButtons(self)
end