-- Quest Dialogue UI for Knox Event Expanded
-- Extends the existing dialogue system to support quest interactions

require "04_QuestSystem/QuestManager"
require "ISUI/ISPanel"

QuestDialogueUI = ISPanel:derive("QuestDialogueUI")

local DIALOGUE_WIDTH = 500
local DIALOGUE_HEIGHT = 400
local DIALOGUE_TITLE_HEIGHT = 30
local DIALOGUE_OPTION_HEIGHT = 40
local DIALOGUE_PADDING = 10
local DIALOGUE_TEXT_PADDING = 20
local DIALOGUE_OPTION_PADDING = 5

function QuestDialogueUI:new(x, y, width, height)
    local o = ISPanel:new(x, y, width or DIALOGUE_WIDTH, height or DIALOGUE_HEIGHT)
    setmetatable(o, self)
    self.__index = self
    
    o.backgroundColor = {r=0, g=0, b=0, a=0.9}
    o.borderColor = {r=0.4, g=0.4, b=0.4, a=1}
    o.titleBackgroundColor = {r=0.2, g=0.2, b=0.2, a=1}
    o.titleColor = {r=1, g=1, b=1, a=1}
    o.textColor = {r=0.9, g=0.9, b=0.9, a=1}
    o.optionBackgroundColor = {r=0.3, g=0.3, b=0.3, a=0.7}
    o.optionHoverColor = {r=0.4, g=0.4, b=0.4, a=0.9}
    o.optionTextColor = {r=1, g=1, b=1, a=1}
    
    o.npc = nil
    o.npcId = nil
    o.quest = nil
    o.questState = "offer" -- offer, active, complete
    o.dialogueText = ""
    o.dialogueOptions = {}
    o.selectedOption = -1
    o.scrollOffset = 0
    o.maxLines = 10
    
    o:setWidth(width or DIALOGUE_WIDTH)
    o:setHeight(height or DIALOGUE_HEIGHT)
    o.moveWithMouse = true
    
    return o
end

function QuestDialogueUI:initialise()
    ISPanel.initialise(self)
    self:setAlwaysOnTop(true)
end

function QuestDialogueUI:createChildren()
    -- Close button
    self.closeButton = ISButton:new(self.width - 24, 4, 20, 20, "X", self, QuestDialogueUI.onCloseButtonClick)
    self.closeButton:initialise()
    self.closeButton.backgroundColor = {r=0.5, g=0, b=0, a=0.7}
    self.closeButton.backgroundColorMouseOver = {r=0.7, g=0, b=0, a=0.7}
    self.closeButton:setAnchorRight(true)
    self:addChild(self.closeButton)
    
    -- Scroll bar for dialogue text
    self.scrollBar = ISScrollBar:new(self.width - 20, DIALOGUE_TITLE_HEIGHT + DIALOGUE_PADDING, 
                                     20, self.height - DIALOGUE_TITLE_HEIGHT - DIALOGUE_PADDING * 2, 
                                     self, QuestDialogueUI.onScrollChange)
    self.scrollBar:initialise()
    self.scrollBar:setAnchorRight(true)
    self.scrollBar:setAnchorBottom(true)
    self:addChild(self.scrollBar)
end

function QuestDialogueUI:onScrollChange()
    self.scrollOffset = self.scrollBar:getValue()
end

function QuestDialogueUI:onCloseButtonClick()
    self:setVisible(false)
    self.npc = nil
    self.quest = nil
end

function QuestDialogueUI:setNPC(npc, npcId)
    self.npc = npc
    self.npcId = npcId
end

function QuestDialogueUI:setQuest(quest, state)
    self.quest = quest
    self.questState = state or "offer"
    
    -- Set dialogue text based on quest and state
    if quest and quest.dialogue then
        self.dialogueText = quest.dialogue[self.questState] or ""
    else
        self.dialogueText = "No quest information available."
    end
    
    -- Set dialogue options based on quest state
    self.dialogueOptions = {}
    
    if self.questState == "offer" then
        table.insert(self.dialogueOptions, {
            text = "Accept quest",
            action = function() self:acceptQuest() end
        })
        table.insert(self.dialogueOptions, {
            text = "Decline quest",
            action = function() self:declineQuest() end
        })
    elseif self.questState == "active" then
        -- Check if the quest can be completed
        local playerId = getSpecificPlayer(0):getPlayerNum()
        local canComplete = self:canCompleteQuest(playerId, self.quest.id)
        
        if canComplete then
            table.insert(self.dialogueOptions, {
                text = "Complete quest",
                action = function() self:completeQuest() end
            })
        end
        
        table.insert(self.dialogueOptions, {
            text = "Ask about quest",
            action = function() self:askAboutQuest() end
        })
    elseif self.questState == "complete" then
        table.insert(self.dialogueOptions, {
            text = "Goodbye",
            action = function() self:closeDialogue() end
        })
    end
    
    -- Always add goodbye option
    if self.questState ~= "complete" then
        table.insert(self.dialogueOptions, {
            text = "Goodbye",
            action = function() self:closeDialogue() end
        })
    end
end

function QuestDialogueUI:canCompleteQuest(playerId, questId)
    -- Get active quest data
    local questInstance = QuestManager.getActiveQuest(playerId, questId)
    if not questInstance then return false end
    
    -- Check if all objectives are completed
    for _, objective in ipairs(questInstance.objectives) do
        if not objective.completed then
            return false
        end
    end
    
    return true
end

function QuestDialogueUI:acceptQuest()
    local playerId = getSpecificPlayer(0):getPlayerNum()
    local player = getSpecificPlayer(playerId)
    
    -- Start the quest
    if QuestManager.startQuest(playerId, self.quest.id) then
        -- Update dialogue text to acceptance text
        self.dialogueText = self.quest.dialogue.accept or "Quest accepted."
        player:Say("I'll help you out.")
        
        -- Update state and options
        self.questState = "active"
        self:setQuest(self.quest, "active")
    else
        -- Failed to start quest
        self.dialogueText = "You already have this quest or there was an error starting it."
    end
end

function QuestDialogueUI:declineQuest()
    -- Update dialogue text to decline text
    self.dialogueText = self.quest.dialogue.decline or "Quest declined."
    getSpecificPlayer(0):Say("Sorry, I can't help with that right now.")
    
    -- Close dialogue after a short delay
    Events.OnTick.Add(function()
        Events.OnTick.Remove(self.closeAfterDelay)
        self:closeDialogue()
    end)
    self.closeAfterDelay = true
end

function QuestDialogueUI:completeQuest()
    local playerId = getSpecificPlayer(0):getPlayerNum()
    local player = getSpecificPlayer(playerId)
    
    -- Complete the quest
    if QuestManager.completeQuest(playerId, self.quest.id) then
        -- Update dialogue text to completion text
        self.dialogueText = self.quest.dialogue.complete or "Quest completed."
        player:Say("I've completed your task.")
        
        -- Update state and options
        self.questState = "complete"
        self:setQuest(self.quest, "complete")
    else
        -- Failed to complete quest
        self.dialogueText = "You haven't completed all objectives yet."
    end
end

function QuestDialogueUI:askAboutQuest()
    local playerId = getSpecificPlayer(0):getPlayerNum()
    local questInstance = QuestManager.getActiveQuest(playerId, self.quest.id)
    
    if questInstance then
        -- Create objective status text
        local objectiveText = "Current objectives:\n"
        for i, objective in ipairs(questInstance.objectives) do
            local questDef = QuestManager.getQuest(self.quest.id)
            local objDef = questDef.objectives[i]
            
            local status = string.format("%s: %d/%d", 
                objDef.description, 
                objective.progress, 
                objective.max)
                
            if objective.completed then
                status = status .. " (Completed)"
            end
            
            objectiveText = objectiveText .. status .. "\n"
        end
        
        -- Update dialogue text
        self.dialogueText = self.quest.dialogue.active or "How's your progress?"
        self.dialogueText = self.dialogueText .. "\n\n" .. objectiveText
    else
        self.dialogueText = "I don't have any tasks for you right now."
    end
end

function QuestDialogueUI:closeDialogue()
    -- Close the dialogue window
    self:setVisible(false)
    
    -- Clear NPC and quest data
    self.npc = nil
    self.quest = nil
end

function QuestDialogueUI:prerender()
    -- Draw background
    self:drawRect(0, 0, self.width, self.height, self.backgroundColor.a, self.backgroundColor.r, self.backgroundColor.g, self.backgroundColor.b)
    
    -- Draw title bar
    self:drawRect(0, 0, self.width, DIALOGUE_TITLE_HEIGHT, self.titleBackgroundColor.a, self.titleBackgroundColor.r, self.titleBackgroundColor.g, self.titleBackgroundColor.b)
    
    -- Draw title
    local title = "Quest: " .. (self.quest and self.quest.title or "Unknown")
    self:drawText(title, DIALOGUE_PADDING, DIALOGUE_PADDING / 2, self.titleColor.r, self.titleColor.g, self.titleColor.b, self.titleColor.a, UIFont.Medium)
    
    -- Draw NPC name if available
    if self.npc then
        local npcName = "NPC: " .. (self.npc:getUsername() or "Unknown")
        local textWidth = getTextManager():MeasureStringX(UIFont.Small, npcName)
        self:drawText(npcName, self.width - textWidth - DIALOGUE_PADDING * 2, DIALOGUE_PADDING / 2, self.titleColor.r, self.titleColor.g, self.titleColor.b, self.titleColor.a, UIFont.Small)
    end
    
    -- Draw dialogue text
    self:drawDialogueText()
    
    -- Draw options
    self:drawDialogueOptions()
    
    -- Draw border
    self:drawRectBorder(0, 0, self.width, self.height, self.borderColor.a, self.borderColor.r, self.borderColor.g, self.borderColor.b)
end

function QuestDialogueUI:drawDialogueText()
    -- Calculate dialogue text area
    local textX = DIALOGUE_PADDING
    local textY = DIALOGUE_TITLE_HEIGHT + DIALOGUE_PADDING
    local textWidth = self.width - DIALOGUE_PADDING * 2 - self.scrollBar.width
    local textHeight = self.height - DIALOGUE_TITLE_HEIGHT - DIALOGUE_PADDING * 2 - DIALOGUE_OPTION_HEIGHT * #self.dialogueOptions - DIALOGUE_PADDING
    
    -- Draw text background
    self:drawRect(textX, textY, textWidth, textHeight, 0.3, 0, 0, 0)
    
    -- Draw dialogue text
    local text = self.dialogueText
    if text and text ~= "" then
        self:drawText(text, textX + DIALOGUE_TEXT_PADDING, textY + DIALOGUE_TEXT_PADDING, self.textColor.r, self.textColor.g, self.textColor.b, self.textColor.a, UIFont.Medium)
    end
end

function QuestDialogueUI:drawDialogueOptions()
    -- Calculate options area
    local optionsStartY = self.height - DIALOGUE_OPTION_HEIGHT * #self.dialogueOptions - DIALOGUE_PADDING
    
    -- Draw each option
    for i, option in ipairs(self.dialogueOptions) do
        local optionY = optionsStartY + (i-1) * DIALOGUE_OPTION_HEIGHT
        local isHovered = self.selectedOption == i
        
        -- Draw option background
        local bgColor = isHovered and self.optionHoverColor or self.optionBackgroundColor
        self:drawRect(DIALOGUE_PADDING, optionY, self.width - DIALOGUE_PADDING * 2, DIALOGUE_OPTION_HEIGHT - DIALOGUE_OPTION_PADDING, bgColor.a, bgColor.r, bgColor.g, bgColor.b)
        
        -- Draw option text
        self:drawText(option.text, DIALOGUE_PADDING + DIALOGUE_TEXT_PADDING, optionY + DIALOGUE_OPTION_HEIGHT / 4, self.optionTextColor.r, self.optionTextColor.g, self.optionTextColor.b, self.optionTextColor.a, UIFont.Medium)
    end
end

function QuestDialogueUI:onMouseMove(dx, dy)
    ISPanel.onMouseMove(self, dx, dy)
    
    -- Calculate options area
    local optionsStartY = self.height - DIALOGUE_OPTION_HEIGHT * #self.dialogueOptions - DIALOGUE_PADDING
    
    -- Check if mouse is over an option
    local mouseY = self:getMouseY()
    if mouseY >= optionsStartY and mouseY <= self.height - DIALOGUE_PADDING then
        local optionIndex = math.floor((mouseY - optionsStartY) / DIALOGUE_OPTION_HEIGHT) + 1
        if optionIndex >= 1 and optionIndex <= #self.dialogueOptions then
            self.selectedOption = optionIndex
        else
            self.selectedOption = -1
        end
    else
        self.selectedOption = -1
    end
end

function QuestDialogueUI:onMouseUp(x, y)
    -- Handle option clicks
    if self.selectedOption > 0 and self.selectedOption <= #self.dialogueOptions then
        local option = self.dialogueOptions[self.selectedOption]
        if option and option.action then
            option.action()
        end
    end
end

-- Static method to open quest dialogue for an NPC
function QuestDialogueUI.showQuestDialogue(npc, npcId, questId, state)
    if not QuestDialogueUI.instance then
        local x = getCore():getScreenWidth() / 2 - DIALOGUE_WIDTH / 2
        local y = getCore():getScreenHeight() / 2 - DIALOGUE_HEIGHT / 2
        QuestDialogueUI.instance = QuestDialogueUI:new(x, y, DIALOGUE_WIDTH, DIALOGUE_HEIGHT)
        QuestDialogueUI.instance:initialise()
        QuestDialogueUI.instance:addToUIManager()
    end
    
    -- Set NPC and quest
    QuestDialogueUI.instance:setNPC(npc, npcId)
    
    -- Get quest definition
    local quest = QuestManager.getQuest(questId)
    if quest then
        -- Determine quest state for the player
        local playerId = getSpecificPlayer(0):getPlayerNum()
        local currentState = state
        
        if not currentState then
            if QuestManager.hasCompletedQuest(playerId, questId) then
                currentState = "complete"
            elseif QuestManager.hasQuest(playerId, questId) then
                currentState = "active"
            else
                currentState = "offer"
            end
        end
        
        -- Set quest and state
        QuestDialogueUI.instance:setQuest(quest, currentState)
    else
        -- No quest found
        QuestDialogueUI.instance.dialogueText = "No quest information available."
    end
    
    -- Show the dialogue UI
    QuestDialogueUI.instance:setVisible(true)
    QuestDialogueUI.instance:bringToTop()
end 