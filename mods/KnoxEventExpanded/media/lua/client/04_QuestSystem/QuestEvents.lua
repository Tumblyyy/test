-- Quest Events for Knox Event Expanded
-- Handles events that can trigger quest progress updates

require "04_QuestSystem/QuestManager"

local QuestEvents = {}

-- Track killed NPCs
local function onNPCDeath(npc)
    if not npc or not npc:getModData() or not instanceof(npc, "IsoZombie") then return end
    
    local npcType = npc:getModData().type
    if not npcType then return end
    
    local player = getSpecificPlayer(0)
    local playerId = player:getPlayerNum()
    
    -- Check all active quests for kill objectives
    local activeQuests = QuestManager.getAllActiveQuests(playerId)
    if not activeQuests then return end
    
    for questId, questInstance in pairs(activeQuests) do
        local questDef = QuestManager.getQuest(questId)
        if questDef and questDef.objectives then
            -- Go through each objective
            for i, objective in ipairs(questInstance.objectives) do
                local objDef = questDef.objectives[i]
                -- Check if this is a kill objective matching the NPC type
                if objDef.type == "kill" and objDef.targetType == npcType then
                    QuestManager.updateObjective(playerId, questId, objDef.id, 1)
                end
            end
        end
    end
end

-- Track item pickups
local function onItemPickup(player, item)
    if not player or not item then return end
    
    local playerId = player:getPlayerNum()
    
    -- Check all active quests for item collection objectives
    local activeQuests = QuestManager.getAllActiveQuests(playerId)
    if not activeQuests then return end
    
    for questId, questInstance in pairs(activeQuests) do
        local questDef = QuestManager.getQuest(questId)
        if questDef and questDef.objectives then
            -- Go through each objective
            for i, objective in ipairs(questInstance.objectives) do
                local objDef = questDef.objectives[i]
                -- Check if this is an item collection objective
                if objDef.type == "item" and objDef.items then
                    -- Check if this item is in the objective list
                    for _, itemType in ipairs(objDef.items) do
                        if item:getFullType() == itemType then
                            QuestManager.updateObjective(playerId, questId, objDef.id, 1)
                            break
                        end
                    end
                end
            end
        end
    end
end

-- Track escort objectives (NPC reached destination)
local function onNPCReachedDestination(npcId, targetLocation)
    if not npcId or not targetLocation then return end
    
    local player = getSpecificPlayer(0)
    local playerId = player:getPlayerNum()
    
    -- Check all active quests for escort objectives
    local activeQuests = QuestManager.getAllActiveQuests(playerId)
    if not activeQuests then return end
    
    for questId, questInstance in pairs(activeQuests) do
        local questDef = QuestManager.getQuest(questId)
        if questDef and questDef.objectives then
            -- Go through each objective
            for i, objective in ipairs(questInstance.objectives) do
                local objDef = questDef.objectives[i]
                -- Check if this is an escort objective matching the NPC
                if objDef.type == "escort" and objDef.targetId == npcId then
                    QuestManager.updateObjective(playerId, questId, objDef.id, 1)
                end
            end
        end
    end
end

-- Track protection objectives (NPC survived)
local function onNPCSurvivalCheck(npcId, duration)
    if not npcId or not duration then return end
    
    local player = getSpecificPlayer(0)
    local playerId = player:getPlayerNum()
    
    -- Check all active quests for protection objectives
    local activeQuests = QuestManager.getAllActiveQuests(playerId)
    if not activeQuests then return end
    
    for questId, questInstance in pairs(activeQuests) do
        local questDef = QuestManager.getQuest(questId)
        if questDef and questDef.objectives then
            -- Go through each objective
            for i, objective in ipairs(questInstance.objectives) do
                local objDef = questDef.objectives[i]
                -- Check if this is a protection objective matching the NPC
                if objDef.type == "protect" and 
                   (not objDef.targetId or objDef.targetId == npcId) and
                   (not objDef.duration or duration >= objDef.duration) then
                    QuestManager.updateObjective(playerId, questId, objDef.id, 1)
                end
            end
        end
    end
end

-- Register event handlers
Events.OnZombieDead.Add(onNPCDeath)
Events.OnItemPickup.Add(onItemPickup)

-- Custom events - these need to be triggered from the appropriate places
QuestEvents.OnNPCReachedDestination = onNPCReachedDestination
QuestEvents.OnNPCSurvivalCheck = onNPCSurvivalCheck

-- Track quest completion
local function checkItemObjectives(player)
    if not player then return end
    
    local playerId = player:getPlayerNum()
    local inventory = player:getInventory()
    
    -- Check all active quests for item collection objectives
    local activeQuests = QuestManager.getAllActiveQuests(playerId)
    if not activeQuests then return end
    
    for questId, questInstance in pairs(activeQuests) do
        local questDef = QuestManager.getQuest(questId)
        if questDef and questDef.objectives then
            -- Go through each objective
            for i, objective in ipairs(questInstance.objectives) do
                local objDef = questDef.objectives[i]
                -- Check if this is an item collection objective that isn't completed
                if objDef.type == "item" and objDef.items and not objective.completed then
                    -- Count matching items in inventory
                    local itemCount = 0
                    for _, itemType in ipairs(objDef.items) do
                        itemCount = itemCount + inventory:getItemCount(itemType)
                    end
                    
                    -- Update progress if more items found than current progress
                    local newProgress = math.min(itemCount, objDef.count)
                    if newProgress > objective.progress then
                        -- Update by the difference
                        QuestManager.updateObjective(playerId, questId, objDef.id, newProgress - objective.progress)
                    end
                end
            end
        end
    end
end

-- Periodically check item objectives
local function onEveryTenMinutes()
    local player = getSpecificPlayer(0)
    if player then
        checkItemObjectives(player)
    end
end

Events.EveryTenMinutes.Add(onEveryTenMinutes)

-- Handle server command responses
local function onServerCommand(module, command, args)
    if module ~= "QuestSystem" then return end
    
    if command == "QuestStarted" then
        -- Show notification
        player:Say("New quest started: " .. args.questTitle)
    elseif command == "QuestCompleted" then
        -- Show notification
        player:Say("Quest completed: " .. args.questTitle)
    elseif command == "ObjectiveCompleted" then
        -- Show notification
        player:Say("Objective completed: " .. args.objectiveDescription)
    end
end

Events.OnServerCommand.Add(onServerCommand)

return QuestEvents 