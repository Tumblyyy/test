-- Quest NPC Integration for Knox Event Expanded
-- Connects the Quest System with the NPC dialogue and interaction systems

require "04_QuestSystem/QuestManager"
require "04_QuestSystem/QuestDialogueUI"

-- Table to track NPCs and their available quests
local NpcQuestGivers = {}

-- Quest giver types mapping to NPC presets and professions
local QuestGiverTypes = {
    ["random_survivor"] = {"SurvivorNpc"},
    ["military_survivor"] = {"SoldierNpc"},
    ["police_survivor"] = {"PoliceNpc"},
    ["bandit"] = {"BanditNpc"},
    -- Add more mappings as needed
}

-- Map professions to quest giver types for more specific matching
local ProfessionToQuestGiverType = {
    ["policeofficer"] = "police_survivor",
    ["parkranger"] = "police_survivor",
    ["fireofficer"] = "random_survivor",
    ["securityguard"] = "random_survivor",
    ["veteran"] = "military_survivor",
    ["doctor"] = "random_survivor",
    ["nurse"] = "random_survivor",
}

-- Initialize quest givers
local function initQuestGivers()
    NpcQuestGivers = {}
    
    -- For each quest in the system
    for questId, questDef in pairs(QuestManager.quests) do
        local giverType = questDef.giver
        if giverType then
            -- Map the quest giver type to NPC types
            local npcTypes = QuestGiverTypes[giverType]
            if npcTypes then
                for _, npcType in ipairs(npcTypes) do
                    if not NpcQuestGivers[npcType] then
                        NpcQuestGivers[npcType] = {}
                    end
                    table.insert(NpcQuestGivers[npcType], questId)
                end
            end
            
            -- Also map professions for this quest giver type
            for profession, mappedType in pairs(ProfessionToQuestGiverType) do
                if mappedType == giverType then
                    if not NpcQuestGivers[profession] then
                        NpcQuestGivers[profession] = {}
                    end
                    table.insert(NpcQuestGivers[profession], questId)
                end
            end
        end
    end
    
    print("Quest givers initialized with " .. getTableSize(NpcQuestGivers) .. " NPC types")
end

-- Helper function to get table size
local function getTableSize(t)
    local count = 0
    for _, _ in pairs(t) do
        count = count + 1
    end
    return count
end

-- Get NPC type using various methods available in the mod
local function getNpcType(npc)
    if not npc then return nil end
    
    -- Method 1: Try to get the preset name (most reliable)
    if npc.preset and npc.preset.name then
        return npc.preset.name
    end
    
    -- Method 2: Check getDescriptor().getProfession() for profession-based mapping
    if npc.getDescriptor and npc:getDescriptor() and npc:getDescriptor().getProfession then
        local profession = npc:getDescriptor():getProfession()
        if profession and profession ~= "" then
            return profession
        end
    end
    
    -- Method 3: Check behavior tree name
    if npc.getBehaviorTree and npc:getBehaviorTree() then
        local tree = npc:getBehaviorTree()
        if tree.name then
            -- Extract "SurvivorBehaviorTree" -> "Survivor"
            local typeName = tree.name:gsub("BehaviorTree", "")
            return typeName .. "Npc"
        end
    end
    
    -- Method 4: Try to infer type from appearances and equipment
    if npc.getWornItem then
        local hasArmyClothes = false
        local hasPoliceClothes = false
        
        -- Check for military clothing
        if npc:getWornItem("Hat_Army") or 
           npc:getWornItem("Jacket_ArmyCamoGreen") or
           npc:getWornItem("Vest_BulletArmy") then
            hasArmyClothes = true
        end
        
        -- Check for police clothing
        if npc:getWornItem("Hat_Police") or 
           npc:getWornItem("Shirt_PoliceBlue") or
           npc:getWornItem("Vest_BulletPolice") then
            hasPoliceClothes = true
        end
        
        if hasArmyClothes then
            return "SoldierNpc"
        elseif hasPoliceClothes then
            return "PoliceNpc"
        end
    end
    
    -- Fallback for MP NPCs by checking tasks
    if npc.task and string.find(npc.task:lower(), "military") then
        return "SoldierNpc"
    elseif npc.task and string.find(npc.task:lower(), "police") then
        return "PoliceNpc"
    elseif npc.task and string.find(npc.task:lower(), "bandit") then
        return "BanditNpc"
    end
    
    -- Default fallback to survivor
    return "SurvivorNpc"
end

-- Get available quests for a specific NPC
local function getAvailableQuestsForNpc(npc)
    if not npc then return {} end
    
    local npcType = getNpcType(npc)
    if not npcType or not NpcQuestGivers[npcType] then return {} end
    
    local playerId = getSpecificPlayer(0):getPlayerNum()
    local availableQuests = {}
    
    -- Check each quest this NPC type can give
    for _, questId in ipairs(NpcQuestGivers[npcType]) do
        local questDef = QuestManager.getQuest(questId)
        if not questDef then goto continue end
        
        -- Check if the player has the required level
        local playerLevel = 0 -- TODO: Get player level from somewhere
        local minLevel = questDef.minLevel or 0
        
        -- Check if quest is already active or completed
        local isActive = QuestManager.hasQuest(playerId, questId)
        local isCompleted = QuestManager.hasCompletedQuest(playerId, questId)
        
        -- Quest is available if meets level requirement and not already completed
        if playerLevel >= minLevel and not isCompleted then
            table.insert(availableQuests, {
                id = questId,
                title = questDef.title,
                description = questDef.description,
                isActive = isActive
            })
        end
        
        ::continue::
    end
    
    return availableQuests
end

-- Extend the existing NPC dialogue with quest options
local function extendNpcDialogue(npc, npcId)
    if not npc or not npcId then return end
    
    -- Get available quests for this NPC
    local availableQuests = getAvailableQuestsForNpc(npc)
    if #availableQuests == 0 then return end
    
    -- Add quest options to the NPC dialogue
    local dialogueUI = getPlayerData(0).npcDialogueUI
    if not dialogueUI then return end
    
    -- Add a "Quests" option to the dialogue submenu
    -- This needs to integrate with the existing NPC dialogue UI
    -- For simplicity, we'll use our separate quest dialogue
    
    -- Show quest dialogue for the first available quest
    -- In a real implementation, you'd add a menu to let the player choose
    QuestDialogueUI.showQuestDialogue(npc, npcId, availableQuests[1].id)
end

-- Hook into the existing NPC dialogue system
-- This assumes the mod has a function that starts the dialogue with an NPC
-- We need to find and modify this function to integrate our quest system

-- Find and patch the NPC dialogue function
local originalTalkToNpc = talkToNpc
if originalTalkToNpc then
    talkToNpc = function(worldObjects, npc)
        -- Call the original function first
        originalTalkToNpc(worldObjects, npc)
        
        -- After a short delay, modify the dialogue to include quests
        -- This gives the original dialogue time to initialize
        Events.OnTick.Add(function()
            Events.OnTick.Remove(addQuestOptions)
            
            -- Add quest options to the dialogue
            extendNpcDialogue(npc, npc:getOnlineID())
        end)
        addQuestOptions = true
    end
end

-- Function to check if an NPC has quests
local function npcHasQuests(npc)
    if not npc or not npc:getModData() then return false end
    
    local npcType = npc:getModData().type
    return npcType and NpcQuestGivers[npcType] and #NpcQuestGivers[npcType] > 0
end

-- Add a "Show Quests" option to NPC context menu
local contextMenuAdded = false
local function addQuestToContextMenu(player, context, worldobjects)
    if contextMenuAdded then return end
    contextMenuAdded = true
    
    -- Check if we're in single-player or multiplayer mode
    local isSinglePlayer = not isClient() or isServer()
    
    -- Find the NPCs in the world objects
    for _, object in ipairs(worldobjects) do
        local npc = nil
        
        -- Different detection for SP vs MP
        if isSinglePlayer and instanceof(object, "IsoNpcPlayer") then
            npc = object
        elseif not isSinglePlayer and instanceof(object, "IsoPlayer") and not object:isLocalPlayer() then
            -- Check if this is an NPC in MP mode
            if isIsoNpcPlayerObject and isIsoNpcPlayerObject(object) then
                npc = object
            end
        end
        
        -- If we found an NPC
        if npc then
            -- Get available quests
            local availableQuests = getAvailableQuestsForNpc(npc)
            
            -- Only add menu option if there are quests
            if #availableQuests > 0 then
                -- Add quest option to context menu
                local option = context:addOption("Show Quests", worldobjects, function()
                    -- Show quest dialogue for the first quest
                    local npcId = npc.getOnlineID and npc:getOnlineID() or 0
                    QuestDialogueUI.showQuestDialogue(npc, npcId, availableQuests[1].id)
                end)
                
                -- Add tooltip showing available quests
                local tooltip = ISWorldObjectContextMenu.addToolTip()
                tooltip:setName("Available Quests")
                tooltip.description = ""
                
                for _, quest in ipairs(availableQuests) do
                    if quest.isActive then
                        tooltip.description = tooltip.description .. quest.title .. " (Active)\n"
                    else
                        tooltip.description = tooltip.description .. quest.title .. "\n"
                    end
                end
                
                option.toolTip = tooltip
            end
            
            break
        end
    end
end

-- Create notification window for quests
local function showQuestNotification(title, text, sound)
    if not title or not text then return end
    
    -- Create notification window
    local x = getCore():getScreenWidth() / 2 - 175
    local y = getCore():getScreenHeight() / 2 - 50
    local width = 350
    local height = 100
    
    local notif = ISModalDialog:new(x, y, width, height, title, text, nil, function() end, nil, nil)
    notif:initialise()
    notif:addToUIManager()
    
    -- Play sound if requested
    if sound then
        getSoundManager():PlaySound(sound)
    end
end

-- Register for server commands
local function onServerCommand(module, command, args)
    if module ~= "QuestSystem" then return end
    
    if command == "QuestStarted" then
        -- Show notification
        showQuestNotification("Quest Started", 
            "New quest: " .. (args.questTitle or args.questId), 
            "QuestStart")
            
    elseif command == "QuestCompleted" then
        -- Show notification
        showQuestNotification("Quest Completed", 
            "Quest completed: " .. (args.questTitle or args.questId),
            "LevelUp")
            
    elseif command == "ObjectiveCompleted" then
        -- Show notification
        showQuestNotification("Objective Completed", 
            args.objectiveDescription or "An objective has been completed",
            "UISelectListItem")
    end
end

-- Create custom sounds
local function createQuestSounds()
    getSoundManager():addSound("QuestStart", "QuestStart")
    getSoundManager():addSound("QuestComplete", "LevelUp")
    getSoundManager():addSound("ObjectiveComplete", "UISelectListItem")
end

-- Initialize the quest giver system when the game starts
Events.OnGameStart.Add(initQuestGivers)
Events.OnGameStart.Add(createQuestSounds)

-- Add quest options to the NPC context menu
Events.OnFillWorldObjectContextMenu.Add(addQuestToContextMenu)

-- Listen for server commands
Events.OnServerCommand.Add(onServerCommand)

-- Create a custom item for quest objectives that require special items
local function createQuestItems()
    -- Create intel documents
    local item = ScriptManager.instance:getItem("KnoxEventExpanded.IntelDocuments")
    if not item then
        -- Define the item properties
        item = ScriptManager.instance:createItem("KnoxEventExpanded.IntelDocuments")
        if item then
            item:DoParam("DisplayName = Intel Documents")
            item:DoParam("Type = Normal")
            item:DoParam("Icon = Paper")
            item:DoParam("Weight = 0.1")
            item:DoParam("CantBeFrozen = TRUE")
        end
    end
end

Events.OnGameBoot.Add(createQuestItems)

-- Export functions for other modules to use
return {
    initQuestGivers = initQuestGivers,
    getAvailableQuestsForNpc = getAvailableQuestsForNpc,
    getNpcType = getNpcType,
    showQuestNotification = showQuestNotification
} 