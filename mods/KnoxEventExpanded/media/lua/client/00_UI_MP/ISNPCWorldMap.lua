if not isClient() or isServer() then return end

require "ISUI/Maps/ISWorldMap"

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)

function ISWorldMap:setShowNpcs(show)
	self.showNpcs = show
	setShowNpcs(show);
end

function ISWorldMap:onRightMouseUp(x, y)
    if self.symbolsUI:onRightMouseUpMap(x, y) then
		return true
	end
    local playerNum = 0
    local worldX = self.mapAPI:uiToWorldX(x, y)
	local worldY = self.mapAPI:uiToWorldY(x, y)
    local context = nil
    if #selectedGroupNps > 0 then
        context = ISContextMenu.get(playerNum, x + self:getAbsoluteX(), y + self:getAbsoluteY())
        context:addOption(getText("ContextMenu_KnoxEvent_Scavenge"), self, self.onScavengeNpc, worldX, worldY);
    end
	if not getDebug() and not (isClient() and (getAccessLevel() == "admin")) then
		return false
	end
	local playerObj = getSpecificPlayer(0)
	if not playerObj then return end -- Debug in main menu
	if context == nil then
        context = ISContextMenu.get(playerNum, x + self:getAbsoluteX(), y + self:getAbsoluteY())
    end

    local option = context:addOption("Show NPCs", self, function(self) self:setShowNpcs(not self.showNpcs) end)
	context:setOptionChecked(option, self.showNpcs)

	local option = context:addOption("Show Cell Grid", self, function(self) self:setShowCellGrid(not self.showCellGrid) end)
	context:setOptionChecked(option, self.showCellGrid)

	option = context:addOption("Show Tile Grid", self, function(self) self:setShowTileGrid(not self.showTileGrid) end)
	context:setOptionChecked(option, self.showTileGrid)

	self.hideUnvisitedAreas = self.mapAPI:getBoolean("HideUnvisited")
	option = context:addOption("Hide Unvisited Areas", self, function(self) self:setHideUnvisitedAreas(not self.hideUnvisitedAreas) end)
	context:setOptionChecked(option, self.hideUnvisitedAreas)

	option = context:addOption("Isometric", self, function(self) self:setIsometric(not self.isometric) end)
	context:setOptionChecked(option, self.isometric)

	-- DEV: Apply the style again after reloading ISMapDefinitions.lua
	option = context:addOption("Reapply Style", self,
		function(self)
			MapUtils.initDefaultStyleV1(self)
			MapUtils.overlayPaper(self)
		end)

	if getWorld():getMetaGrid():isValidChunk(worldX / 10, worldY / 10) then
        context:addOption("Spawn NPC", self, self.onSpawnNpc, worldX, worldY);
        context:addOption("Teleport Here", self, self.onTeleport, worldX, worldY);
        context:addOption("Get waypoints", self, self.onGetWaypoints, worldX, worldY);
        context:addOption("Add waypoint", self, self.onAddWaypoint, worldX, worldY);
        context:addOption("Remove waypoint", self, self.onRemoveWaypoint, worldX, worldY);
        context:addOption("Clear waypoint", self, self.onClearWaypoint, worldX, worldY);
	end
end

function ISWorldMap:onMoveNPC(worldX, worldY)
	-- TODO: Safe for later when sending Npcs to loot
    print("Moving NPC to " .. tostring(worldX) .. "," .. tostring(worldY))
	sendClientCommand("KnoxEventNpcControl", "NpcMove", {worldX=worldX,worldY=worldY})
end

function ISWorldMap:onSpawnNpc(worldX, worldY)
    print("Spawning NPC at " .. tostring(worldX) .. "," .. tostring(worldY))
	sendClientCommand("KnoxEventDebug", "NpcSpawn", {worldX=worldX,worldY=worldY})
end

function ISWorldMap:onScavengeNpc(worldX, worldY)
    print("Asking Npc to scavenge at " .. tostring(worldX) .. "," .. tostring(worldY))
	sendClientCommand("KnoxEventNpcRoamingControl", "NpcScavenge", {npcs=selectedGroupNps,centerX=worldX,centerY=worldY,length=40,ammo=lootAmmo,firstaid=lootFirstAid,food=lootFood,guns=lootGuns,materials=lootMaterials,tools=lootTools,water=lootWater,weapons=lootWeapons});
    if ISWorldMap_instance ~= nil then
        ISWorldMap_instance:close();
    end
end

function ISWorldMap:onGetWaypoints(worldX, worldY)
    print("Getting waypoints from server")
    sendClientCommand("KnoxEventDebug", "GetWaypoints", {})
end

function ISWorldMap:onAddWaypoint(worldX, worldY)
    print("Adding waypoint " .. tostring(worldX) .. "," .. tostring(worldY))
    sendClientCommand("KnoxEventDebug", "AddWaypoint", {worldX=worldX,worldY=worldY})
end

function ISWorldMap:onRemoveWaypoint(worldX, worldY)
    print("Removing waypoint " .. tostring(worldX) .. "," .. tostring(worldY))
    sendClientCommand("KnoxEventDebug", "RemoveWaypoint", {worldX=worldX,worldY=worldY})
end

function ISWorldMap:onClearWaypoint(worldX, worldY)
    print("Clearing current waypoint")
    sendClientCommand("KnoxEventDebug", "ClearWaypoint", {})
 end

function ISWorldMap:addSafehouse(worldX,  worldY)
    local symbolsAPI = self.mapAPI:getSymbolsAPI();
    local textureSymbol = symbolsAPI:addTexture("FaceDead", worldX, worldY)
    textureSymbol:setRGBA(0.0, 0.0, 0.5, 1.0);
    textureSymbol:setAnchor(0.5, 0.5);
    --textureSymbol:setScale(ISMap.SCALE * self.scale / 10);
end

WorldMapLootOverlayUI = ISPanel:derive("WorldMapLootOverlayUI")

function WorldMapLootOverlayUI:new()
	local width = NPCLOOTUI_ELEMENT_WIDTH
    local height = NPCLOOTUI_ELEMENT_HEIGHT * 8
    local x = width / 2
    local y = 3 * height / 2
	local o = {}
	o = ISPanel:new(x, y, width, height);
    setmetatable(o, self)
    self.__index = self
    self.showNpcs = false;
	o.x = x;
	o.y = y;
	o.background = true;
	o.backgroundColor = {r=0, g=0, b=0, a=0.5};
    o.borderColor = {r=0.4, g=0.4, b=0.4, a=1};
    o.width = width;
	o.height = height;
	o.anchorLeft = true;
	o.anchorRight = false;
	o.anchorTop = true;
	o.anchorBottom = false;
    o.moveWithMouse = false;
   return o
end

function WorldMapLootOverlayUI:prerender()
	if self.background then
		self:drawRectStatic(0, 0, self.width, self.height, self.backgroundColor.a, self.backgroundColor.r, self.backgroundColor.g, self.backgroundColor.b);
		self:drawRectBorderStatic(0, 0, self.width, self.height, self.borderColor.a, self.borderColor.r, self.borderColor.g, self.borderColor.b);
    end

    if lootAmmo then
        self:drawTextZoomed(getText("IGUI_KnoxEvent_Looting_Category_Ammo"), 3, 0 * NPCLOOTUI_ELEMENT_HEIGHT + 5, 1.0, 1.0, 1.0, 1.0, FONT_HGT_SMALL);
    else
        self:drawTextZoomed(getText("IGUI_KnoxEvent_Looting_Category_Ammo"), 3, 0 * NPCLOOTUI_ELEMENT_HEIGHT + 5, 1.0, 0.8, 0.1, 0.1, FONT_HGT_SMALL);
    end
    self:drawRectBorderStatic(0, 0, NPCLOOTUI_ELEMENT_WIDTH, NPCLOOTUI_ELEMENT_HEIGHT, self.borderColor.a, self.borderColor.r, self.borderColor.g, self.borderColor.b);

    if lootFirstAid then
        self:drawTextZoomed(getText("IGUI_KnoxEvent_Looting_Category_FirstAid"), 3, 1 * NPCLOOTUI_ELEMENT_HEIGHT + 5, 1.0, 1.0, 1.0, 1.0, FONT_HGT_SMALL);
    else
        self:drawTextZoomed(getText("IGUI_KnoxEvent_Looting_Category_FirstAid"), 3, 1 * NPCLOOTUI_ELEMENT_HEIGHT + 5, 1.0, 0.8, 0.1, 0.1, FONT_HGT_SMALL);
    end
    self:drawRectBorderStatic(0, 2 * NPCLOOTUI_ELEMENT_HEIGHT, NPCLOOTUI_ELEMENT_WIDTH, NPCLOOTUI_ELEMENT_HEIGHT, self.borderColor.a, self.borderColor.r, self.borderColor.g, self.borderColor.b);

    if lootFood then
        self:drawTextZoomed(getText("IGUI_KnoxEvent_Looting_Category_Food"), 3, 2 * NPCLOOTUI_ELEMENT_HEIGHT + 5, 1.0, 1.0, 1.0, 1.0, FONT_HGT_SMALL);
    else
        self:drawTextZoomed(getText("IGUI_KnoxEvent_Looting_Category_Food"), 3, 2 * NPCLOOTUI_ELEMENT_HEIGHT + 5, 1.0, 0.8, 0.1, 0.1, FONT_HGT_SMALL);
    end
    self:drawRectBorderStatic(0, 2 * NPCLOOTUI_ELEMENT_HEIGHT, NPCLOOTUI_ELEMENT_WIDTH, NPCLOOTUI_ELEMENT_HEIGHT, self.borderColor.a, self.borderColor.r, self.borderColor.g, self.borderColor.b);

    if lootGuns then
        self:drawTextZoomed(getText("IGUI_KnoxEvent_Looting_Category_Guns"), 3, 3 * NPCLOOTUI_ELEMENT_HEIGHT + 5, 1.0, 1.0, 1.0, 1.0, FONT_HGT_SMALL);
    else
        self:drawTextZoomed(getText("IGUI_KnoxEvent_Looting_Category_Guns"), 3, 3 * NPCLOOTUI_ELEMENT_HEIGHT + 5, 1.0, 0.8, 0.1, 0.1, FONT_HGT_SMALL);
    end
    self:drawRectBorderStatic(0, 3 * NPCLOOTUI_ELEMENT_HEIGHT, NPCLOOTUI_ELEMENT_WIDTH, NPCLOOTUI_ELEMENT_HEIGHT, self.borderColor.a, self.borderColor.r, self.borderColor.g, self.borderColor.b);

    if lootMaterials then
        self:drawTextZoomed(getText("IGUI_KnoxEvent_Looting_Category_Materials"), 3, 4 * NPCLOOTUI_ELEMENT_HEIGHT + 5, 1.0, 1.0, 1.0, 1.0, FONT_HGT_SMALL);
    else
        self:drawTextZoomed(getText("IGUI_KnoxEvent_Looting_Category_Materials"), 3, 4 * NPCLOOTUI_ELEMENT_HEIGHT + 5, 1.0, 0.8, 0.1, 0.1, FONT_HGT_SMALL);
    end
    self:drawRectBorderStatic(0, 4 * NPCLOOTUI_ELEMENT_HEIGHT, NPCLOOTUI_ELEMENT_WIDTH, NPCLOOTUI_ELEMENT_HEIGHT, self.borderColor.a, self.borderColor.r, self.borderColor.g, self.borderColor.b);

    if lootTools then
        self:drawTextZoomed(getText("IGUI_KnoxEvent_Looting_Category_Tools"), 3, 5 * NPCLOOTUI_ELEMENT_HEIGHT + 5, 1.0, 1.0, 1.0, 1.0, FONT_HGT_SMALL);
    else
        self:drawTextZoomed(getText("IGUI_KnoxEvent_Looting_Category_Tools"), 3, 5 * NPCLOOTUI_ELEMENT_HEIGHT + 5, 1.0, 0.8, 0.1, 0.1, FONT_HGT_SMALL);
    end
    self:drawRectBorderStatic(0, 5 * NPCLOOTUI_ELEMENT_HEIGHT, NPCLOOTUI_ELEMENT_WIDTH, NPCLOOTUI_ELEMENT_HEIGHT, self.borderColor.a, self.borderColor.r, self.borderColor.g, self.borderColor.b);

    if lootWater then
        self:drawTextZoomed(getText("IGUI_KnoxEvent_Looting_Category_Water"), 3, 6 * NPCLOOTUI_ELEMENT_HEIGHT + 5, 1.0, 1.0, 1.0, 1.0, FONT_HGT_SMALL);
    else
        self:drawTextZoomed(getText("IGUI_KnoxEvent_Looting_Category_Water"), 3, 6 * NPCLOOTUI_ELEMENT_HEIGHT + 5, 1.0, 0.8, 0.1, 0.1, FONT_HGT_SMALL);
    end
    self:drawRectBorderStatic(0, 6 * NPCLOOTUI_ELEMENT_HEIGHT, NPCLOOTUI_ELEMENT_WIDTH, NPCLOOTUI_ELEMENT_HEIGHT, self.borderColor.a, self.borderColor.r, self.borderColor.g, self.borderColor.b);

    if lootWeapons then
        self:drawTextZoomed(getText("IGUI_KnoxEvent_Looting_Category_Weapons"), 3, 7 * NPCLOOTUI_ELEMENT_HEIGHT + 5, 1.0, 1.0, 1.0, 1.0, FONT_HGT_SMALL);
    else
        self:drawTextZoomed(getText("IGUI_KnoxEvent_Looting_Category_Weapons"), 3, 7 * NPCLOOTUI_ELEMENT_HEIGHT + 5, 1.0, 0.8, 0.1, 0.1, FONT_HGT_SMALL);
    end
    self:drawRectBorderStatic(0, 7 * NPCLOOTUI_ELEMENT_HEIGHT, NPCLOOTUI_ELEMENT_WIDTH, NPCLOOTUI_ELEMENT_HEIGHT, self.borderColor.a, self.borderColor.r, self.borderColor.g, self.borderColor.b);
end

function WorldMapLootOverlayUI:onMouseUp(x, y)
    print("Got coords " .. tostring(x) .. ", " .. tostring(y));
    local lootIndex = math.floor(y/NPCLOOTUI_ELEMENT_HEIGHT);
    if lootIndex == 0 then
        lootAmmo = not lootAmmo;
    elseif lootIndex == 1 then
        lootFirstAid = not lootFirstAid;
    elseif lootIndex == 2 then
        lootFood = not lootFood;
    elseif lootIndex == 3 then
        lootGuns = not lootGuns;
    elseif lootIndex == 4 then
        lootMaterials = not lootMaterials;
    elseif lootIndex == 5 then
        lootTools = not lootTools;
    elseif lootIndex == 6 then
        lootWater = not lootWater;
    elseif lootIndex == 7 then
        lootWeapons = not lootWeapons;
    end
end

WorldMapNpcOverlayUI = ISPanel:derive("WorldMapNpcOverlayUI")

function WorldMapNpcOverlayUI:new()
	local width = NPCUI_ELEMENT_WIDTH * 8
    local height = NPCUI_ELEMENT_HEIGHT
    local x = width / 2
    local y = height / 2
	local o = {}
	o = ISPanel:new(x, y, width, height);
    setmetatable(o, self)
    self.__index = self
	o.x = x;
	o.y = y;
	o.background = true;
	o.backgroundColor = {r=0, g=0, b=0, a=0.5};
    o.borderColor = {r=0.4, g=0.4, b=0.4, a=1};
    o.width = width;
	o.height = height;
	o.anchorLeft = true;
	o.anchorRight = false;
	o.anchorTop = true;
	o.anchorBottom = false;
    o.moveWithMouse = false;
   return o
end

function WorldMapNpcOverlayUI:prerender()
	if self.background then
		self:drawRectStatic(0, 0, self.width, self.height, self.backgroundColor.a, self.backgroundColor.r, self.backgroundColor.g, self.backgroundColor.b);
		self:drawRectBorderStatic(0, 0, self.width, self.height, self.borderColor.a, self.borderColor.r, self.borderColor.g, self.borderColor.b);
	end
    local tmpX = 0;
    local playerData = getPlayerData(0);
    local overlayUI = playerData.npcOverlayUI;
    for i=0, overlayUI.npcListLen-1 do
        local w = NPCUI_ELEMENT_WIDTH;
        local h = NPCUI_ELEMENT_HEIGHT;
        local npcData = overlayUI.npcList[i];
        local splitPos, splitEnd = string.find(npcData.name, ' ', 1, true);
        local npc_id = tonumber(npcData["id"]);
        local name = string.sub(npcData.name, 0, splitPos);
        local task = npcData.task;
        local subtask = npcData.subtask;
        if isNpcSelected(npc_id) then
            if self.javaObject ~= nil then
                self.javaObject:DrawTextureScaledColor(nil, tmpX-self:getXScroll(), -self:getYScroll(), BORDER_THICKNESS, h, 255, 0, 0, 255);
                self.javaObject:DrawTextureScaledColor(nil, tmpX-self:getXScroll()+BORDER_THICKNESS, -self:getYScroll(), w-2, BORDER_THICKNESS, 255, 0, 0, 255);
                self.javaObject:DrawTextureScaledColor(nil, tmpX-self:getXScroll()+w-BORDER_THICKNESS, -self:getYScroll(), BORDER_THICKNESS, h, 255, 0, 0, 255);
                self.javaObject:DrawTextureScaledColor(nil, tmpX-self:getXScroll()+BORDER_THICKNESS, -self:getYScroll()+h-BORDER_THICKNESS, w-2, BORDER_THICKNESS, 255, 0, 0, 255);
            end
        else
            self:drawRectBorderStatic(tmpX, 0, w, h, self.borderColor.a, self.borderColor.r, self.borderColor.g, self.borderColor.b);
        end
        self:drawTextZoomed(name, tmpX+3, 3, 1.0, 1.0, 1.0, 1.0, FONT_HGT_SMALL);
        self:drawTextZoomed(task, tmpX+3, 20, 1.0, 1.0, 1.0, 1.0, FONT_HGT_SMALL);
        if subtask ~= nil then
            self:drawTextZoomed(subtask, tmpX+3, 37, 1.0, 1.0, 1.0, 1.0, FONT_HGT_SMALL);
        end
        tmpX = tmpX + NPCUI_ELEMENT_WIDTH;
    end
end

function WorldMapNpcOverlayUI:onMouseUp(x, y)
    print("Got coords " .. tostring(x) .. ", " .. tostring(y));
    local npc_index = math.floor(x/NPCUI_ELEMENT_WIDTH);
    local playerData = getPlayerData(0);
    local overlayUI = playerData.npcOverlayUI;
    if overlayUI.npcList[npc_index] ~= nil then
        local npc_id = tonumber(overlayUI.npcList[npc_index]["id"]);
        print("Selected npc with id " .. tostring(npc_id));
        if #selectedGroupNps == 0 then
            selectedGroupNps = {}
            table.insert(selectedGroupNps, npc_id)
        elseif #selectedGroupNps == 1 then
            if isNpcSelected(npc_id) then
                selectedGroupNps = {}
            else
                if isShiftKeyDown() then
                    table.insert(selectedGroupNps, npc_id)
                else
                    selectedGroupNps = {}
                    table.insert(selectedGroupNps, npc_id)
                end
            end
        else
            if isNpcSelected(npc_id) then
                if isShiftKeyDown() then
                    local tmpSelectedGroupNps = {}
                    for _, npc in ipairs(selectedGroupNps) do
                        if npc ~= npc_id then
                            table.insert(tmpSelectedGroupNps, npc)
                        end
                    end
                    selectedGroupNps = tmpSelectedGroupNps
                else
                    selectedGroupNps = {}
                    table.insert(selectedGroupNps, npc_id)
                end
            else
                if isShiftKeyDown() then
                    table.insert(selectedGroupNps, npc_id)
                else
                    selectedGroupNps = {}
                    table.insert(selectedGroupNps, npc_id)
                end
            end
        end
    end
end

ISWorldMap.createChildren_old = ISWorldMap.createChildren;
ISWorldMap.createChildren = function(self)
    self:createChildren_old();

    self.worldMapNpcOverlayUI = WorldMapNpcOverlayUI:new();
    self:addChild(self.worldMapNpcOverlayUI);

    self.worldMapLootOverlayUI = WorldMapLootOverlayUI:new();
    self:addChild(self.worldMapLootOverlayUI);
end
