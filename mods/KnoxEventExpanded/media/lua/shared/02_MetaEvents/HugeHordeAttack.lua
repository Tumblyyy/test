if isClient() then return end;

require "ISBaseObject"

HugeHordeAttack = ISBaseObject:derive("HugeHordeAttack");

function HugeHordeAttack:setup()
    local safehouse = self.group:getSafehouse();
    local x = safehouse:getX() + safehouse:getW()/2;
    local y = safehouse:getY() + safehouse:getH()/2;
    sendNpcRadioMessageWithRange(x, y, 90000, 200, "To anyone listening, we are under attack by huge horde of zombies at " .. tostring(x) .. "," .. tostring(y) .. ". Please help us!");
    --sendSafehouseMarker(x, y, 200);
end

function HugeHordeAttack:simulate()
    local groupList = self.group:getGroupMembers();
    if groupList:size() == 0 then
        return;
    end
    for i=1,self.nbrOfZombies do
        local attackRoll = ZombRand(1,100);
        local targetIndex = 0;
        if groupList:size() >= 1 then
            targetIndex = ZombRand(0, groupList:size());
        end
        local targetNpc = groupList:get(targetIndex);
        if targetNpc ~= nil then
            if attackRoll >= 95 then
                targetNpc:getBodyDamage():AddRandomDamageFromZombie(getCell():getFakeZombieForHit(), "Bite");
            elseif attackRoll >= 80 then
                --targetNpc:getBodyDamage():AddRandomDamageFromZombie(getCell():getFakeZombieForHit(), "Bite");
            elseif attackRoll >= 60 then
                --targetNpc:getBodyDamage():AddRandomDamageFromZombie(getCell():getFakeZombieForHit(), "Bite");
            end
        end
    end
end

function HugeHordeAttack:loaded()
    local safehouse = self.group:getSafehouse();
    local x1 = safehouse:getX();
    local y1 = safehouse:getY() - 7;
    local x2 = safehouse:getX2();
    local y2 = safehouse:getY2() + 7;
    createHordeInAreaTo(x1, y1, 0, x2, y2, 0, self.nbrOfZombies);
end

function HugeHordeAttack:finish()
    local groupList = self.group:getGroupMembers();
    for i=0,groupList:size()-1 do
        -- TODO: Add memories
    end
end

function HugeHordeAttack:new(group)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.group = group;
    o.eventObj = LuaNpcMetaSafehouseEvent.new(group, o);
    o.nbrOfZombies = ZombRand(8, 10);
    return o
end