if isClient() then return end;

require "ISBaseObject"

PoliceFaction = ISBaseObject:derive("PoliceFaction");

PoliceFaction.instance = PoliceFaction:new();

function PoliceFaction:reasonNextMove()
    --[[
     Tasks that needs to be solve
     1. Patrol around the neighbourhood
     2. Greet citizens at the police station
     3. Protect the armory

     Cops will work in 10 hour shifts. Patrolling officers will work in pairs.
    ]]--
    local hour = getGameTime():getHour();
    if hour == 8 then
    elseif hour == 20 then
    end
end

function PoliceFaction:setup()
end

function PoliceFaction:new()
    local o = {}
	setmetatable(o, self)
	self.__index = self
    o.faction = NpcFaction.new("Police", o);
	return o
end