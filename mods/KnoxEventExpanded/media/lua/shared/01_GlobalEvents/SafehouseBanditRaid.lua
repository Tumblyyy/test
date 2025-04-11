if isClient() then return end;

function doSafehouseAttack(player)
    local safeHouse = nil;
    if isServer() then
        safeHouse = SafeHouse.hasSafehouse(player);
    else
        safeHouse = getPlayerSafehouse();
    end
    if safeHouse == nil then
        return;
    end
    local playerX = player:getX();
    local playerY = player:getY();
    if playerX < safeHouse:getX() or playerX > safeHouse:getX2() or playerY < safeHouse:getY() or playerY > safeHouse:getY2() then
        print("Player is not home, skip spawning...")
        return;
    end
    local dir = ZombRand(0 , 7);
    local dirX = 0;
    local dirY = 0;
    local w = safeHouse:getW()/2;
    local h = safeHouse:getH()/2;
    local startX = safeHouse:getX() + w;
    local startY = safeHouse:getY() + h;
    local offset = ZombRand(2, 6);
    if dir == 0 then
        dirY = dirY - (h + offset);
    elseif dir == 1 then
        dirX = dirX + (w + offset);
        dirY = dirY - (h + offset);
    elseif dir == 2 then
        dirX = dirX + (w + offset);
    elseif dir == 3 then
        dirX = dirX + (w + offset);
        dirY = dirY + (h + offset);
    elseif dir == 4 then
        dirY = dirY + (h + offset);
    elseif dir == 5 then
        dirX = dirX - (w + offset);
        dirY = dirY + (h + offset);
    elseif dir == 6 then
        dirX = dirX - (w + offset);
    elseif dir == 7 then
        dirX = dirX - (w + offset);
        dirY = dirY - (h + offset);
    end
    local sx = startX + dirX;
    local sy = startY + dirY;

    local nbrOfBandits = ZombRand(SandboxVars.KnoxEventExpanded.General_BanditAttackMinNumberInterval, SandboxVars.KnoxEventExpanded.General_BanditAttackMaxNumberInterval);
    local group = KnoxEventNpcAPI.instance:spawnNpcGroup("BanditNpc", sx, sy, nbrOfBandits);
    local targetSquare = getCell():getGridSquare(startX, startY, 0);
    local building = targetSquare:getBuilding();
    group:raidBuilding(player, building);
end

local function everyHoursHandler()
    local hour = getGameTime():getHour();

    if SandboxVars.KnoxEventExpanded.General_BanditSafehouseAttacks then
        if isServer() then
            local playerList = getOnlinePlayers();
            for i=0, playerList:size()-1 do
                local player = playerList:get(i);
                local risk = 0;
                if (hour >= 9 and hour <= 20) then
                    risk = SandboxVars.KnoxEventExpanded.General_BanditAttackRiskDay;
                else
                    risk = SandboxVars.KnoxEventExpanded.General_BanditAttackRiskNight;
                end
                if ZombRand(1, 1000) < risk then
                    doSafehouseAttack(player);
                end
            end
        else
            local player = getPlayer();
            local risk = 0;
            if (hour >= 9 and hour <= 20) then
                risk = SandboxVars.KnoxEventExpanded.General_BanditAttackRiskDay;
            else
                risk = SandboxVars.KnoxEventExpanded.General_BanditAttackRiskNight;
            end
            if ZombRand(1, 1000) < risk then
                doSafehouseAttack(player);
            end
        end
    end
end

Events.EveryHours.Add(everyHoursHandler)