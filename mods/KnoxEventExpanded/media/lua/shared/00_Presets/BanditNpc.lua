if isClient() then return end;

require "ISBaseObject"
require "NpcPreset"
require "Quest"

local weapons = {"Axe", "BaseballBat", "BaseballBatNails", "Crowbar", "WoodenLance",
"LeadPipe", "Nightstick", "MetalBar", "MetalPipe", "Machete",
"PipeWrench", "SpearKnife", "SpearHuntingKnife", "SpearScissors", "SpearScrewdriver"};
local guns = {"Pistol", "Pistol2", "Pistol3"};
local bags = {"Bag_WorkerBag", "Bag_DuffelBag", "Bag_BigHikingBag"};
local masks = {"Hat_DustMask", "Hat_GasMask", "Hat_SurgicalMask_Blue", "Hat_NBCmask", "WeldingMask" };
local jackets = {"Jacket_Black", "Jacket_LeatherBarrelDogs", "Jacket_LeatherIronRodent", "Jacket_LeatherWildRacoons", "Jacket_Ranger" , "JacketLong_Random" };

BanditPreset = ISBaseObject:derive("BanditPreset");

function BanditPreset:dressNpc(npc)
    local belt = npc:getInventory():AddItem("Base.Belt2");
	npc:setWornItem(belt:getBodyLocation(), belt);

    local pants = npc:getInventory():AddItem("Trousers_Denim");
	npc:setWornItem(pants:getBodyLocation(), pants);

    local socks = npc:getInventory():AddItem("Socks_Ankle");
    npc:setWornItem(socks:getBodyLocation(), socks);

	local shoes = npc:getInventory():AddItem("Shoes_ArmyBoots");
	npc:setWornItem(shoes:getBodyLocation(), shoes);

    local roll = ZombRand(#bags)+1;
    local bag = npc:getInventory():AddItem(bags[roll]);
    npc:setClothingItem_Back(nil);
	npc:setClothingItem_Back(bag);

    roll = ZombRand(#masks)+1;
    local mask = npc:getInventory():AddItem(masks[roll]);
	npc:setWornItem(mask:getBodyLocation(), mask);

    roll = ZombRand(#jackets)+1;
    local jacket = npc:getInventory():AddItem(jackets[roll]);
	npc:setWornItem(jacket:getBodyLocation(), jacket);

    roll = ZombRand(100);
    if roll < 20 then
        roll = ZombRand(#guns)+1;
        local gun = npc:getInventory():AddItem(guns[roll]);
        npc:setPrimaryHandItem(gun);
        npc:setSecondaryHandItem(gun);
        if gun:getMagazineType() == nil then
            gun:setCurrentAmmoCount(gun:getMaxAmmo());
        else
            gun:setCurrentAmmoCount(gun:getMaxAmmo());
            gun:setContainsClip(true);
        end
    else
        roll = ZombRand(#weapons)+1;
        local weapon = npc:getInventory():AddItem(weapons[roll]);
	    npc:setPrimaryHandItem(weapon);
	    npc:setSecondaryHandItem(weapon);
    end
end

function BanditPreset:dressNpcWithOutfit(npc, outfit)
end

function BanditPreset:new()
    local o = {}
	setmetatable(o, self)
	self.__index = self
    o.preset = NpcPreset.new("BanditNpc", o);
    o.preset.faction = "Bandits";
    o.preset.partyID = "BanditNpc";
	o.preset:setBehaviorTree("BanditBehaviorTree");
	return o
end

Events.OnInitGlobalModData.Add(function() BanditPreset.instance = BanditPreset:new(); end)