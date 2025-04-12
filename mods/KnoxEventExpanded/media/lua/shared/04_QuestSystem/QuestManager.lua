-- Initialize quest system with correct variable names
QuestManager = QuestManager or {}
QuestManager.quests = QuestManager.quests or {}        -- Quest definitions table (matches original)
QuestManager.playerQuests = QuestManager.playerQuests or {} -- Active player quests
QuestManager.failedQuests = QuestManager.failedQuests or {} -- Failed player quests
QuestManager.questsByGiverType = QuestManager.questsByGiverType or {} -- Quests by NPC type
QuestManager.debugMode = false -- Debug mode flag

local function debugLog(message)
    if QuestManager.debugMode then
        print("[QuestSystem] " .. message)
    end
end

-- Validate quest definition - keeping original parameters
function QuestManager.validateQuestDef(questDef)
    if not questDef then
        debugLog("ERROR: Attempted to register nil quest definition")
        return false, "Nil quest definition"
    end

    if not questDef.id then
        debugLog("ERROR: Quest definition missing ID")
        return false, "Missing ID"
    end
    
    if not questDef.title then
        debugLog("ERROR: Quest " .. questDef.id .. " missing title")
        return false, "Missing title"
    end
    
    if not questDef.description then
        debugLog("WARNING: Quest " .. questDef.id .. " missing description")
    end
    
    if not questDef.objectives or #questDef.objectives == 0 then
        debugLog("ERROR: Quest " .. questDef.id .. " has no objectives")
        return false, "No objectives"
    end
    
    -- Validate objectives
    for i, objective in ipairs(questDef.objectives) do
        if not objective.id then
            debugLog("ERROR: Quest " .. questDef.id .. " has objective without ID")
            return false, "Objective missing ID"
        end
        
        if not objective.description then
            debugLog("WARNING: Quest " .. questDef.id .. ", objective " .. objective.id .. " missing description")
        end
        
        if not objective.type then
            debugLog("ERROR: Quest " .. questDef.id .. ", objective " .. objective.id .. " missing type")
            return false, "Objective missing type"
        end
        
        -- Validate type-specific properties
        if objective.type == "item" and (not objective.items or #objective.items == 0) then
            debugLog("ERROR: Quest " .. questDef.id .. ", objective " .. objective.id .. " (item) has no items")
            return false, "Item objective missing items"
        end
        
        if objective.type == "kill" and not objective.targetType then
            debugLog("ERROR: Quest " .. questDef.id .. ", objective " .. objective.id .. " (kill) has no targetType")
            return false, "Kill objective missing targetType"
        end
        
        if objective.type == "escort" and not objective.targetId then
            debugLog("WARNING: Quest " .. questDef.id .. ", objective " .. objective.id .. " (escort) has no targetId")
        end
    end

    return true, nil
end

-- Get a quest definition by ID - was missing from my original implementation
function QuestManager.getQuest(questId)
    return QuestManager.quests[questId]
end

-- Validate objective definition
function QuestManager.validateObjectiveDef(questId, objective)
    if not objective then
        debugLog("ERROR: Quest " .. questId .. " has a nil objective.")
        return false, "Objective is nil"
    end

    if not objective.id then
        debugLog("ERROR: Quest " .. questId .. " has objective without ID")
        return false, "Objective missing ID"
    end

    if not objective.type then
        debugLog("ERROR: Quest " .. questId .. ", objective " .. objective.id .. " missing type")
        return false, "Objective missing type"
    end

    -- Validate type-specific properties
    if objective.type == "item" and (not objective.items or #objective.items == 0) then
        debugLog("ERROR: Quest " .. questId .. ", objective " .. objective.id .. " (item) has no items")
        return false, "Item objective missing items"
    end

    if objective.type == "kill" and not objective.targetType then
        debugLog("ERROR: Quest " .. questId .. ", objective " .. objective.id .. " (kill) has no targetType")
        return false, "Kill objective missing targetType"
    end

    return true, nil
end



-- Register a quest definition
function QuestManager.registerQuest(questDef)
    -- Validate quest definition
    local isValid, errorMsg = QuestManager.validateQuestDef(questDef)
    if not isValid then
        debugLog("ERROR: Failed to register quest: " .. errorMsg)
        return false
    end
    
    -- Store quest definition
    QuestManager.quests[questDef.id] = questDef
    
    -- Register quest with appropriate giver types if specified
    if questDef.giverTypes then
        for _, giverType in ipairs(questDef.giverTypes) do
            if not QuestManager.questsByGiverType[giverType] then
                QuestManager.questsByGiverType[giverType] = {}
            end
            table.insert(QuestManager.questsByGiverType[giverType], questDef.id)
        end
    end
    
    debugLog("Registered quest: " .. questDef.id)
    return true
end

-- Helper function to safely get player
function QuestManager.getSafePlayer(player)
    if not player then return nil end
    
    local playerId
    if type(player) == "number" then
        playerId = player
        player = getSpecificPlayer(player)
    else
        playerId = player:getPlayerNum()
    end
    
    return player, playerId
end

-- Start a quest for a player
function QuestManager.startQuest(player, questId)
    -- Get safe player reference
    player, playerId = QuestManager.getSafePlayer(player)
    if not player then
        debugLog("Failed to start quest: Invalid player")
        return false
    end
    
    -- Check if quest exists
    local questDef = QuestManager.quests[questId]
    if not questDef then
        debugLog("Failed to start quest: Quest ID '" .. questId .. "' not found")
        return false
    end
    
    -- Check if player meets requirements
    if questDef.requirements and not QuestManager.meetsRequirements(player, questDef) then
        debugLog("Player does not meet requirements for quest: " .. questId)
        return false
    end
    
    -- Initialize player quests table if needed
    if not QuestManager.playerQuests[playerId] then
        QuestManager.playerQuests[playerId] = {}
    end
    
    -- Check if already has quest
    if QuestManager.playerQuests[playerId][questId] then
        debugLog("Player " .. playerId .. " already has quest: " .. questId)
        return false
    end
    
    -- Check if already failed the quest and not repeatable
    if QuestManager.failedQuests[playerId] and 
       QuestManager.failedQuests[playerId][questId] and
       not questDef.repeatable then
        debugLog("Player " .. playerId .. " already failed quest: " .. questId)
        return false
    end
    
    -- Create quest instance
    local questInstance = {
        id = questId,
        started = true,
        completed = false,
        failed = false,
        startTime = getGameTime():getWorldAgeHours(),
        objectives = {},
        objectivesCompleted = {},
        objectiveCompletionTimes = {}
    }
    
     -- Initialize objectives
    for _, objectiveDef in ipairs(questDef.objectives) do
         local isValid, errorMsg = QuestManager.validateObjectiveDef(questId, objectiveDef)
         if isValid then
             questInstance.objectives[objectiveDef.id] = {
                 completed = false, progress = 0, maxProgress = objectiveDef.count or 1, available = not objectiveDef.requires }
         else
             debugLog("ERROR: Invalid objective in quest " .. questId .. ": " .. errorMsg)
             return false
         end
    }
    
    -- Set time limit if defined
    if questDef.timeLimit then
        questInstance.expirationTime = questInstance.startTime + questDef.timeLimit
    end
    
    -- Store in player quests
    QuestManager.playerQuests[playerId][questId] = questInstance
    
    -- Notify client
    if isServer() then
         sendServerCommand(player, "QuestSystem", "QuestStarted", {
             questId = questId,
             questTitle = questDef.title,
             questDescription = questDef.description,
             timeLimit = questDef.timeLimit
         })

         -- Send initial objectives that are available
         for _, objective in ipairs(questDef.objectives) do
             if not objective.requires then
                 sendServerCommand(player, "QuestSystem", "ObjectiveAdded", {
                     questId = questId,
                     objectiveId = objective.id,
                     objectiveDescription = objective.description
                 })
             end
         end
     end

    debugLog("Started quest: " .. questId .. " for player: " .. tostring(playerId))
    return true
end

-- Check if a player meets quest requirements
function QuestManager.meetsRequirements(player, questDef)
    player, playerId = QuestManager.getSafePlayer(player)
    if not player then return false end
    
    -- If no requirements, always meets them
    if not questDef.requirements then return true end
    
    local req = questDef.requirements
    
    -- Check level requirement
    if req.level and player:getLevel() < req.level then
        return false
    end
    
    -- Check skill requirements
    if req.skills then
        for skillName, level in pairs(req.skills) do
            local perk = Perks.FromString(skillName)
            if player:getPerkLevel(perk) < level then
                return false
            end
        end
    end
    
    -- Check zone requirements
    if req.zone then
        local playerX, playerY = player:getX(), player:getY()
        local inValidZone = false
        
        if type(req.zone) == "table" and req.zone.x1 then
            -- Single zone definition
            inValidZone = (playerX >= req.zone.x1 and playerX <= req.zone.x2 and
                          playerY >= req.zone.y1 and playerY <= req.zone.y2)
        elseif type(req.zone) == "table" then
            -- Multiple zones
            for _, zone in ipairs(req.zone) do
                if playerX >= zone.x1 and playerX <= zone.x2 and
                   playerY >= zone.y1 and playerY <= zone.y2 then
                    inValidZone = true
                    break
                end
            end
        end
        
        if not inValidZone then return false end
    end
    
    -- Check item requirements
    if req.items then
        local inventory = player:getInventory()
        for itemName, count in pairs(req.items) do
            if inventory:getItemCount(itemName) < count then
                return false
            end
        end
    end
    
    -- Check trait requirements
    if req.traits then
        for _, trait in ipairs(req.traits) do
            if not player:HasTrait(trait) then
                return false
            end
        end
    end
    
    -- Check reputation requirements
    if req.reputation then
         local playerData = ModData.get("PlayerData")
         if not playerData then
             debugLog("Warning: PlayerData is nil")
             return false
         end
         if not playerData[playerId] or not playerData[playerId].reputation then
             debugLog("Warning: PlayerData for player " .. playerId .. " is incomplete")
             return false
         end


        for faction, minRep in pairs(req.reputation) do
            if (playerData[playerId].reputation[faction] or 0) < minRep then
                return false
            end
        end
    end
    
    return true
end

-- Check if objective prerequisites are met
function QuestManager.isObjectiveAvailable(player, questId, objectiveId)
    player, playerId = QuestManager.getSafePlayer(player)
    if not player then return false end
    
    local questInstance = QuestManager.playerQuests[playerId][questId]
    if not questInstance then return false end
    
     local questDef = QuestManager.quests[questId]
     if not questDef then return false end

     -- Find the objective definition
     local objectiveDef = nil
     for _, obj in ipairs(questDef.objectives) do
         if obj.id == objectiveId then
            objectiveDef = obj
            break
        end
    end
    
    if not objectiveDef then return false end
    
     -- If no requires, it's always available
     if not objectiveDef.requires then return true end

     -- Check requirements
    if type(objectiveDef.requires) == "string" then
        -- Single requirement
        return questInstance.objectivesCompleted[objectiveDef.requires] == true
    elseif type(objectiveDef.requires) == "table" then
        -- Multiple requirements
        if objectiveDef.requireAll then
            -- Need all prerequisites
            for _, reqId in ipairs(objectiveDef.requires) do
                if not questInstance.objectivesCompleted[reqId] then
                    return false
                end
            end
            return true
        else
            -- Need any prerequisite
            for _, reqId in ipairs(objectiveDef.requires) do
                if questInstance.objectivesCompleted[reqId] then
                    return true
                end
            end
            return false
        end
    end
    
    return false
end

-- Update objective progress
function QuestManager.updateObjective(player, questId, objectiveId, progress)
    -- Get safe player reference
    player, playerId = QuestManager.getSafePlayer(player)
    if not player then
        debugLog("Failed to update objective: Invalid player")
        return false
    end
    
    -- Check if player has the quest
    if not QuestManager.playerQuests[playerId] or 
       not QuestManager.playerQuests[playerId][questId] then
        debugLog("Player " .. playerId .. " doesn't have quest: " .. questId)
        return false
    end
    
    local questInstance = QuestManager.playerQuests[playerId][questId]
    
    -- Check if quest is completed or failed
    if questInstance.completed or questInstance.failed then
        debugLog("Can't update objective for completed/failed quest: " .. questId)
        return false
    end
    
    -- Check if objective exists
    if not questInstance.objectives[objectiveId] then
        debugLog("Objective '" .. objectiveId .. "' not found in quest: " .. questId)
        return false
    end
    
    local objective = questInstance.objectives[objectiveId]
    
    -- Check if objective is already completed
    if objective.completed then
        debugLog("Objective '" .. objectiveId .. "' already completed")
        return false
    end
    
    -- Check if objective is available
    if not objective.available then
        if QuestManager.isObjectiveAvailable(player, questId, objectiveId) then
            objective.available = true
            -- Notify client about newly available objective
            if isServer() then
                 local objDef = nil
                for _, def in ipairs(QuestManager.quests[questId].objectives) do
                    if def.id == objectiveId then objDef = def; break end
                end
                
                if objDef then
                    sendServerCommand(player, "QuestSystem", "ObjectiveAdded", {
                        questId = questId, 
                        objectiveId = objectiveId,
                        objectiveDescription = objDef.description
                    })
                end
            end
        else
             -- Objective not available, log it
            debugLog("Objective '" .. objectiveId .. "' not available yet")
            return false
        end
    end
    
    -- Update progress
    local newProgress = progress or 1
    objective.progress = objective.progress + newProgress
    
    -- Check if objective is completed
    if objective.progress >= objective.maxProgress then
        objective.completed = true
        objective.progress = objective.maxProgress
        objective.completionTime = getGameTime():getWorldAgeHours()
        
        -- Track completion for condition checks
         questInstance.objectivesCompleted[objectiveId] = true
         questInstance.objectiveCompletionTimes[objectiveId] = objective.completionTime

         debugLog("Completed objective: " .. objectiveId .. " for quest: " .. questId)
        
        -- Update availability of other objectives
        for id, obj in pairs(questInstance.objectives) do
            if not obj.completed and not obj.available then
                if QuestManager.isObjectiveAvailable(player, questId, id) then
                    obj.available = true
                    
                     -- Notify client about newly available objective
                    if isServer() then
                        local objDef = nil
                        for _, def in ipairs(QuestManager.quests[questId].objectives) do
                            if def.id == id then objDef = def; break end
                        end
                        
                        if objDef then
                            sendServerCommand(player, "QuestSystem", "ObjectiveAdded", {
                                questId = questId, 
                                objectiveId = id,
                                objectiveDescription = objDef.description
                            })
                        end
                     end
                    end
                end
            end
        end
        
        -- Check if all available objectives are completed
        local allCompleted = true
        for id, obj in pairs(questInstance.objectives) do
            if obj.available and not obj.completed then
                allCompleted = false
                break
            end
        end

        -- Complete quest if all available objectives are completed
        if allCompleted then
            QuestManager.completeQuest(player, questId)
        end
     end

     -- Notify client
    if isServer() then
        sendServerCommand(player, "QuestSystem", "ObjectiveUpdated", {
            questId = questId,
            objectiveId = objectiveId,
            progress = objective.progress,
            maxProgress = objective.maxProgress,
            completed = objective.completed
        })
    end
    
    return true
end

-- Complete a quest
function QuestManager.completeQuest(player, questId)
    -- Get safe player reference
    player, playerId = QuestManager.getSafePlayer(player)
    if not player then
        debugLog("Failed to complete quest: Invalid player")
        return false
    end
    
    -- Check if player has the quest
    if not QuestManager.playerQuests[playerId] or 
       not QuestManager.playerQuests[playerId][questId] then
        debugLog("Player " .. playerId .. " doesn't have quest: " .. questId)
        return false
    end
    
    local questInstance = QuestManager.playerQuests[playerId][questId]
    local quest = QuestManager.quests[questId]
    
    -- Check if quest is already completed or failed
    if questInstance.completed then
        debugLog("Quest '" .. questId .. "' already completed")
        return false
    end
    
    if questInstance.failed then
        debugLog("Can't complete failed quest: " .. questId)
        return false
    end
    
    -- Mark as completed
    questInstance.completed = true
    questInstance.completionTime = getGameTime():getWorldAgeHours()
    
    -- Give rewards if any
    if quest.rewards then
        for _, reward in ipairs(quest.rewards) do
            if reward.type == "item" then
                -- Handle item count
                local count = reward.count or 1
                for i=1,count do
                    player:getInventory():AddItem(reward.item)
                end
            elseif reward.type == "xp" then
                player:getXp():AddXP(Perks.FromString(reward.skill), reward.amount)
            elseif reward.type == "reputation" then
                -- Handle reputation rewards
                 local playerData = ModData.get("PlayerData")
                 if not playerData then
                     playerData = {} -- Initialize if nil
                 end

                playerData[playerId] = playerData[playerId] or {}
                playerData[playerId].reputation = playerData[playerId].reputation or {}
                playerData[playerId].reputation[reward.faction] = 
                    (playerData[playerId].reputation[reward.faction] or 0) + reward.amount
                ModData.add("PlayerData", playerData)
            end
        end
    end
    
     -- Run custom completion function if defined
    if quest.onComplete and type(quest.onComplete) == "function" then
        quest.onComplete(player, questInstance)
    end
    
    -- Unlock follow-up quests if any
    if quest.nextQuests then
        if type(quest.nextQuests) == "string" then
            -- Single next quest
            if QuestManager.meetsRequirements(player, QuestManager.quests[quest.nextQuests]) then
                if quest.autoStartNext then
                    QuestManager.startQuest(player, quest.nextQuests)
                else
                    -- Mark as available
                    player:getModData().availableQuests = player:getModData().availableQuests or {}
                    player:getModData().availableQuests[quest.nextQuests] = true
                end
            end
        elseif type(quest.nextQuests) == "table" then
            -- Multiple possible next quests
            for _, nextQuestId in ipairs(quest.nextQuests) do
                if QuestManager.meetsRequirements(player, QuestManager.quests[nextQuestId]) then
                    if quest.autoStartNext then
                        QuestManager.startQuest(player, nextQuestId)
                    else
                        -- Mark as available
                        player:getModData().availableQuests = player:getModData().availableQuests or {}
                        player:getModData().availableQuests[nextQuestId] = true
                    end
                end
            end
        end
    end
    
     -- Notify client
    if isServer() then
        sendServerCommand(player, "QuestSystem", "QuestCompleted", {
            questId = questId,
            questTitle = quest.title,
            questDescription = quest.description,
            rewards = quest.rewards
        })
    end
    
    debugLog("Completed quest: " .. questId .. " for player: " .. tostring(playerId))
    return true
end

-- Fail a quest
function QuestManager.failQuest(player, questId, reason)
    -- Get safe player reference
    player, playerId = QuestManager.getSafePlayer(player)
    if not player then
        debugLog("Failed to fail quest: Invalid player")
        return false
    end
    
    -- Check if player has the quest
    if not QuestManager.playerQuests[playerId] or 
       not QuestManager.playerQuests[playerId][questId] then
        debugLog("Player " .. playerId .. " doesn't have quest: " .. questId)
        return false
    end
    
    local questInstance = QuestManager.playerQuests[playerId][questId]
    
    -- Check if quest is already completed or failed
    if questInstance.completed then
        debugLog("Can't fail completed quest: " .. questId)
        return false
    end
    
    if questInstance.failed then
        debugLog("Quest '" .. questId .. "' already failed")
        return false
    end
    
    -- Mark as failed
    questInstance.failed = true
    questInstance.failReason = reason or "Unknown reason"
    questInstance.failTime = getGameTime():getWorldAgeHours()
    
    -- Store in failed quests
    if not QuestManager.failedQuests[playerId] then
        QuestManager.failedQuests[playerId] = {}
    end
    
    QuestManager.failedQuests[playerId][questId] = questInstance
    
     -- Run custom failure function if defined
    local quest = QuestManager.quests[questId]
    if quest.onFail and type(quest.onFail) == "function" then
        quest.onFail(player, questInstance)
    end
    
    -- Notify client
    if isServer() then
        sendServerCommand(player, "QuestSystem", "QuestFailed", {
            questId = questId,
            questTitle = quest.title,
            reason = questInstance.failReason
        })
    end
    
    debugLog("Failed quest: " .. questId .. " for player: " .. tostring(playerId) .. " - Reason: " .. questInstance.failReason)
    return true
end

-- Check if a player has a quest
function QuestManager.hasQuest(player, questId)
    -- Get safe player reference
    player, playerId = QuestManager.getSafePlayer(player)
    if not player then return false end
    
    return QuestManager.playerQuests[playerId] and 
           QuestManager.playerQuests[playerId][questId] ~= nil
end

-- Check if a player has completed a quest
function QuestManager.hasCompletedQuest(player, questId)
    -- Get safe player reference
    player, playerId = QuestManager.getSafePlayer(player)
    if not player then return false end
    
    return QuestManager.playerQuests[playerId] and 
           QuestManager.playerQuests[playerId][questId] and
           QuestManager.playerQuests[playerId][questId].completed
end

-- Check if a player has failed a quest
function QuestManager.hasFailedQuest(player, questId)
    -- Get safe player reference
    player, playerId = QuestManager.getSafePlayer(player)
    if not player then return false end
    
    return QuestManager.failedQuests[playerId] and 
           QuestManager.failedQuests[playerId][questId] ~= nil
end

-- Reset a failed quest
function QuestManager.resetFailedQuest(player, questId)
    -- Get safe player reference
    player, playerId = QuestManager.getSafePlayer(player)
    if not player then
        debugLog("Failed to reset quest: Invalid player")
        return false
    end
    
    -- Check if player has failed the quest
    if not QuestManager.failedQuests[playerId] or 
       not QuestManager.failedQuests[playerId][questId] then
        debugLog("Player " .. playerId .. " hasn't failed quest: " .. questId)
        return false
    end
    
    -- Remove from failed quests
    QuestManager.failedQuests[playerId][questId] = nil
    
    debugLog("Reset failed quest: " .. questId .. " for player: " .. tostring(playerId))
    return true
end

-- Get all quests for a specific NPC type
function QuestManager.getQuestsForNpcType(npcType, player)
    player, playerId = QuestManager.getSafePlayer(player)
    if not player then return {} end
    
    local availableQuests = {}
    local npcQuests = QuestManager.questsByGiverType[npcType] or {}
    
    for _, questId in ipairs(npcQuests) do
        local quest = QuestManager.quests[questId]
        if quest and QuestManager.meetsRequirements(player, quest) then
            -- Check if player has already completed the quest
            if quest.repeatable or not QuestManager.hasCompletedQuest(player, questId) then
                -- Check if player has already failed and it's not repeatable
                if quest.repeatable or not QuestManager.hasFailedQuest(player, questId) then
                    table.insert(availableQuests, quest)
                end
            end
        end
    end
    
    return availableQuests
end

-- Save quest data
function QuestManager.saveData()
    local saveData = {
        playerQuests = QuestManager.playerQuests,
        failedQuests = QuestManager.failedQuests
    }
    
    ModData.add("QuestSystem", saveData)
    debugLog("Saved quest data")
end

-- Load quest data
function QuestManager.loadData()
    local saveData = ModData.get("QuestSystem")
    if saveData then
        QuestManager.playerQuests = saveData.playerQuests or {}
        QuestManager.failedQuests = saveData.failedQuests or {}
        debugLog("Loaded quest data")
    else
        QuestManager.playerQuests = {}
        QuestManager.failedQuests = {}
        debugLog("No saved quest data found")
    end
end

-- Register event handlers for objective updates
function QuestManager.registerEventHandlers()
    -- Zombie kill event
    Events.OnZombieDead.Add(function(zombie, player)
        if not player or not player:isAlive() then return end
        local playerId = player:getPlayerNum()
        if not QuestManager.playerQuests[playerId] then return end
        
        for questId, questInstance in pairs(QuestManager.playerQuests[playerId]) do
            if not questInstance.completed and not questInstance.failed then
                 local questDef = QuestManager.quests[questId]
                
                for _, objective in ipairs(questDef.objectives) do
                    if objective.type == "kill" and 
                       questInstance.objectives[objective.id] and
                       not questInstance.objectives[objective.id].completed then
                        
                        -- Check if zombie type matches
                        if not objective.targetType or zombie:getZombieType() == objective.targetType then
                             QuestManager.updateObjective(player, questId, objective.id, 1)
                        end
                    end
                end
            end
        end
    end)
    
    -- Item inventory check (runs periodically)
    Events.EveryTenMinutes.Add(function()
        for playerId, playerQuests in pairs(QuestManager.playerQuests) do
            local player = getSpecificPlayer(playerId)
             if not player or not player:isAlive() then return end

             local inventory = player:getInventory()
             if not inventory then return end

             for questId, questInstance in pairs(playerQuests) do
                 if not questInstance.completed and not questInstance.failed then
                     local questDef = QuestManager.quests[questId]

                     for _, objective in ipairs(questDef.objectives) do
                         if objective.type == "item" and
                            questInstance.objectives[objective.id] and
                            not questInstance.objectives[objective.id].completed and
                            objective.items then -- Check if objective.items exists

                             -- Check for each required item
                             local allItemsFound = true
                             for _, itemDef in ipairs(objective.items) do
                                 if itemDef and itemDef.itemType then  -- Add nil check for itemDef
                                     local itemType = itemDef.itemType
                                     local count = itemDef.count or 1

                                     if inventory:getItemCount(itemType) < count then
                                         allItemsFound = false
                                         break
                                     end
                                 else
                                     allItemsFound = false -- If itemDef is nil, objective cannot be completed
                                     break
                                 end
                             end

                             if allItemsFound and questInstance.objectives[objective.id].available then
                                 QuestManager.updateObjective(player, questId, objective.id, 1)
                             end
                         end
                     end
                 end
             end
        end
    end)
    
    -- Location check
    Events.OnPlayerUpdate.Add(function(player)
        -- Only check every few seconds for performance
        if player:getHoursSurvived() % (1/720) > 0.0001 then return end
        
         local playerId = player:getPlayerNum()
         if not QuestManager.playerQuests[playerId] then return end

         local playerX, playerY = player:getX(), player:getY()

         for questId, questInstance in pairs(QuestManager.playerQuests[playerId]) do
             if not questInstance.completed and not questInstance.failed then
                 local questDef = QuestManager.quests[questId]

                 for _, objective in ipairs(questDef.objectives) do
                     if objective.type == "location" and
                        questInstance.objectives[objective.id] and
                        not questInstance.objectives[objective.id].completed and
                        questInstance.objectives[objective.id].available and
                        objective.location then --Check if location exists

                         local distance = math.sqrt(
                             (playerX - objective.location.x)^2 +
                             (playerY - objective.location.y)^2
                         )
                         if distance <= 2 then -- 2 tiles for completion
                             QuestManager.updateObjective(player, questId, objective.id, 1)
                         end
                     end
                 end
             end
         end
        end
    end)