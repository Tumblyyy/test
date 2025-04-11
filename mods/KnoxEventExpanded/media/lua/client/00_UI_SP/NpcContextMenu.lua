if isClient() or isServer() then return end

function isNpcInGroup(npcObject)
    local player = getPlayer();
    local group = player:getGroup();
    if group ~= nil then
        local npcList = group:getGroupMembers();
        if npcList ~= nil then
            return npcList:contains(npcObject);
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
                        if instanceof(tmpNpc, "IsoNpcPlayer") then
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
    local group = player:getGroup();
	local mapx = player:getX();
	local mapy = player:getY();
	local mousex = ((getMouseX() - (getCore():getScreenWidth() / 2)));
	local mousey = ((getMouseY() - (getCore():getScreenHeight() / 2)));

	local sx = mapx + (mousex / (sw / 2) + mousey / (sh / 2)) / 2;
	local sy = mapy + (mousey / (sh / 2) - (mousex / (sw / 2))) / 2;

    local square = nil;
    local z = player:getZ();
    while square == nil and z >= 0 do
        square = getCell():getGridSquare(sx, sy, z);
        if square then
            break;
        end
        z = z - 1;
    end
    if square == nil then
        return;
    end
    local objects = square:getMovingObjects()
    local npcObj = nil;
    local car = nil;
    local i = 0

    local safeHouse = getPlayerSafehouse();
    if square:getBuilding() ~= nil then
        local building = square:getBuilding();
        local buildingDef = building:getDef();
        if safeHouse == nil then
            context:addOption(getText("ContextMenu_SafehouseClaim"), worldObjects, claimSafehouse, buildingDef, player);
        elseif safeHouse ~= nil and safeHouse == buildingDef then
            context:addOption(getText("ContextMenu_SafehouseRelease"), worldObjects, releaseSafehouse, player);
        end
    end

--[[
    i = 0;
    while i < (objects:size()) do
        local tmpCar = objects:get(i);
        print("Looking at object " .. tostring(tmpCar));
        if instanceof(tmpCar, "BaseVehicle") then
            car = tmpCar;
            break;
        end
        i = i + 1;
    end
    if car ~= nil and #selectedGroupNps == 1 then
        context:addOption("Drive", nil, driveVehicleNpc, selectedGroupNps[1], car);
    end
]]--
    local npcList = findNpcs(sx, sy, player:getZ());
    for _, npcObj in pairs(npcList) do
        local npcOption = context:addOption(npcObj:getUsername(), worldObjects, nil);
        local npcSubMenu = context:getNew(context);
        print("Found npc " .. tostring(npcObj:getUsername()))
        npcSubMenu:addOption(getText("ContextMenu_KnoxEvent_Speak"), nil, talkToNpc, npcObj);
        if isNpcInGroup(npcObj) then
            npcSubMenu:addOption(getText("ContextMenu_KnoxEvent_OpenInventory"), nil, openNpcInventory, npcObj);
        end
        if getDebug() then
            npcSubMenu:addOption("Test hunger", nil, testHunger, npcObj);
            npcSubMenu:addOption("Test thirst", nil, testThirst, npcObj);
            npcSubMenu:addOption("Test exhaustion", nil, testExhaustion, npcObj);
            npcSubMenu:addOption("Debug NpcBase", nil, toggleNpcBaseDebug, npcObj);
            npcSubMenu:addOption("Debug BehaviorTree", nil, toggleNpcTreeDebug, npcObj);
            npcSubMenu:addOption("Dump memories", nil, dumpMemories, npcObj);
        end
        context:addSubMenu(npcOption, npcSubMenu);
    end
    local building = square:getBuilding();
    if building ~= nil and #selectedGroupNps > 0 then
        local lootOption = context:addOption(getText("ContextMenu_KnoxEvent_LootBuilding"), nil, tellNpcLoot, building);
    end
end

Events.OnFillWorldObjectContextMenu.Add(onFillWorldObjectNpcContextMenu);