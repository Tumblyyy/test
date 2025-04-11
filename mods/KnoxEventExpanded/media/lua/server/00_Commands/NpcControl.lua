local function handleKnoxEventNpcControl(_command, _player, _table)
    if _command == "NpcSync" then
    elseif _command == "NpcSpeak" then
        local npcId = tonumber(_table["npcId"]);
        local npcObj = KnoxEventNpcAPI.instance:getNpcFromOnlineId(npcId);
        if npcObj == nil then
            print("No Npc with id " .. tostring(npcId));
            return;
        end
        print("NPC with id " ..  tostring(npcId) .. " asked to speak with");
        local tree = npcObj:getBehaviorTree();
        local dialogueNode = tree:getChildWithName("DialogueSubTree");
        dialogueNode:clearAllDataRecursive();
        dialogueNode:setData("DialogueSubTreeIsSpeaking", true);
        dialogueNode:setData("DialogueSubTreeSpeaker", _player);
    elseif _command == "NpcSmallTalkWeather" then
        local npcId = tonumber(_table["npcId"]);
        local npcObj = KnoxEventNpcAPI.instance:getNpcFromOnlineId(npcId);
        if npcObj == nil then
            print("No Npc with id " .. tostring(npcId));
            return;
        end
        print("NPC with id " ..  tostring(npcId) .. " asked to small talk");
        local tree = npcObj:getBehaviorTree();
        local dialogueNode = tree:getChildWithName("DialogueSubTree");
        dialogueNode:setData("DialogueSubTreeSpeakSubMenu", 1.0);
        dialogueNode:setData("DialogueSubTreeSpeakOption", 1.0);
    elseif _command == "NpcSmallTalkAge" then
        local npcId = tonumber(_table["npcId"]);
        local npcObj = KnoxEventNpcAPI.instance:getNpcFromOnlineId(npcId);
        if npcObj == nil then
            print("No Npc with id " .. tostring(npcId));
            return;
        end
        print("NPC with id " ..  tostring(npcId) .. " asked about age");
        local tree = npcObj:getBehaviorTree();
        local dialogueNode = tree:getChildWithName("DialogueSubTree");
        dialogueNode:setData("DialogueSubTreeSpeakSubMenu", 1.0);
        dialogueNode:setData("DialogueSubTreeSpeakOption", 2.0);
    elseif _command == "NpcSmallTalkOccupation" then
        local npcId = tonumber(_table["npcId"]);
        local npcObj = KnoxEventNpcAPI.instance:getNpcFromOnlineId(npcId);
        if npcObj == nil then
            print("No Npc with id " .. tostring(npcId));
            return;
        end
        print("NPC with id " ..  tostring(npcId) .. " asked about occupation");
        local tree = npcObj:getBehaviorTree();
        local dialogueNode = tree:getChildWithName("DialogueSubTree");
        dialogueNode:setData("DialogueSubTreeSpeakSubMenu", 1.0);
        dialogueNode:setData("DialogueSubTreeSpeakOption", 3.0);
    elseif _command == "NpcAskRecent" then
        local npcId = tonumber(_table["npcId"]);
        local npcObj = KnoxEventNpcAPI.instance:getNpcFromOnlineId(npcId);
        if npcObj == nil then
            print("No Npc with id " .. tostring(npcId));
            return;
        end
        print("NPC with id " ..  tostring(npcId) .. " asked about background");
        local tree = npcObj:getBehaviorTree();
        local dialogueNode = tree:getChildWithName("DialogueSubTree");
        dialogueNode:setData("DialogueSubTreeSpeakSubMenu", 0.0);
        dialogueNode:setData("DialogueSubTreeSpeakOption", 2.0);
    elseif _command == "NpcSpeakBack" then
        local npcId = tonumber(_table["npcId"]);
        local npcObj = KnoxEventNpcAPI.instance:getNpcFromOnlineId(npcId);
        if npcObj == nil then
            print("No Npc with id " .. tostring(npcId));
            return;
        end
        print("NPC with id " ..  tostring(npcId) .. " back to main dialogue menu");
        local tree = npcObj:getBehaviorTree();
        local dialogueNode = tree:getChildWithName("DialogueSubTree");
        dialogueNode:setData("DialogueSubTreeSpeakSubMenu", 0.0);
    elseif _command == "NpcStopTalk" then
        local npcId = tonumber(_table["npcId"]);
        local npcObj = KnoxEventNpcAPI.instance:getNpcFromOnlineId(npcId);
        if npcObj == nil then
            print("No Npc with id " .. tostring(npcId));
            return;
        end
        print("NPC with id " ..  tostring(npcId) .. " asked to leave");
        local tree = npcObj:getBehaviorTree();
        local dialogueNode = tree:getChildWithName("DialogueSubTree");
        dialogueNode:setData("DialogueSubTreeSpeakSubMenu", 0.0);
        dialogueNode:setData("DialogueSubTreeSpeakOption", 4.0);
    elseif _command == "NpcGiveWeapon" then
        local npcId = tonumber(_table["npcId"]);
        local npcWeapon = tostring(_table["weaponName"]);
        local npcObj = KnoxEventNpcAPI.instance:getNpcFromOnlineId(npcId);
        if npcObj == nil then
            print("No Npc with id " .. tostring(npcId));
            return;
        end
        print("Npc equipping weapon " .. tostring(npcWeapon));
        local weaponItem = InventoryItemFactory.CreateItem(npcWeapon);
        local playerInventory = npcObj:getInventory();
        playerInventory:addItem(weaponItem);

        local primary = npcObj:getPrimaryHandItem();
        if primary then
            npcObj:moveWeaponToBackpack(primary);
        end

        local secondary = npcObj:getSecondaryHandItem();
        if secondary then
            npcObj:moveWeaponToBackpack(secondary);
        end
        npcObj:setPrimaryHandItem(weaponItem);
        npcObj:setSecondaryHandItem(weaponItem);
    elseif _command == "NpcJoinGroup" then
        local npcId = tonumber(_table["npcId"]);
        local npcObj = KnoxEventNpcAPI.instance:getNpcFromOnlineId(npcId);
        if npcObj == nil then
            print("No Npc with id " .. tostring(npcId));
            return;
        end
        print("NPC with id " .. tostring(npcId) .. " asked to join group");
        group = KnoxEventNpcAPI.instance:getGroupFromPlayer(_player);
        group:joinGroup(npcObj);
    elseif _command == "NpcLeaveGroup" then
        local npcId = tonumber(_table["npcId"]);
        local npcObj = KnoxEventNpcAPI.instance:getNpcFromOnlineId(npcId);
        if npcObj == nil then
            print("No Npc with id " .. tostring(npcId));
            return;
        end
        print("NPC with id " .. tostring(npcId) .. " asked to leave group");
        local group = _player:getGroup();
        group:leaveGroup(npcObj);
    elseif _command == "NpcToggleGroupAggressive" then
        local group = _player:getGroup();
        if group then
            group:toggleAggressive();
        end
    elseif _command == "NpcToggleGroupRetreat" then
        local group = _player:getGroup();
        if group then
            group:toggleRetreat();
        end
    elseif _command == "NpcSetGroupChopTreesArea" then
        local x1 = tonumber(_table["startX"]);
        local y1 = tonumber(_table["startY"]);
        local x2 = tonumber(_table["endX"]);
        local y2 = tonumber(_table["endY"]);
        local group = _player:getGroup();
        if group then
            group:setChopTreesArea(x1, y1, x2, y2);
        end
    elseif _command == "NpcSetGroupCorpseClearArea" then
        local x1 = tonumber(_table["startX"]);
        local y1 = tonumber(_table["startY"]);
        local x2 = tonumber(_table["endX"]);
        local y2 = tonumber(_table["endY"]);
        local group = _player:getGroup();
        if group then
            group:setCorpseClearArea(x1, y1, x2, y2);
        end
    elseif _command == "NpcSetGroupCorpseDumpArea" then
        local x1 = tonumber(_table["startX"]);
        local y1 = tonumber(_table["startY"]);
        local x2 = tonumber(_table["endX"]);
        local y2 = tonumber(_table["endY"]);
        local group = _player:getGroup();
        if group then
            group:setCorpseDumpArea(x1, y1, x2, y2);
        end
    elseif _command == "NpcSetGroupGuardArea" then
        local x1 = tonumber(_table["startX"]);
        local y1 = tonumber(_table["startY"]);
        local x2 = tonumber(_table["endX"]);
        local y2 = tonumber(_table["endY"]);
        local group = _player:getGroup();
        if group then
            group:setGuardArea(x1, y1, x2, y2);
        end
    elseif _command == "NpcGroupInfo" then
    end
end

local function npcControlCommandHandler(_module, _command, _player, _table)
    if _module == "KnoxEventNpcControl" then
        print("Received command " .. tostring(_command) .. " for module " .. tostring(_module));
        handleKnoxEventNpcControl(_command, _player, _table);
    end
end

Events.OnClientCommand.Add(npcControlCommandHandler)