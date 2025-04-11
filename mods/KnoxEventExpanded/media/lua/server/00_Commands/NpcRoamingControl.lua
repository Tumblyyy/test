local function handleKnoxEventNpcRoamingControl(_command, _player, _table)
    if _command == "NpcFollow" then
        local npcId = tonumber(_table["npcId"]);
        local npcObj = KnoxEventNpcAPI.instance:getNpcFromOnlineId(npcId);
        if npcObj == nil then
            print("No Npc with id " .. tostring(npcId));
            return;
        end
        npcObj:setGoal("RoamingSubTree");
		npcObj:setSubGoal("FollowSubTree");
		print("NPC with id " .. tostring(npcId) .. " told to follow player");
    elseif _command == "NpcStay" then
        local npcId = tonumber(_table["npcId"]);
        local x = tonumber(_table["tx"]);
        local y = tonumber(_table["ty"]);
        local z = tonumber(_table["tz"]);
        local npcObj = KnoxEventNpcAPI.instance:getNpcFromOnlineId(npcId);
        if npcObj == nil then
            print("No Npc with id " .. tostring(npcId));
            return;
        end
        npcObj:setGoal("RoamingSubTree");
		npcObj:setSubGoal("StaySubTree");
        local tree = npcObj:getBehaviorTree();
        local staySubTreeNode = tree:getChildWithName("StaySubTree");
        local stayMovementNode = staySubTreeNode:getChildWithName("MovementSubTree");
        stayMovementNode:setData("MovementSubTreeTargetX", x);
        stayMovementNode:setData("MovementSubTreeTargetY", y);
        stayMovementNode:setData("MovementSubTreeTargetZ", z);
        print("NPC " .. tostring(npcObj:getUsername()) .. " told to stay at " .. tostring(x) .. "," .. tostring(y) .. "," .. tostring(z));
    elseif _command == "NpcScavenge" then
        local npcs = _table["npcs"];
        local x = tonumber(_table["centerX"])
        local y = tonumber(_table["centerY"])
        local length = tonumber(_table["length"])
        local scavengeRegion = ScavengeRegion.new(x, y, length);
        local i = 0;
        for _, npc in ipairs(npcs) do
            local npcId = tonumber(npc);
            local npcObj = KnoxEventNpcAPI.instance:getNpcFromOnlineId(npcId);
            if npcObj == nil then
                print("No Npc with id " .. tostring(npcId));
                return;
            end
            npcObj:setGoal("RoamingSubTree");
            npcObj:setSubGoal("ScavengeSubTree");
            local tree = npcObj:getBehaviorTree();
            local node = tree:getChildWithName("ScavengeSubTree");
            local lootAmmo = _table["ammo"];
            local lootFirstAid = _table["firstaid"];
            local lootFood = _table["food"];
            local lootGuns = _table["guns"];
            local lootMaterials = _table["materials"];
            local lootTools = _table["tools"];
            local lootWater = _table["water"];
            local lootWeapons = _table["weapons"];

            node:setData("ScavengeSubTreeScavengeRegion", scavengeRegion);
            node:setData("LootingSubTreeCategoryAmmo", lootAmmo);
            node:setData("LootingSubTreeCategoryFood", lootFood);
            node:setData("LootingSubTreeCategoryFirstAid", lootFirstAid);
            node:setData("LootingSubTreeCategoryMats", lootMaterials);
            node:setData("LootingSubTreeCategoryGuns", lootGuns);
            node:setData("LootingSubTreeCategoryTools", lootTools);
            node:setData("LootingSubTreeCategoryWater", lootWater);
            node:setData("LootingSubTreeCategoryWeapons", lootWeapons);
            print("NPC with id " .. tostring(npcId) .. " told to scavenge");
            if i == 0 then
                npcObj:Say("Scavenge now? If you say so...");
            end
            i = i + i;
        end
    elseif _command == "NpcLoot" then
        local npcs = _table["npcs"];
        local x = tonumber(_table["buildingX"])
        local y = tonumber(_table["buildingY"])
        local lootBuilding = ServerMap.instance:getGridSquare(x, y, 0):getBuilding();
        local buildingDef = lootBuilding:getDef();
        for _, npc in ipairs(npcs) do
            local npcId = tonumber(npc);
            local npcObj = KnoxEventNpcAPI.instance:getNpcFromOnlineId(npcId);
            if npcObj == nil then
                print("No Npc with id " .. tostring(npcId));
                return;
            end
            npcObj:setGoal("LootingSubTree");
            npcObj:setSubGoal("");
            local tree = npcObj:getBehaviorTree();
            local goalNode = tree:getGoalNode();
            local lootNode = goalNode:getChildWithNameWithDepth("LootingSubTree", 1);
            local lootAmmo = _table["ammo"];
            local lootFirstAid = _table["firstaid"];
            local lootFood = _table["food"];
            local lootGuns = _table["guns"];
            local lootMaterials = _table["materials"];
            local lootTools = _table["tools"];
            local lootWater = _table["water"];
            local lootWeapons = _table["weapons"];

            lootNode:setData("EnterBuildingIsoBuilding", lootBuilding);
            lootNode:setData("LootingSubTreeLootBuilding", buildingDef);
            lootNode:setData("LootingSubTreeCategoryAmmo", lootAmmo);
            lootNode:setData("LootingSubTreeCategoryFood", lootFood);
            lootNode:setData("LootingSubTreeCategoryFirstAid", lootFirstAid);
            lootNode:setData("LootingSubTreeCategoryMats", lootMaterials);
            lootNode:setData("LootingSubTreeCategoryGuns", lootGuns);
            lootNode:setData("LootingSubTreeCategoryTools", lootTools);
            lootNode:setData("LootingSubTreeCategoryWater", lootWater);
            lootNode:setData("LootingSubTreeCategoryWeapons", lootWeapons);
            lootNode:setData("LootingSubTreeCategoryFinishedGoal", "RoamingSubTree");
            lootNode:setData("LootingSubTreeCategoryFinishedSubGoal", "FollowSubTree");

            print("NPC with id " .. tostring(npcId) .. " told to loot building");
        end
    end
end

local function npcRoamingControlCommandHandler(_module, _command, _player, _table)
    if _module == "KnoxEventNpcRoamingControl" then
        print("Received command " .. tostring(_command) .. " for module " .. tostring(_module));
        handleKnoxEventNpcRoamingControl(_command, _player, _table);
    end
end

Events.OnClientCommand.Add(npcRoamingControlCommandHandler)