if isClient() or isServer() then return end

require "ISUI/ISPanel"

NpcOverlayUI = ISPanel:derive("NpcOverlayUI");

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
NPCUI_ELEMENT_WIDTH = 64
NPCUI_ELEMENT_HEIGHT = 60
NPCLOOTUI_ELEMENT_WIDTH = 60
NPCLOOTUI_ELEMENT_HEIGHT = 25
BORDER_THICKNESS = 3

lootAmmo = true;
lootFirstAid = true;
lootFood = true;
lootGuns = true;
lootMaterials = true;
lootTools = true;
lootWater = true;
lootWeapons = true;

selectedGroupNps = {}

function NpcOverlayUI:initialise()
	ISPanel.initialise(self);
end

function isNpcSelected(npc_id)
    for _, npc in ipairs(selectedGroupNps) do
        if npc == npc_id then
            return true;
        end
    end
    return false;
end

function NpcOverlayUI:prerender()
	if self.background then
		self:drawRectStatic(0, 0, self.width, self.height, self.backgroundColor.a, self.backgroundColor.r, self.backgroundColor.g, self.backgroundColor.b);
		self:drawRectBorderStatic(0, 0, self.width, self.height, self.borderColor.a, self.borderColor.r, self.borderColor.g, self.borderColor.b);
	end
    if getPlayer() == nil or getPlayer():isDead() then
        return;
    end
    --print("NPCOverlayUI: NpcListLen = " .. tostring(self.npcListLen));
    local tmpY = 0;
    local player = getPlayer();
    local group = player:getGroup();
    if group then
        local npcList = group:getGroupMembers();
        local i = 0

        while i < npcList:size() do
            local npc = npcList:get(i);
            local name = npc:getForname();
            local task = npc:getGoalPretty();
            local subtask = npc:getSubGoalPretty();
            if isNpcSelected(npc) then
                if self.javaObject ~= nil then
                    local w = self.width;
                    local h = NPCUI_ELEMENT_HEIGHT;
                    self.javaObject:DrawTextureScaledColor(nil, -self:getXScroll(), tmpY-self:getYScroll(), BORDER_THICKNESS, h, 255, 0, 0, 255);
                    self.javaObject:DrawTextureScaledColor(nil, -self:getXScroll()+BORDER_THICKNESS, tmpY-self:getYScroll(), w-2, BORDER_THICKNESS, 255, 0, 0, 255);
                    self.javaObject:DrawTextureScaledColor(nil, -self:getXScroll()+w-BORDER_THICKNESS, tmpY-self:getYScroll(), BORDER_THICKNESS, h, 255, 0, 0, 255);
                    self.javaObject:DrawTextureScaledColor(nil, -self:getXScroll()+BORDER_THICKNESS, tmpY-self:getYScroll()+h-BORDER_THICKNESS, w-2, BORDER_THICKNESS, 255, 0, 0, 255);
                end
            else
                self:drawRectBorderStatic(0, tmpY, self.width, NPCUI_ELEMENT_HEIGHT, self.borderColor.a, self.borderColor.r, self.borderColor.g, self.borderColor.b);
            end
            self:drawTextZoomed(name, 3, tmpY+3, 1.0, 1.0, 1.0, 1.0, FONT_HGT_SMALL);
            self:drawTextZoomed(task, 3, tmpY+20, 1.0, 1.0, 1.0, 1.0, FONT_HGT_SMALL);
            if subtask ~= nil then
                self:drawTextZoomed(subtask, 3, tmpY+37, 1.0, 1.0, 1.0, 1.0, FONT_HGT_SMALL);
            end
            tmpY = tmpY + NPCUI_ELEMENT_HEIGHT;
            i = i + 1;
        end
    end
end

function NpcOverlayUI:onMouseUp(x, y)
    if getPlayer() == nil or getPlayer():isDead() then
        return;
    end
    print("Got coords " .. tostring(x) .. ", " .. tostring(y));
    local npcIndex = math.floor(y/NPCUI_ELEMENT_HEIGHT);
    local player = getPlayer();
    local group = player:getGroup();
    if group == nil then
        return;
    end
    local npcList = group:getGroupMembers();
    if npcIndex >= npcList:size() then
        return;
    end
    local npc = npcList:get(npcIndex);
    if npc then
        print("Selected npc " .. tostring(npc:getUsername()));
        if #selectedGroupNps == 0 then
            selectedGroupNps = {}
            table.insert(selectedGroupNps, npc)
        elseif #selectedGroupNps == 1 then
            if isNpcSelected(npc) then
                selectedGroupNps = {}
            else
                if isShiftKeyDown() then
                    table.insert(selectedGroupNps, npc)
                else
                    selectedGroupNps = {}
                    table.insert(selectedGroupNps, npc)
                end
            end
        else
            if isNpcSelected(npc) then
                if isShiftKeyDown() then
                    local tmpSelectedGroupNps = {}
                    for _, tmpNpc in ipairs(selectedGroupNps) do
                        if tmpNpc ~= npc then
                            table.insert(tmpSelectedGroupNps, npc)
                        end
                    end
                    selectedGroupNps = tmpSelectedGroupNps
                else
                    selectedGroupNps = {}
                    table.insert(selectedGroupNps, npc)
                end
            else
                if isShiftKeyDown() then
                    table.insert(selectedGroupNps, npc)
                else
                    selectedGroupNps = {}
                    table.insert(selectedGroupNps, npc)
                end
            end
        end
    end
end

local function openNpcSettingsWindow()
    if ISGroupNpcsUI.instance == nil then
        local ui = ISGroupNpcsUI:new(300,300)
        ui:initialise()
        ui:addToUIManager()
    end
end

local function createStayCursor(npcObj)
    local bo = ISNpcStayCursor:new("", "", npcObj, getPlayer());
	getCell():setDrag(bo, getPlayer():getPlayerNum());
end

function NpcOverlayUI:onRightMouseUp(x, y)
    if getPlayer() == nil or getPlayer():isDead() then
        return;
    end
    local width = getCore():getScreenWidth() / 30;
    local height = getCore():getScreenHeight() / 2;
    local task_context_menu = ISContextMenu.get(0, (width * 29), height - 90, 1, 1);
    local npcIndex = math.floor(y/NPCUI_ELEMENT_HEIGHT);
    local player = getPlayer();
    local group = player:getGroup();
    if group == nil then
        return;
    end
    local npcList = group:getGroupMembers();
    if npcIndex >= npcList:size() then
        return;
    end
    local npc = npcList:get(npcIndex);
    if npc then
        task_context_menu:addOption(getText("ContextMenu_KnoxEvent_Barricade"), nil, function() tellNpcBarricade(nil, npc) end);
        task_context_menu:addOption(getText("ContextMenu_KnoxEvent_ChopTrees"), nil, function() tellNpcChopTrees(nil, npc) end);
        task_context_menu:addOption(getText("ContextMenu_KnoxEvent_DumpCorpses"), nil, function() tellNpcDumpCorpses(nil, npc) end);
        task_context_menu:addOption(getText("ContextMenu_KnoxEvent_DumpLoot"), nil, function() tellNpcDumpLoot(nil, npc) end);
        task_context_menu:addOption(getText("ContextMenu_KnoxEvent_Follow"), nil, function() tellNpcFollow(nil, npc) end);
        task_context_menu:addOption(getText("ContextMenu_KnoxEvent_Stay"), nil, function() createStayCursor(npc); end);
        task_context_menu:addOption(getText("ContextMenu_KnoxEvent_Guard"), nil, function() tellNpcGuard(nil, npc) end);
        task_context_menu:addOption(getText("ContextMenu_KnoxEvent_Rest"), nil, function() tellNpcRest(nil, npc) end);
        task_context_menu:addOption(getText("ContextMenu_KnoxEvent_Settings"), nil, function() openNpcSettingsWindow() end)
        task_context_menu:calcWidth();
        task_context_menu:setX(width * 29 - task_context_menu:getWidth());
    end
end

function NpcOverlayUI:new()
    local width = NPCUI_ELEMENT_WIDTH
    local height = NPCUI_ELEMENT_HEIGHT * 8
    local x = getCore():getScreenWidth() - NPCUI_ELEMENT_WIDTH
    local y = getCore():getScreenHeight() - height - 140
	local o = {}
	o = ISPanel:new(x, y, width, height);
    setmetatable(o, self)
    self.__index = self
    o.npcListLen = 0;
    o.npcList = {};
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

NpcLootOverlayUI = ISPanel:derive("NpcLootOverlayUI")

function NpcLootOverlayUI:new()
	local width = NPCLOOTUI_ELEMENT_WIDTH
    local height = NPCLOOTUI_ELEMENT_HEIGHT * 8
    local x = getCore():getScreenWidth() - NPCUI_ELEMENT_WIDTH - NPCLOOTUI_ELEMENT_WIDTH
    local y = getCore():getScreenHeight() - height - 140
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

function NpcLootOverlayUI:prerender()
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

function NpcLootOverlayUI:onMouseUp(x, y)
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

NpcAggressiveOverlayUI = ISPanel:derive("NpcAggressiveOverlayUI")

function NpcAggressiveOverlayUI:new()
	local width = NPCLOOTUI_ELEMENT_WIDTH * 2
    local height = NPCLOOTUI_ELEMENT_HEIGHT
    local x = getCore():getScreenWidth() - NPCLOOTUI_ELEMENT_WIDTH * 2
    local y = getCore():getScreenHeight() - height - 111
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

function NpcAggressiveOverlayUI:prerender()
    if getPlayer() == nil or getPlayer():isDead() then
        return;
    end
    local player = getPlayer();
    local group = player:getGroup();
    if group == nil then
        return;
    end
    if group:getGroupAggressive() then
        self:drawTextZoomed(getText("IGUI_KnoxEvent_Npc_Stance_Hostile"), 3, 5, 1.0, 0.8, 0.1, 0.1, FONT_HGT_SMALL);
    else
        self:drawTextZoomed(getText("IGUI_KnoxEvent_Npc_Stance_Neutral"), 3, 5, 1.0, 1.0, 1.0, 1.0, FONT_HGT_SMALL);
    end
    self:drawRectBorderStatic(0, 0, NPCLOOTUI_ELEMENT_WIDTH * 2, NPCLOOTUI_ELEMENT_HEIGHT, self.borderColor.a, self.borderColor.r, self.borderColor.g, self.borderColor.b);
end

function NpcAggressiveOverlayUI:onMouseUp(x, y)
    toggleNpcAggressive();
end

NpcRetreatOverlayUI = ISPanel:derive("NpcRetreatOverlayUI")

function NpcRetreatOverlayUI:new()
	local width = NPCLOOTUI_ELEMENT_WIDTH * 2
    local height = NPCLOOTUI_ELEMENT_HEIGHT
    local x = getCore():getScreenWidth() - NPCLOOTUI_ELEMENT_WIDTH * 2
    local y = getCore():getScreenHeight() - height - 80
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

function NpcRetreatOverlayUI:prerender()
    if getPlayer() == nil or getPlayer():isDead() then
        return;
    end
    local player = getPlayer();
    local group = player:getGroup();
    if group == nil then
        return;
    end
    if group:getGroupRetreat() then
        self:drawTextZoomed(getText("IGUI_KnoxEvent_Npc_Retreat"), 3, 5, 1.0, 0.8, 0.1, 0.1, FONT_HGT_SMALL);
    else
        self:drawTextZoomed(getText("IGUI_KnoxEvent_Npc_Fight"), 3, 5, 1.0, 1.0, 1.0, 1.0, FONT_HGT_SMALL);
    end
    self:drawRectBorderStatic(0, 0, NPCLOOTUI_ELEMENT_WIDTH * 2, NPCLOOTUI_ELEMENT_HEIGHT, self.borderColor.a, self.borderColor.r, self.borderColor.g, self.borderColor.b);
end

function NpcRetreatOverlayUI:onMouseUp(x, y)
    toggleNpcRetreat();
end

local DIALOGUE_ROW_HEIGHT = 30;
local DIALOGUE_PADDING = (DIALOGUE_ROW_HEIGHT - FONT_HGT_SMALL) / 2;
local DIALOGUE_FIRST_OFFSET = 15;

NpcDialogueUI = ISPanel:derive("NpcDialogueUI");

function NpcDialogueUI:onMouseUp(x, y)
    optionOne = DIALOGUE_FIRST_OFFSET + DIALOGUE_ROW_HEIGHT;
    optionsTwo = optionOne + DIALOGUE_ROW_HEIGHT;
    optionsThree = optionsTwo + DIALOGUE_ROW_HEIGHT;
    optionsFour = optionsThree + DIALOGUE_ROW_HEIGHT;
    if self.submenu == 0 then
        if y <= optionOne and y >= DIALOGUE_FIRST_OFFSET then
            self.submenu = 1;
        elseif y <= optionsTwo and y >= DIALOGUE_FIRST_OFFSET then
            askRecentToNpc(self.npcObj);
        elseif y <= optionsThree and y >= DIALOGUE_FIRST_OFFSET and self.npcObj ~= nil and not isNpcInGroup(self.npcObj) then
            askNpcToJoinGroup(self.npcObj);
        elseif y <= optionsFour and y >= DIALOGUE_FIRST_OFFSET then
            stopTalkingToNpc(self.npcObj);
            local playerData = getPlayerData(0);
            playerData.npcDialogueUI.npcName = nil;
            playerData.npcDialogueUI:setVisible(false);
        end
    elseif self.submenu == 1 then
        if y <= optionOne and y >= DIALOGUE_FIRST_OFFSET then
            smallTalkWeather(self.npcObj);
        elseif y <= optionsTwo and y >= DIALOGUE_FIRST_OFFSET then
            smallTalkAge(self.npcObj);
        elseif y <= optionsThree and y >= DIALOGUE_FIRST_OFFSET then
            smallTalkOccupation(self.npcObj);
        elseif y <= optionsFour and y >= DIALOGUE_FIRST_OFFSET then
            self.submenu = 0;
        end
    end
end

function NpcDialogueUI:initialise()
	ISPanel.initialise(self);
end

function NpcDialogueUI:prerender()
    local playerData = getPlayerData(0);
    self.npcName = getNpcDialogueName();
    if  self.npcName ~= nil then
        playerData.npcDialogueUI:setVisible(true);
    else
        self.npcName = nil;
        self.npcObj = nil;
        playerData.npcDialogueUI:setVisible(false);
        return;
    end
    if self.npcName ~= nil then
        local x = 3;
        local y = 0;
        local title = "Chatting with " .. tostring(self.npcName);
        self:drawTextZoomed(title, 3, y, 1.0, 1.0, 1.0, 1.0, FONT_HGT_SMALL);

        if self.submenu == 0 then
            y = y + DIALOGUE_FIRST_OFFSET;
            self:drawTextZoomed(getText("IGUI_KnoxEvent_Npc_Dialogue_SmallTalk"), 3, y + DIALOGUE_PADDING, 1.0, 1.0, 1.0, 1.0, FONT_HGT_SMALL);
            self:drawRectBorderStatic(0, y, self.width, self.height - y, self.borderColor.a, self.borderColor.r, self.borderColor.g, self.borderColor.b);
            y = y + DIALOGUE_ROW_HEIGHT;
            self:drawTextZoomed(getText("IGUI_KnoxEvent_Player_Speech_SpeechRecent"), 3, y + DIALOGUE_PADDING, 1.0, 1.0, 1.0, 1.0, FONT_HGT_SMALL);
            self:drawRectBorderStatic(0, y, self.width, self.height - y, self.borderColor.a, self.borderColor.r, self.borderColor.g, self.borderColor.b);
            y = y + DIALOGUE_ROW_HEIGHT;
            if self.npcObj ~= nil and not isNpcInGroup(self.npcObj) then
                self:drawTextZoomed(getText("IGUI_KnoxEvent_Npc_Dialogue_AskToJoinGroup"), 3, y + DIALOGUE_PADDING, 1.0, 1.0, 1.0, 1.0, FONT_HGT_SMALL);
                self:drawRectBorderStatic(0, y, self.width, self.height - y, self.borderColor.a, self.borderColor.r, self.borderColor.g, self.borderColor.b);
            end
            y = y + DIALOGUE_ROW_HEIGHT;
            self:drawTextZoomed(getText("IGUI_KnoxEvent_Npc_Dialogue_Leave"), 3, y + DIALOGUE_PADDING, 1.0, 1.0, 1.0, 1.0, FONT_HGT_SMALL);
            self:drawRectBorderStatic(0, y, self.width, self.height - y, self.borderColor.a, self.borderColor.r, self.borderColor.g, self.borderColor.b);
            self:drawRectBorderStatic(0, 0, self.width, self.height, self.borderColor.a, self.borderColor.r, self.borderColor.g, self.borderColor.b);
        elseif self.submenu == 1 then
            y = y + DIALOGUE_FIRST_OFFSET;
            self:drawTextZoomed(getText("IGUI_KnoxEvent_Npc_Dialogue_SmallTalkWeather"), 3, y + DIALOGUE_PADDING, 1.0, 1.0, 1.0, 1.0, FONT_HGT_SMALL);
            self:drawRectBorderStatic(0, y, self.width, self.height - y, self.borderColor.a, self.borderColor.r, self.borderColor.g, self.borderColor.b);
            y = y + DIALOGUE_ROW_HEIGHT;
            self:drawTextZoomed(getText("IGUI_KnoxEvent_Npc_Dialogue_SmallTalkAge"), 3, y + DIALOGUE_PADDING, 1.0, 1.0, 1.0, 1.0, FONT_HGT_SMALL);
            self:drawRectBorderStatic(0, y, self.width, self.height - y, self.borderColor.a, self.borderColor.r, self.borderColor.g, self.borderColor.b);
            y = y + DIALOGUE_ROW_HEIGHT;
            self:drawTextZoomed(getText("IGUI_KnoxEvent_Npc_Dialogue_SmallTalkOccupation"), 3, y + DIALOGUE_PADDING, 1.0, 1.0, 1.0, 1.0, FONT_HGT_SMALL);
            self:drawRectBorderStatic(0, y, self.width, self.height - y, self.borderColor.a, self.borderColor.r, self.borderColor.g, self.borderColor.b);
            y = y + DIALOGUE_ROW_HEIGHT;
            self:drawTextZoomed(getText("IGUI_KnoxEvent_Npc_Dialogue_Back"), 3, y + DIALOGUE_PADDING, 1.0, 1.0, 1.0, 1.0, FONT_HGT_SMALL);
            self:drawRectBorderStatic(0, y, self.width, self.height - y, self.borderColor.a, self.borderColor.r, self.borderColor.g, self.borderColor.b);
            self:drawRectBorderStatic(0, 0, self.width, self.height, self.borderColor.a, self.borderColor.r, self.borderColor.g, self.borderColor.b);
        end
    end
end

function NpcDialogueUI:new()
    local width = NPCUI_ELEMENT_WIDTH * 4
    local height = DIALOGUE_FIRST_OFFSET + DIALOGUE_ROW_HEIGHT * 4
    local x = getCore():getScreenWidth() / 2 - width/2;
    local y = getCore():getScreenHeight() /2 - height/2;
	local o = {}
	o = ISPanel:new(x, y, width, height);
    setmetatable(o, self)
    self.__index = self
    o.npcName = nil;
    o.npcObj = nil
    o.submenu = 0;
	o.x = x;
	o.y = y;
	o.background = true;
	o.backgroundColor = {r=0, g=0, b=0, a=0.5};
    o.borderColor = {r=0.4, g=0.4, b=0.4, a=1.0};
    o.width = width;
	o.height = height;
	o.anchorLeft = true;
	o.anchorRight = false;
	o.anchorTop = true;
	o.anchorBottom = false;
    o.moveWithMouse = false;
   return o
end

local function npcGroupHandleHotkeys(keynum)
    if keynum == Keyboard.KEY_SEMICOLON then
        print("Pressed show npc control key")
        if ISGroupNpcsUI.instance ~= nil then
            ISGroupNpcsUI.instance:close();
        else
            local ui = ISGroupNpcsUI:new(300,300)
            ui:initialise()
            ui:addToUIManager()
        end
    elseif keynum == Keyboard.KEY_COMMA then
        toggleNpcAggressive();
    elseif keynum == Keyboard.KEY_PERIOD then
        toggleNpcRetreat();
    elseif keynum == Keyboard.KEY_SLASH then
        local playerData = getPlayerData(0);
        playerData.npcOverlayUI:setVisible(not playerData.npcOverlayUI:isVisible());
        playerData.npcLootOverlayUI:setVisible(not playerData.npcLootOverlayUI:isVisible());
        playerData.npcAggressiveOverlayUI:setVisible(not playerData.npcAggressiveOverlayUI:isVisible());
        playerData.npcRetreatOverlayUI:setVisible(not playerData.npcRetreatOverlayUI:isVisible());
    end
end

Events.OnKeyPressed.Add(npcGroupHandleHotkeys)