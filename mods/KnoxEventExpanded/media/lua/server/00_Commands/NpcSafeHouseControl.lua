local function handleKnoxEventNpcSafeHouseControl(_command, _player, _table)
    local npcId = tonumber(_table["npcId"]);
    local npcObj = KnoxEventNpcAPI.instance:getNpcFromOnlineId(npcId);
    if npcObj == nil then
        print("No Npc with id " .. tostring(npcId));
        return;
    end
    if _command == "NpcBarricade" then
        npcObj:setGoal("SafehouseSubTree");
        npcObj:setSubGoal("BarricadeSubTree");
        print("NPC with id " .. tostring(npcId) .. " told to barricade");
    elseif _command == "NpcChopTrees" then
        npcObj:setGoal("SafehouseSubTree");
        npcObj:setSubGoal("ChopTreesSubTree");
        print("NPC with id " .. tostring(npcId) .. " told to chop trees");
    elseif _command == "NpcCorpseDump" then
        npcObj:setGoal("SafehouseSubTree");
        npcObj:setSubGoal("CorpseDumpSubTree");
        print("NPC with id " .. tostring(npcId) .. " told to dump corpses");
    elseif _command == "NpcDumpLoot" then
        npcObj:setGoal("SafehouseSubTree");
        npcObj:setSubGoal("DumpLootSubTree");
    elseif _command == "NpcGuard" then
        npcObj:setGoal("SafehouseSubTree");
        npcObj:setSubGoal("GuardSubTree");
        print("NPC with id " .. tostring(npcId) .. " told to guard");
    elseif _command == "NpcRest" or _command == "NpcReturnToSafehouse" then
        npcObj:setGoal("SafehouseSubTree");
        npcObj:setSubGoal("RestSubTree");
        print("NPC with id " .. tostring(npcId) .. " told to rest");
    else
        print("Received unknown command " .. tostring(_command));
    end
end
local function npcSafeHouseControlCommandHandler(_module, _command, _player, _table)
    if _module == "KnoxEventNpcSafeHouseControl" then
        print("Received command " .. tostring(_command) .. " for module " .. tostring(_module));
        handleKnoxEventNpcSafeHouseControl(_command, _player, _table);
    end
end

Events.OnClientCommand.Add(npcSafeHouseControlCommandHandler)