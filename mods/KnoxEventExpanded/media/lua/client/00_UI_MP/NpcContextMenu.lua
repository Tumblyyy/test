if not isClient() or isServer() then return end

function isIsoNpcPlayerObject(playerObject)
    for id, _ in pairs(masterNpcList) do
        if playerObject:getOnlineID() == id then
            return true;
        end
    end
    return false;
end

function isNpcInGroup(npcObject)
    for _, npc in pairs(groupNpcList) do
        if npcObject:getOnlineID() == tonumber(npc["id"]) then
            return true;
        end
    end
    return false;
end

local function findNpcs(x, y, startZ)
    local npcs = {};
    for z=startZ,0,-1 do
        for sy=y-1,y+1 do
            for sx=x-1,x+1 do
                local square = getCell():getGridSquare(sx, sy, z);
                if square then
                    local objects = square:getMovingObjects()
                    local i = 0;
                    while i < (objects:size()) do
                        local tmpNpc = objects:get(i);
                        if (instanceof(tmpNpc, "IsoPlayer") and isIsoNpcPlayerObject(tmpNpc)) then
                            table.insert(npcs, tmpNpc);
                        end
                        i = i + 1;
                    end
                end
            end
        end
    end
    return npcs;
end

local function onFillWorldObjectNpcContextMenu(playerIndex, context, worldObjects, test)
    local sw = (128 / getCore():getZoom(0));
	local sh = (64 / getCore():getZoom(0));

    local player = getSpecificPlayer(0);
	local mapx = player:getX();
	local mapy = player:getY();
	local mousex = ((getMouseX() - (getCore():getScreenWidth() / 2)));
	local mousey = ((getMouseY() - (getCore():getScreenHeight() / 2)));

	local sx = mapx + (mousex / (sw / 2) + mousey / (sh / 2)) / 2;
	local sy = mapy + (mousey / (sh / 2) - (mousex / (sw / 2))) / 2;

    local npcList = findNpcs(sx, sy, player:getZ());
    for _, npcObj in pairs(npcList) do
        local npcOption = context:addOption(npcObj:getUsername(), worldObjects, nil);
        local npcSubMenu = context:getNew(context);
        local npcId = npcObj:getOnlineID()
        print("Found npc with id " .. tostring(npcId))
        npcSubMenu:addOption(getText("ContextMenu_KnoxEvent_Speak"), nil, talkToNpc, npcId);
        if isNpcInGroup(npcObj) then
            npcSubMenu:addOption(getText("ContextMenu_KnoxEvent_OpenInventory"), nil, openNpcInventory, npcObj);
        end
        if getDebug() then
            if isClient() and getAccessLevel() == "admin" then
                npcSubMenu:addOption("Test hunger", nil, testHunger, npcId);
                npcSubMenu:addOption("Test thirst", nil, testThirst, npcId);
                npcSubMenu:addOption("Test exhaustion", nil, testExhaustion, npcId);
                npcSubMenu:addOption("Debug NpcBase", nil, toggleNpcBaseDebug, npcId);
                npcSubMenu:addOption("Debug BehaviorTree", nil, toggleNpcTreeDebug, npcId);
                npcSubMenu:addOption("Dump memories", nil, dumpMemories, npcId);
            end
        end
        context:addSubMenu(npcOption, npcSubMenu);
    end
    local square = getCell():getGridSquare(sx, sy, player:getZ());
    if square:getBuilding() ~= nil and #selectedGroupNps > 0 then
        local bx = square:getX()
        local by = square:getY()
        local lootOption = context:addOption(getText("ContextMenu_KnoxEvent_LootBuilding"), nil, tellNpcLoot, bx, by);
    end
end

if not isServer() then
    Events.OnFillWorldObjectContextMenu.Add(onFillWorldObjectNpcContextMenu);
end
