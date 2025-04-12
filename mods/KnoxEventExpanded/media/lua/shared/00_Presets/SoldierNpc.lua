if isClient() then return end;

require "ISBaseObject"
require "NpcPreset"

SoldierPreset = ISBaseObject:derive("SoldierPreset");

local function addEscortQuest(preset)
    table.insert(preset.quests, "escort")
end

function SoldierPreset:dressNpc(npc) end
function SoldierPreset:dressNpcWithOutfit(npc, outfit) end

function SoldierPreset:new()
    local o = {}
	setmetatable(o, self)
	self.__index = self    o.preset = NpcPreset.new("SoldierNpc", o);
    o.preset.faction = "Soldiers";
    o.preset.partyID = "SoldierNpc";
    o.preset:setBehaviorTree("SoldierBehaviorTree");
    o.preset.presetClothes = {
        hat = "Hat_Army",
        jacket = "Jacket_ArmyCamoGreen",
        shirt = "Tshirt_ArmyGreen",
        vest = "Vest_BulletArmy",
        pants = "Trousers_ArmyService",
        belt = "Base.Belt2",
        socks = "Socks_Ankle",
        boots = "Shoes_ArmyBoots",
        watch = "WristWatch_Left_ClassicMilitary"
    }
    addEscortQuest(o.preset)
	return o
end

Events.OnInitGlobalModData.Add(function() SoldierPreset.instance = SoldierPreset:new(); end)