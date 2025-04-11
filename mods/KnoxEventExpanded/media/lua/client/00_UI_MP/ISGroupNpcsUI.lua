if not isClient() or isServer() then return end

require "ISUI/ISCollapsableWindow"

ISGroupNpcsUI = ISCollapsableWindow:derive("ISGroupNpcsUI");

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local FONT_HGT_MEDIUM = getTextManager():getFontHeight(UIFont.Medium)
local FONT_HGT_LARGE = getTextManager():getFontHeight(UIFont.Large)

local function setChopTreesArea()
    local ui = AreaSelector:new(0, 0, 320, 150, getText("IGUI_KnoxEvent_Npc_Task_ChopTrees"));
    ui:initialise();
    ui.type = "CHOPTREES";
    ui:addToUIManager();
end

local function setCorpseClearArea()
    local ui = AreaSelector:new(0, 0, 320, 150, getText("IGUI_KnoxEvent_Npc_Task_CorpseClear"));
    ui:initialise();
    ui.type = "CORPSECLEAR";
    ui:addToUIManager();
end

local function setCorpseDumpArea()
    local ui = AreaSelector:new(0, 0, 320, 150, getText("IGUI_KnoxEvent_Npc_Task_CorpseDump"));
    ui:initialise();
    ui.type = "CORPSEDUMP";
    ui:addToUIManager();
end

local function setGuardArea()
    local ui = AreaSelector:new(0, 0, 320, 150, getText("IGUI_KnoxEvent_Npc_Task_Guard"));
    ui:initialise();
    ui.type = "GUARD";
    ui:addToUIManager();
end

function ISGroupNpcsUI:populateList()
    local itemHeight = 20;
    local panelWidth = 9 * self.width / 10;
    local nameWidth = panelWidth / 6;
    local taskWidth = panelWidth / 6;
    local subTaskWidth = panelWidth / 6;
    local relationWidth = panelWidth / 6;
    local removeWidth = panelWidth / 6;
    local paddingX = panelWidth / 24;
    local y = 35;

    local topPanelEntry = ISPanel:new(self.width / 20, y, 9 * self.width / 10, itemHeight);
    local x = 0;
    local nameHeaderButton = ISButton:new(x, 0, nameWidth, itemHeight, getText("IGUI_KnoxEvent_NpcOverview_Col_Name"), nil, function() end);
    x = x + nameWidth + paddingX;
    local taskHeaderButton = ISButton:new(x, 0, taskWidth, itemHeight, getText("IGUI_KnoxEvent_NpcOverview_Col_Task"), nil, function() end);
    x = x + taskWidth + paddingX;
    local subTaskHeaderButton = ISButton:new(x, 0, subTaskWidth, itemHeight, getText("IGUI_KnoxEvent_NpcOverview_Col_Subtask"), nil, function() end);
    x = x + subTaskWidth + paddingX;
    local relationHeaderButton = ISButton:new(x, 0, relationWidth, itemHeight, getText("IGUI_KnoxEvent_NpcOverview_Col_Relation"), nil, function() end);
    topPanelEntry:addChild(nameHeaderButton);
    topPanelEntry:addChild(taskHeaderButton);
    topPanelEntry:addChild(subTaskHeaderButton);
    topPanelEntry:addChild(relationHeaderButton);
    self:addChild(topPanelEntry);
    y = y + 4 * itemHeight / 3

    for i=1, #groupNpcList do
        local npcData = groupNpcList[i];
        local panelEntry = ISPanel:new(self.width / 20, y, 9 * self.width / 10, itemHeight);
        x = 0;
        local nameButton = ISButton:new(x, 0, nameWidth, itemHeight, npcData.name, nil, function() end);
        x = x + nameWidth + paddingX;
        local taskButton = ISButton:new(x, 0, taskWidth, itemHeight, npcData["task"], nil, function() end);
        x = x + taskWidth + paddingX;
        local subTaskButton = ISButton:new(x, 0, subTaskWidth, itemHeight, npcData["subtask"], nil, function() end);
        x = x + subTaskWidth + paddingX;
        local relationButton = ISButton:new(x, 0, relationWidth, itemHeight, tostring(npcData["relation"]), nil, function() end);
        x = x + relationWidth + paddingX;
        local removeButton = ISButton:new(x, 0, removeWidth, itemHeight, getText("IGUI_KnoxEvent_NpcOverview_Remove_Button"), nil, function() askNpcToLeaveGroup(nil, tonumber(npcData["id"])); end);
        panelEntry:addChild(nameButton);
        panelEntry:addChild(taskButton);
        panelEntry:addChild(subTaskButton);
        panelEntry:addChild(relationButton);
        panelEntry:addChild(removeButton);
        self:addChild(panelEntry);
        y = y + 4 * itemHeight / 3;
    end

    local areaSelectorY = 9 * self.height / 10;
    local chopTreesButton = ISButton:new(panelWidth / 100, areaSelectorY, panelWidth / 10, itemHeight, getText("IGUI_KnoxEvent_NpcOverview_Sel_ChopTreesArea"), nil, function() setChopTreesArea(); end);
    self:addChild(chopTreesButton);
    local corpseClearButton = ISButton:new(25 * panelWidth / 100, areaSelectorY, panelWidth / 10, itemHeight, getText("IGUI_KnoxEvent_NpcOverview_Sel_ClearCorpsesArea"), nil, function() setCorpseClearArea(); end);
    self:addChild(corpseClearButton);
    local corpseDumpButton = ISButton:new(50 * panelWidth / 100, areaSelectorY, panelWidth / 10, itemHeight, getText("IGUI_KnoxEvent_NpcOverview_Sel_DumpCorpsesArea"), nil, function() setCorpseDumpArea(); end);
    self:addChild(corpseDumpButton);
    local guardButton = ISButton:new(75 * panelWidth / 100, areaSelectorY, panelWidth / 10, itemHeight, getText("IGUI_KnoxEvent_NpcOverview_Sel_GuardArea"), nil, function() setGuardArea(); end);
    self:addChild(guardButton);
end

function ISGroupNpcsUI:new(x, y)
    local o = {}
    local width = 720
    local height = 350
    o = ISCollapsableWindow:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o.width = width
    o.height = height
    o.moveWithMouse = true
    o.anchorLeft = true
    o.anchorRight = true
    o.anchorTop = true
    o.anchorBottom = true
    o.resizable = false
    o.npcList = {}
    ISGroupNpcsUI.instance = o
    o:populateList();
    return o;
end

function ISGroupNpcsUI:close()
    self:setVisible(false);
    self:removeFromUIManager();
    ISGroupNpcsUI.instance = nil
end
