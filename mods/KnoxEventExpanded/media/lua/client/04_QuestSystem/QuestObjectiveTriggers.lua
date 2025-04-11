-- Quest Objective Triggers for Knox Event Expanded
-- Implements the missing event triggers for escort and protection objectives

require "04_QuestSystem/QuestEvents"

-- NPC escort destination checking
local escortedNpcs = {}
local protectedNpcs = {}

-- Register an NPC as being escorted for a quest
local function registerEscortedNpc(npcId, targetLocation)
    if not npcId or not targetLocation then return end
    
    escortedNpcs[npcId] = {
        targetX = targetLocation.x,
        targetY = targetLocation.y,
        targetZ = targetLocation.z or 0,
        startTime = getGameTime():getWorldAgeHours(),
        lastChecked = getGameTime():getWorldAgeHours()
    }
    
    print("Registered NPC " .. tostring(npcId) .. " for escort to location: " .. 
          tostring(targetLocation.x) .. "," .. tostring(targetLocation.y))
end

-- Register an NPC as being protected for a quest
local function registerProtectedNpc(npcId, duration)
    if not npcId then return end
    
    local startTime = getGameTime():getWorldAgeHours()
    duration = duration or 24 -- Default 24 hour protection if not specified
    
    protectedNpcs[npcId] = {
        startTime = startTime,
        endTime = startTime + duration,
        lastChecked = startTime
    }
    
    print("Registered NPC " .. tostring(npcId) .. " for protection for " .. 
          tostring(duration) .. " hours")
end

-- Check if escorted NPCs have reached their destinations
local function checkEscortObjectives()
    for npcId, data in pairs(escortedNpcs) do
        -- Get the NPC
        local npc = nil
        if isClient() then
            -- Multiplayer - get by online ID
            npc = getPlayerByOnlineID(npcId)
        else
            -- Singleplayer - assumes getNpcById exists or similar function
            npc = getNpcById and getNpcById(npcId) or nil
        end
        
        -- If NPC doesn't exist anymore, remove from tracking
        if not npc then
            escortedNpcs[npcId] = nil
            goto continue
        end
        
        -- Check if NPC has reached destination
        local npcX = npc:getX()
        local npcY = npc:getY()
        local npcZ = npc:getZ()
        
        -- Calculate distance to target (square distance is fine for comparison)
        local distance = ((npcX - data.targetX) * (npcX - data.targetX)) + 
                        ((npcY - data.targetY) * (npcY - data.targetY))
        
        -- Check if on correct floor/level
        local correctLevel = (npcZ == data.targetZ)
        
        -- If NPC is close enough to target and on correct level
        if distance < 4 and correctLevel then -- 2 tile radius
            -- Trigger the escort completion event
            QuestEvents.OnNPCReachedDestination(npcId, {x=data.targetX, y=data.targetY, z=data.targetZ})
            
            -- Remove NPC from tracking
            escortedNpcs[npcId] = nil
            
            print("NPC " .. tostring(npcId) .. " has reached destination")
        end
        
        ::continue::
    end
end

-- Check if protected NPCs are still alive and if protection period has ended
local function checkProtectionObjectives()
    local currentTime = getGameTime():getWorldAgeHours()
    
    for npcId, data in pairs(protectedNpcs) do
        -- Get the NPC
        local npc = nil
        if isClient() then
            -- Multiplayer - get by online ID
            npc = getPlayerByOnlineID(npcId)
        else
            -- Singleplayer - assumes getNpcById exists or similar function
            npc = getNpcById and getNpcById(npcId) or nil
        end
        
        -- If NPC doesn't exist anymore, protection failed
        if not npc or (npc.isDead and npc:isDead()) then
            protectedNpcs[npcId] = nil
            print("NPC " .. tostring(npcId) .. " protection failed - NPC died")
            goto continue
        end
        
        -- Check if protection period has ended
        if currentTime >= data.endTime then
            -- Trigger the protection completion event
            local duration = data.endTime - data.startTime
            QuestEvents.OnNPCSurvivalCheck(npcId, duration)
            
            -- Remove NPC from tracking
            protectedNpcs[npcId] = nil
            
            print("NPC " .. tostring(npcId) .. " has been successfully protected for " .. 
                  tostring(duration) .. " hours")
        end
        
        ::continue::
    end
end

-- Periodically check escort and protection objectives
local function onEveryTenMinutes()
    checkEscortObjectives()
    checkProtectionObjectives()
end

-- Add custom events for hooking into the quest system
Events.EveryTenMinutes.Add(onEveryTenMinutes)

-- Hook into NPC death events if they exist
if Events.OnNPCDeath then
    Events.OnNPCDeath.Add(function(npc)
        if not npc then return end
        
        local npcId = npc.getOnlineID and npc:getOnlineID() or npc.id
        if not npcId then return end
        
        -- If this NPC was being protected, mark as failed
        if protectedNpcs[npcId] then
            protectedNpcs[npcId] = nil
            print("NPC " .. tostring(npcId) .. " protection failed - NPC died")
        end
    end)
end

-- Export functions for other modules to use
return {
    registerEscortedNpc = registerEscortedNpc,
    registerProtectedNpc = registerProtectedNpc
} 