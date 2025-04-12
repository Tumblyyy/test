if isClient() then return end;

require "00_Presets/SoldierNpc"
require "00_Presets/SurvivorNpc"

require "ISBaseObject"

MilitaryFaction = ISBaseObject:derive("MilitaryFaction");

local function assignDefendNorth(npc, index)
    local tx = 0;
    local ty = 0;
    if index == 0 then
        tx = 12513;
        ty = 4194;
    elseif index == 1 then
        tx = 12516;
        ty = 4194;
    elseif index == 2 then
        tx = 12520;
        ty = 4195;
    elseif index == 3 then
        tx = 12514;
        ty = 4196;
    end
    npc:setGoal("DefendSubTree");
    npc:setSubGoal("");
    local tree = npc:getBehaviorTree();
    if tree ~= nil then
        return;
    end
    local defendSubTree = tree:getChildWithName("DefendSubTree");
    if defendSubTree == nil then
        -- TODO: Log here
        return;
    end
    local staySubTreeNode = defendSubTree:getChildWithName("StaySubTree");
    local stayMovementNode = staySubTreeNode:getChildWithName("MovementSubTree");
    stayMovementNode:setData("MovementSubTreeTargetX", tx);
    stayMovementNode:setData("MovementSubTreeTargetY", ty);
    stayMovementNode:setData("MovementSubTreeTargetZ", 0);
end

local function assignDefendSouth(npc, index)
    --12513, 4358: 12516, 4358: 12518, 4358: 12520, 4358
    local tx = 0;
    local ty = 0;
    if index == 0 then
        tx = 12513;
        ty = 4358;
    elseif index == 1 then
        tx = 12516;
        ty = 4358;
    elseif index == 2 then
        tx = 12518;
        ty = 4358;
    elseif index == 3 then
        tx = 12520;
        ty = 4358;
    end
    npc:setGoal("DefendSubTree");
    npc:setSubGoal("");
    local tree = npc:getBehaviorTree();
    if tree ~= nil then
        return;
    end
    local defendSubTree = tree:getChildWithName("DefendSubTree");
    local staySubTreeNode = defendSubTree:getChildWithName("StaySubTree");
    local stayMovementNode = staySubTreeNode:getChildWithName("MovementSubTree");
    stayMovementNode:setData("MovementSubTreeTargetX", tx);
    stayMovementNode:setData("MovementSubTreeTargetY", ty);
    stayMovementNode:setData("MovementSubTreeTargetZ", 0);
end

local function assignDefendEast(npc, index)
    --12574, 4340:12577, 4340
    local tx = 0;
    local ty = 0;
    if index == 0 then
        tx = 12574;
        ty = 4340;
    elseif index == 1 then
        tx = 12578;
        ty = 4341;
    elseif index == 2 then
        tx = 12574;
        ty = 4340;
    elseif index == 3 then
        tx = 12577;
        ty = 4340;
    end
    npc:setGoal("DefendSubTree");
    npc:setSubGoal("");
    local tree = npc:getBehaviorTree();
    if tree ~= nil then
        return;
    end
    local defendSubTree = tree:getChildWithName("DefendSubTree");
    local staySubTreeNode = defendSubTree:getChildWithName("StaySubTree");
    local stayMovementNode = staySubTreeNode:getChildWithName("MovementSubTree");
    stayMovementNode:setData("MovementSubTreeTargetX", tx);
    stayMovementNode:setData("MovementSubTreeTargetY", ty);
    stayMovementNode:setData("MovementSubTreeTargetZ", 0);
end

function MilitaryFaction:assignPatrol(npc, index)
    -- TODO: Implement
end

function MilitaryFaction:assignCurfew(npc, index)
    -- TODO: Implement
end

function MilitaryFaction:doReinforcements()
    -- TODO: Implement
end

function MilitaryFaction:assignWork()
    local groupList = self.faction:getFactionGroups();
    local i = 0;
    while i < self.restingGroups:size() do
        local group = self.restingGroups:get(i):getGroupMembers();
        local j = 0;
        while j < group:size() do
            local npc = group:get(j);
            npc:setGoal("SafehouseSubTree");
            npc:setSubGoal("RestSubTree");
            j = j + 1;
        end
        i = i + 1;
    end

    i = 0;
    while i < self.workingGroups:size() do
        local group = self.workingGroups:get(i):getGroupMembers();
        local j = 0;
        while j < group:size() do
            local npc = group:get(j);
            if i == 0 then
                assignDefendNorth(npc, j);
            elseif i == 1 then
                assignDefendSouth(npc, j);
            elseif i == 2 then
                assignDefendEast(npc, j);
            else
                npc:setGoal("SafehouseSubTree");
                npc:setSubGoal("RestSubTree");
            end
            j = j + 1;
        end
        i = i + 1;
    end
end

function MilitaryFaction:reasonNextMove()
    --[[
     Tasks that needs to be solve
     1. Guarding the three entrances to the Louisville checkpoint (3 groups)
     2. Guarding the two "mini" checkpoints along the exclusion zone
     3. Patrolling the exclusion zone (day time)
     4. Curfew enforcement (save until later)
     The military will work in two shifts
     8 - 20 and 20 - 8
    ]]--
    local hour = getGameTime():getHour();
    if hour == 8 or hour == 20 then
        local tmpGroup = self.restingGroups;
        self.restingGroups = self.workingGroups;
        self.workingGroups = tmpGroup;
        self:assignWork();
    end
end

function MilitaryFaction:setup()
    local tents = getWorld():getMetaGrid():getMilitaryBuildings();
    for i=1,10  do
        local group = KnoxEventNpcAPI.instance:spawnNpcGroup("SoldierNpc", 12511, 4276, 4);
        -- TODO: Assign aiming skill and profession
        --soldierObject.getXp().setXPToLevel(PerkFactory.Perks.Aiming, 10);
        self.faction:addGroup(group);
        local groupList = group:getGroupMembers();
        local j = 0;
        while j < groupList:size() do
            local npc = groupList:get(j);
            npc:getXp():setXPToLevel(Perks.Aiming, 10);
            SoldierPreset.instance.preset:dressNpc(npc)
            j = j + 1;
        end
        local npc = group:getGroupMembers():get(0);
        local safehouse = tents:get(i);
        local x = safehouse:getX() + safehouse:getW() / 2;
        local y = safehouse:getY() + safehouse:getH() / 2;
        npc:claimSafeHouse(x, y);
    end
    -- Initialize behavior trees for all NPCs in the faction
    for i = 0, self.faction:getFactionGroups():size() - 1 do
        local group = self.faction:getFactionGroups():get(i);
        group:initAllNpcTrees()
    end
    local groupList = self.faction:getFactionGroups();
    local i = 0;
    while i < groupList:size() do
        local group = groupList:get(i);
        if i <= groupList:size()/2 then
            self.restingGroups:add(group);
        else
            self.workingGroups:add(group);
        end
        i = i + 1;
    end
    self:assignWork();
end

function MilitaryFaction:new()
    local o = {}
	setmetatable(o, self)
	self.__index = self
    o.faction = NpcFaction.new("Military", o);
    o.restingGroups = ArrayList.new();
    o.workingGroups = ArrayList.new();
	return o
end

MilitaryFaction.instance = MilitaryFaction:new()