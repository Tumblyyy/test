if isClient() then return end;

local function runMetaEvents()
    local groups = getEligibleGroups();
    for i=0,groups:size()-1 do
        local group = groups:get(i);
        local roll = ZombRand(1,100);
        if roll >= 90 then
            local event = HugeHordeAttack:new(group);
            event:setup();
        elseif roll >= 70 then
            local event = LargeHordeAttack:new(group);
            event:setup();
        elseif roll >= 40 then
            local event = SmallHordeAttack:new(group);
            event:setup();
        end
    end
end

Events.EveryTenMinutes.Add(runMetaEvents);