-- Quest Journal UI for Knox Event Expanded
-- Displays active and completed quests

require "04_QuestSystem/QuestManager"
require "ISUI/ISCollapsableWindow"
require "ISUI/ISTabPanel"
require "ISUI/ISPanel"
require "ISUI/ISButton"
require "ISUI/ISScrollingListBox"

QuestJournalUI = ISCollapsableWindow:derive("QuestJournalUI")

local JOURNAL_WIDTH = 600
local JOURNAL_HEIGHT = 500
local QUEST_ITEM_HEIGHT = 50
local TAB_HEIGHT = 30
local INFO_PANEL_WIDTH = 350

-- Initialize a new Quest Journal UI
function QuestJournalUI:new(x, y, width, height)
    local o = ISCollapsableWindow:new(x, y, width or JOURNAL_WIDTH, height or JOURNAL_HEIGHT)
    setmetatable(o, self)
    self.__index = self
    
    o.title = getText("IGUI_KnoxEvent_QuestJournal") or "Quest Journal"
    o:setResizable(false)
    
    o.backgroundColor = {r=0.1, g=0.1, b=0.1, a=0.9}
    o.borderColor = {r=0.4, g=0.4, b=0.4, a=1}
    o.moveWithMouse = true
    
    o.selectedQuest = nil
    o.filter = "all" -- all, active, completed
    o.activeQuests = {}
    o.completedQuests = {}
    
    return o
end

-- Initialize the UI elements
function QuestJournalUI:initialise()
    ISCollapsableWindow.initialise(self)
    
    -- Create tab panel
    self.tabPanel = ISTabPanel:new(0, 16, self.width, self.height - 16)
    self.tabPanel:initialise()
    self.tabPanel:setAnchorRight(true)
    self.tabPanel:setAnchorBottom(true)
    self:addChild(self.tabPanel)
    
    -- Create active quests panel
    self.activeQuestsPanel = ISPanel:new(0, TAB_HEIGHT, self.width, self.height - TAB_HEIGHT)
    self.activeQuestsPanel:initialise()
    self.activeQuestsPanel.backgroundColor = {r=0.1, g=0.1, b=0.1, a=0.01}
    self.tabPanel:addTab(getText("IGUI_KnoxEvent_ActiveQuests") or "Active Quests", self.activeQuestsPanel)
    
    -- Create completed quests panel
    self.completedQuestsPanel = ISPanel:new(0, TAB_HEIGHT, self.width, self.height - TAB_HEIGHT)
    self.completedQuestsPanel:initialise()
    self.completedQuestsPanel.backgroundColor = {r=0.1, g=0.1, b=0.1, a=0.01}
    self.tabPanel:addTab(getText("IGUI_KnoxEvent_CompletedQuests") or "Completed Quests", self.completedQuestsPanel)
    
    -- Create quest list for active quests
    self.activeQuestsList = ISScrollingListBox:new(0, 0, self.width - INFO_PANEL_WIDTH - 1, self.height - TAB_HEIGHT - 1)
    self.activeQuestsList:initialise()
    self.activeQuestsList:instantiate()
    self.activeQuestsList.itemheight = QUEST_ITEM_HEIGHT
    self.activeQuestsList.selected = 0
    self.activeQuestsList.joypadParent = self
    self.activeQuestsList.drawBorder = true
    self.activeQuestsList.backgroundColor = {r=0, g=0, b=0, a=0.5}
    self.activeQuestsList.doDrawItem = self.doDrawQuestItem
    self.activeQuestsList:setOnMouseDownFunction(self, self.onQuestMouseDown)
    self.activeQuestsPanel:addChild(self.activeQuestsList)
    
    -- Create quest list for completed quests
    self.completedQuestsList = ISScrollingListBox:new(0, 0, self.width - INFO_PANEL_WIDTH - 1, self.height - TAB_HEIGHT - 1)
    self.completedQuestsList:initialise()
    self.completedQuestsList:instantiate()
    self.completedQuestsList.itemheight = QUEST_ITEM_HEIGHT
    self.completedQuestsList.selected = 0
    self.completedQuestsList.joypadParent = self
    self.completedQuestsList.drawBorder = true
    self.completedQuestsList.backgroundColor = {r=0, g=0, b=0, a=0.5}
    self.completedQuestsList.doDrawItem = self.doDrawQuestItem
    self.completedQuestsList:setOnMouseDownFunction(self, self.onQuestMouseDown)
    self.completedQuestsPanel:addChild(self.completedQuestsList)
    
    -- Create quest info panel for active quests
    self.activeQuestInfoPanel = ISPanel:new(self.width - INFO_PANEL_WIDTH, 0, INFO_PANEL_WIDTH, self.height - TAB_HEIGHT - 1)
    self.activeQuestInfoPanel:initialise()
    self.activeQuestInfoPanel.backgroundColor = {r=0.1, g=0.1, b=0.1, a=0.7}
    self.activeQuestInfoPanel.drawQuestInfo = self.drawQuestInfo
    self.activeQuestInfoPanel.parent = self
    self.activeQuestsPanel:addChild(self.activeQuestInfoPanel)
    
    -- Create quest info panel for completed quests
    self.completedQuestInfoPanel = ISPanel:new(self.width - INFO_PANEL_WIDTH, 0, INFO_PANEL_WIDTH, self.height - TAB_HEIGHT - 1)
    self.completedQuestInfoPanel:initialise()
    self.completedQuestInfoPanel.backgroundColor = {r=0.1, g=0.1, b=0.1, a=0.7}
    self.completedQuestInfoPanel.drawQuestInfo = self.drawQuestInfo
    self.completedQuestInfoPanel.parent = self
    self.completedQuestsPanel:addChild(self.completedQuestInfoPanel)
    
    -- Add keybind
    self.keybind = Keyboard.KEY_J
    
    -- Set initial tab
    self.tabPanel:activateTabByName(getText("IGUI_KnoxEvent_ActiveQuests") or "Active Quests")
end

-- Load quests from the QuestManager
function QuestJournalUI:loadQuests(playerId)
    if not playerId then return end -- Add a guard to make sure that a player id was passed
    local player = getSpecificPlayer(playerId)
    
    -- Clear existing quests
    self.activeQuestsList:clear()
    self.completedQuestsList:clear()
    
    -- Load active quests
    self.activeQuests = QuestManager.getAllActiveQuests(playerId)
    for questId, questInstance in pairs(self.activeQuests) do
        local questDef = QuestManager.getQuest(questId)
        if questDef then
            self.activeQuestsList:addItem(questDef.title, {questId = questId, questDef = questDef, questInstance = questInstance})
        end
    end
    
    -- Load completed quests
    self.completedQuests = QuestManager.getAllCompletedQuests(playerId)
    for questId, questInstance in pairs(self.completedQuests) do
        local questDef = QuestManager.getQuest(questId)
        if questDef then
            self.completedQuestsList:addItem(questDef.title, {questId = questId, questDef = questDef, questInstance = questInstance})
        end
    end
    if not player then
        return
        end
    end
    
    -- Select the first quest if available
    if self.activeQuestsList.items and #self.activeQuestsList.items > 0 then
        self.activeQuestsList.selected = 1
        self.selectedQuest = self.activeQuestsList.items[1].item
    elseif self.completedQuestsList.items and #self.completedQuestsList.items > 0 then
        self.completedQuestsList.selected = 1
        self.selectedQuest = self.completedQuestsList.items[1].item
        self.tabPanel:activateTabByName(getText("IGUI_KnoxEvent_CompletedQuests") or "Completed Quests")
    end
end

-- Draw a quest item in the list
function QuestJournalUI:doDrawQuestItem(y, item, alt)
    local questData = item.item
    local questDef = questData.questDef
    local questInstance = questData.questInstance
    
    -- Draw background
    local isSelected = self.selected == item.index
    local bg = isSelected and {r=0.3, g=0.3, b=0.3, a=0.8} or {r=0.1, g=0.1, b=0.1, a=0.6}
    self:drawRect(0, y, self:getWidth(), self.itemheight, bg.a, bg.r, bg.g, bg.b)
    
    -- Draw quest title
    self:drawText(questDef.title, 10, y + 5, 1, 1, 1, 1, UIFont.Medium)
    
    -- Draw quest type and difficulty
    local typeText = questDef.type or "side"
    local diffText = ""
    if questDef.difficulty then
        if questDef.difficulty == 1 then
            diffText = "Easy"
        elseif questDef.difficulty == 2 then
            diffText = "Medium"
        elseif questDef.difficulty == 3 then
            diffText = "Hard"
        elseif questDef.difficulty == 4 then
            diffText = "Very Hard"
        end
    end
    
    local typeAndDiff = string.format("%s - %s", typeText:upper(), diffText)
    self:drawText(typeAndDiff, 10, y + 25, 0.7, 0.7, 0.7, 1, UIFont.Small)
    
    -- Draw separator
    if not isSelected then
        self:drawRect(0, y + self.itemheight - 1, self:getWidth(), 1, 0.2, 0.2, 0.2, 0.2)
    end
    
    return y + self.itemheight
end

-- Handle quest selection
function QuestJournalUI:onQuestMouseDown(item, x, y)
    if not item or not item.item then return end
    
    self.selectedQuest = item.item
    if self.tabPanel:getActiveTab() == getText("IGUI_KnoxEvent_ActiveQuests") or self.tabPanel:getActiveTab() == "Active Quests" then
        self.completedQuestsList.selected = 0
    else
        self.activeQuestsList.selected = 0
    end
end

-- Draw quest info in the detail panel
function QuestJournalUI:drawQuestInfo(questData)
    -- If no quest selected, show a message
    if not questData then
        self:drawText("No quest selected", 10, 20, 0.7, 0.7, 0.7, 1, UIFont.Medium)
        return
    end
    
    local questDef = questData.questDef
    local questInstance = questData.questInstance
    
    -- Draw title
    self:drawText(questDef.title, 10, 10, 1, 1, 1, 1, UIFont.Medium)
    
    -- Draw description
    local y = 40
    self:drawRect(5, y - 5, self.width - 10, 2, 0.6, 0.6, 0.6, 0.6)
    self:drawText(questDef.description, 10, y, 0.9, 0.9, 0.9, 1, UIFont.Small)
    
    -- Draw objectives
    y = y + 40
    self:drawText("Objectives:", 10, y, 0.8, 0.8, 1, 1, UIFont.Medium)
    y = y + 25
    
    if questDef.objectives then
        for i, objDef in ipairs(questDef.objectives) do
            local objective = questInstance.objectives[i]
            local objText = objDef.description
            
            -- Show progress if applicable
            if objective then
                objText = string.format("%s (%d/%d)", objText, objective.progress, objective.max)
                
                -- Mark completed objectives
                if objective.completed then
                    objText = objText .. " [COMPLETED]"
                    self:drawText(objText, 20, y, 0.5, 1, 0.5, 1, UIFont.Small)
                else
                    self:drawText(objText, 20, y, 0.9, 0.9, 0.9, 1, UIFont.Small)
                end
            else
                self:drawText(objText, 20, y, 0.9, 0.9, 0.9, 1, UIFont.Small)
            end
            
            y = y + 20
        end
    end
    
    -- Draw rewards if any
    if questDef.rewards then
        y = y + 20
        self:drawText("Rewards:", 10, y, 0.8, 0.8, 1, 1, UIFont.Medium)
        y = y + 25
        
        for _, reward in ipairs(questDef.rewards) do
            local rewardText = ""
            
            if reward.type == "item" then
                rewardText = string.format("%d x %s", reward.count or 1, reward.item:gsub("Base.", ""):gsub("KnoxEventExpanded.", ""))
            elseif reward.type == "xp" then
                rewardText = string.format("%d %s XP", reward.amount, reward.skill)
            end
            
            if rewardText ~= "" then
                self:drawText(rewardText, 20, y, 0.9, 0.9, 0.6, 1, UIFont.Small)
                y = y + 20
            end
        end
    end
    
    -- Draw quest status (active/completed)
    y = y + 30
    local statusText = "Status: "
    if questInstance.status == QuestManager.STATUS.ACTIVE then
        statusText = statusText .. "Active"
        self:drawText(statusText, 10, y, 0.6, 0.8, 1, 1, UIFont.Medium)
    elseif questInstance.status == QuestManager.STATUS.COMPLETED then
        statusText = statusText .. "Completed"
        self:drawText(statusText, 10, y, 0.5, 1, 0.5, 1, UIFont.Medium)
    elseif questInstance.status == QuestManager.STATUS.FAILED then
        statusText = statusText .. "Failed"
        self:drawText(statusText, 10, y, 1, 0.5, 0.5, 1, UIFont.Medium)
    end
    
    -- Draw time tracking
    y = y + 25
    local startedTime = questInstance.started
    if startedTime then
        self:drawText("Started: Day " .. math.floor(startedTime / 24), 10, y, 0.7, 0.7, 0.7, 1, UIFont.Small)
    end
    
    if questInstance.completed then
        y = y + 20
        self:drawText("Completed: Day " .. math.floor(questInstance.completed / 24), 10, y, 0.7, 0.7, 0.7, 1, UIFont.Small)
    end
end

-- Override render to update quest info panel
function QuestJournalUI:prerender()
    ISCollapsableWindow.prerender(self)
    
    -- Update the quest info panel based on the selected tab
    if self.tabPanel:getActiveTab() == getText("IGUI_KnoxEvent_ActiveQuests") or self.tabPanel:getActiveTab() == "Active Quests" then
        if self.activeQuestsList.selected > 0 and self.activeQuestsList.items[self.activeQuestsList.selected] then
            self.selectedQuest = self.activeQuestsList.items[self.activeQuestsList.selected].item
        end
        self.activeQuestInfoPanel:drawQuestInfo(self.selectedQuest)
    else
        if self.completedQuestsList.selected > 0 and self.completedQuestsList.items[self.completedQuestsList.selected] then
            self.selectedQuest = self.completedQuestsList.items[self.completedQuestsList.selected].item
        end
        self.completedQuestInfoPanel:drawQuestInfo(self.selectedQuest)
    end
end

-- Override update to check for keybind
function QuestJournalUI:update()
    ISCollapsableWindow.update(self)
    
    -- Check for keybind to toggle journal
    if self.keybind and (isKeyDown(self.keybind) and not self.wasKeyDown) then
        self:toggleVisibility()
    end
    self.wasKeyDown = isKeyDown(self.keybind)
end

-- Toggle visibility of the journal
function QuestJournalUI:toggleVisibility(playerId)
	if not playerId then return end -- Add a guard to make sure that a player id was passed
	self.visible = not self.visible
	if self.visible then
		self:loadQuests(playerId)
	end
end

-- Create the journal instance
function QuestJournalUI.createUI()
    if QuestJournalUI.instance then
        QuestJournalUI.instance:removeFromUIManager()
        QuestJournalUI.instance = nil
    end
    
    local x = getCore():getScreenWidth() / 2 - JOURNAL_WIDTH / 2
    local y = getCore():getScreenHeight() / 2 - JOURNAL_HEIGHT / 2
    
    QuestJournalUI.instance = QuestJournalUI:new(x, y, JOURNAL_WIDTH, JOURNAL_HEIGHT)
    QuestJournalUI.instance:initialise()
    QuestJournalUI.instance:addToUIManager()
    QuestJournalUI.instance:setVisible(false)
end

-- Initialize the journal when the game starts
Events.OnGameStart.Add(QuestJournalUI.createUI)

-- Keybind to toggle journal visibility
local function onKeyPressed(key, pressed)
	if not pressed then return end
	if key == Keyboard.KEY_J and not isKeyDown(Keyboard.KEY_LCONTROL) and not isKeyDown(Keyboard.KEY_LSHIFT) then
		local player = getSpecificPlayer(0)
		if player and QuestJournalUI.instance then
			QuestJournalUI.instance:toggleVisibility(player:getPlayerNum())
		end
	end
end

Events.OnKeyPressed.Add(onKeyPressed) 

return QuestJournalUI 