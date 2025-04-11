if isClient() or isServer() then return end

require "DebugUIs/DebugMenu/ISDebugMenu"

KnoxEventAdventureDebugWindow = ISPanel:derive("KnoxEventAdventureDebugWindow")

local function disableAllDebug()
	
end

local function spawnGunNpc()
	print("Spawning gun Npc")
	local player = getSpecificPlayer(0);
	local square = player:getSquare();
	local npc = KnoxEventNpcAPI.instance:spawnNpc("SurvivorNpc", square:getX(), square:getY());
	local gun = npc:getInventory():AddItem("Base.AssaultRifle");
	npc:setPrimaryHandItem(gun);
	npc:setSecondaryHandItem(gun);
	npc:setPreferredWeapon(gun);
end

local function sendSpawnNpc()
	print("Spawning Npc")
	local player = getSpecificPlayer(0);
	local square = player:getSquare();
	local npc = KnoxEventNpcAPI.instance:spawnNpc("SurvivorNpc", square:getX(), square:getY());
end

local function sendSpawnNpcGroup()
	print("Sending trigger checkpoint attack event")
end

local function sendTriggerSafehouseEvent()
	local player = getPlayer();
	doSafehouseAttack(player);
end

local function debugPlaceholder1()
end

local function debugCurfewStart()
	startCurfewPatrols();
end

local function debugCurfewStop()
	endCurfewPatrols();
end

local function sendLoadWaypoints()
    print("Sending LoadWaypoints")
end

local function sendExportWaypoints()
       print("Sending ExportWaypoints")
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

	-- Setup placeholder NPC driving vehicle button
	local placeholder1Btn = ISButton:new(self.width - w - padding, y, w, h, "Placeholder 1", nil, function() debugPlaceholder1() end)
	self:addChild(placeholder1Btn)

	y = y + h;
	-- Setup extra debug placeholder 1
	local curfewStartBtn = ISButton:new(10, y, w, h, "Start curfew", nil, function() debugCurfewStart() end)
	self:addChild(curfewStartBtn)

	-- Setup extra debug placeholder 2
	local curfewStopBtn = ISButton:new(self.width - w - padding, y, w, h, "Stop curfew", nil, function() debugCurfewStop() end)
	self:addChild(curfewStopBtn)

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