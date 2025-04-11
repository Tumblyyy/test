if isClient() then return end;

local louisVille1 = nil;
local louisVille2 = nil;
local louisVille3 = nil;
local louisVille4 = nil;

local muldraughSoldiers = nil;
local westPointSoldiers = nil;
local roseWoodSoldiers = nil;
local riversideSoldiers = nil;

local function doCurfewPatrol(sx, sy, tx, ty)
    local group = KnoxEventNpcAPI.instance:spawnNpcGroup("SoldierNpc", sx, sy, 4);
    local groupList = group:getGroupMembers();
    for i=0, groupList:size()-1 do
        local npc = groupList:get(i);
        npc:setGoal("CurfewPatrolSubTree");
        npc:setSubGoal("");
        local tree = npc:getBehaviorTree();
        local curfewNode = tree:getChildWithName("CurfewPatrolSubTree");
        curfewNode:setData("CurfewPatrolSubTreeTargetX", tx);
        curfewNode:setData("CurfewPatrolSubTreeTargetY", ty);
        MilitaryFaction.instance.faction:addGroup(group);
    end
    return group;
end

function startCurfewPatrols()
    print("Curfew has begun!");
    sendNpcRadioMessage(12512, 4280, 92000, "Curfew has begun. All units, lock and load!");
    muldraughSoldiers = doCurfewPatrol(10590, 8855, 10590, 11204);
    westPointSoldiers = doCurfewPatrol(11100, 6899, 12229, 6898);
    roseWoodSoldiers = doCurfewPatrol(8101, 11201, 8413, 12222);
    riversideSoldiers  = doCurfewPatrol(5881, 5445, 7008, 5468);
    louisVille1 = doCurfewPatrol(12278, 3451, 12068, 1730);
    louisVille2 = doCurfewPatrol(12509, 3245, 12502, 2097);
    louisVille3 = doCurfewPatrol(12512, 3447, 13976, 3298);
    louisVille4 = doCurfewPatrol(13979, 2997, 13498, 1954);
end

function endCurfewPatrols()
    print("Curfew has ended.");
    sendNpcRadioMessage(12512, 4280, 92000, "Curfew is now over. All units, return to base.");
    if louisVille1 ~= nil then
        MilitaryFaction.instance.faction:removeGroup(louisVille1);
        louisVille1:unload();
        louisVille1 = nil;
    end
    if louisVille2 ~= nil then
        MilitaryFaction.instance.faction:removeGroup(louisVille2);
        louisVille2:unload();
        louisVille2 = nil;
    end
    if louisVille3 ~= nil then
        MilitaryFaction.instance.faction:removeGroup(louisVille3);
        louisVille3:unload();
        louisVille3 = nil;
    end
    if louisVille4 ~= nil then
        MilitaryFaction.instance.faction:removeGroup(louisVille4);
        louisVille4:unload();
        louisVille4 = nil;
    end
    if roseWoodSoldiers ~= nil then
        MilitaryFaction.instance.faction:removeGroup(roseWoodSoldiers);
        roseWoodSoldiers:unload();
        roseWoodSoldiers = nil;
    end
    if muldraughSoldiers ~= nil then
        MilitaryFaction.instance.faction:removeGroup(muldraughSoldiers);
        muldraughSoldiers:unload();
        muldraughSoldiers = nil;
    end
    if westPointSoldiers ~= nil then
        MilitaryFaction.instance.faction:removeGroup(westPointSoldiers);
        westPointSoldiers:unload();
        westPointSoldiers = nil;
    end
    if riversideSoldiers ~= nil then
        MilitaryFaction.instance.faction:removeGroup(riversideSoldiers);
        riversideSoldiers:unload();
        riversideSoldiers = nil;
    end
end

local function everyHoursHandler()
    local hour = getGameTime():getHour();

    if SandboxVars.KnoxEventExpanded.General_MilitaryCurfewPatrols then
        if hour == 20 then
            startCurfewPatrols();
        elseif hour == 8 then
            endCurfewPatrols();
        end
    end
end

Events.EveryHours.Add(everyHoursHandler)