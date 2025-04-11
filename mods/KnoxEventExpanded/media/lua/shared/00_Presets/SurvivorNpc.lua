if isClient() then return end;

require "ISBaseObject"

SurvivorPreset = ISBaseObject:derive("SurvivorPreset");

longBlunt = {"BaseballBat", "Broom", "Crowbar", "Shovel", "Shovel2", "BaseballBatNails", "PlankNail"};
shortBlunt = {"BallPeenHammer", "ClubHammer", "LeadPipe", "MetalBar", "MetalPipe", "Nightstick", "PipeWrench", "Wrench"};
longBlade = {"Machete", "Katana"};
spears = {"SpearCrafted", "WoodenLance"};
guns = {"Revolver_Long", "Pistol", "Revolver", "Revolver_Short", "Pistol2", "Pistol3"};
bags = {"Bag_NormalHikingBag", "Bag_ALICEpack", "Bag_SurvivorBag", "Bag_DuffelBag", "Bag_BigHikingBag"};

shirtsMale = {"Tshirt_SpiffoDECAL", "Tshirt_Sport", "Tshirt_Fossoil", "Tshirt_Gas2Go", "Tshirt_ThunderGas",
"Tshirt_Rock", "Tshirt_McCoys", "Tshirt_PileOCrepe", "Tshirt_PizzaWhirled", "Tshirt_ValleyStation", "Tshirt_PoloStripedTINT",
"Tshirt_DefaultDECAL", "Tshirt_DefaultDECAL_TINT", "Tshirt_DefaultTEXTURE", "Tshirt_DefaultTEXTURE_TINT", "Tshirt_WhiteTINT", "Tshirt_PoloTINT",
"Shirt_HawaiianTINT", "Shirt_HawaiianRed","Shirt_FormalWhite_ShortSleeve", "Shirt_FormalWhite_ShortSleeveTINT", "Shirt_Denim", "Shirt_FormalWhite",
"Shirt_Lumberjack", "Shirt_Workman" };
shirtsFemale = {"Shirt_CropTopTINT", "Shirt_CropTopNoArmTINT", "BoobTube", "BoobTubeSmall"};
hoodies = {"Jumper_PoloNeck", "Jumper_RoundNeck", "Jumper_VNeck", "HoodieDOWN_WhiteTINT", "HoodieUP_WhiteTINT"};

stockings = {"StockingsBlack", "StockingsWhite", "StockingsBlackSemiTrans", "StockingsBlackTrans"};
skirts = {"Skirt_Knees", "Skirt_Long", "Skirt_Mini", "Skirt_Short", "Skirt_Normal"};
dresses = {"Dress_Normal", "Dress_Knees", "Dress_SmallBlackStraps", "Dress_SmallBlackStrapless",
"Dress_SmallStrapless", "Dress_Straps", "DressKnees_Straps", "Dress_SmallStraps",
"Dress_Long", "Dress_long_Straps", "Dress_Short"};
pants = {"Trousers_JeanBaggy", "Trousers_LeatherBlack", "Trousers_Black", "TrousersMesh_DenimLight",
"Shorts_ShortDenim", "Trousers_Denim", "Shorts_LongDenim", "Shorts_LongSport", "Shorts_LongSport_Red",
"Shorts_CamoGreenLong", "Trousers_NavyBlue", "Dungarees", "Trousers_Padded", "Trousers",
"Trousers_DefaultTEXTURE", "Trousers_DefaultTEXTURE_HUE", "Trousers_DefaultTEXTURE_TINT",
"Trousers_WhiteTEXTURE", "Trousers_WhiteTINT", "Shorts_ShortFormal", "TrousersMesh_Leather"};

necklace = { "Necklace_Choker", "Necklace_Choker_Amber", "Necklace_Choker_Diamond", "Necklace_Choker_Sapphire",
"Necklace_Gold", "Necklace_GoldDiamond", "Necklace_GoldRuby",
"Necklace_Silver", "Necklace_SilverCrucifix", "Necklace_SilverDiamond", "Necklace_SilverSapphire",
"Necklace_Crucifix", "Necklace_YingYang", "Necklace_Pearl" };
earrings = { "Earring_Dangly_Diamond", "Earring_Dangly_Emerald", "Earring_Dangly_Pearl", "Earring_Dangly_Ruby", "Earring_Dangly_Sapphire", 
"Earring_Stone_Emerald", "Earring_Stone_Ruby", "Earring_Stone_Sapphire", "Earring_Pearl",
"Earring_Stud_Gold", "Earring_Stud_Silver", "Earring_LoopLrg_Gold", "Earring_LoopMed_Gold", "Earring_LoopSmall_Gold_Both", "Earring_LoopSmall_Gold_Top", 
"Earring_LoopLrg_Silver", "Earring_LoopMed_Silver", "Earring_LoopSmall_Silver_Both", "Earring_LoopSmall_Silver_Top", 
"Earring_Loop__Silver", "Earring_Loop__Silver", "Earring_Loop__Silver", "Earring_Loop__Silver" };
rings = { "Ring_Left_MiddleFinger_Gold", "Ring_Left_RingFinger_Gold", "Ring_Left_MiddleFinger_GoldDiamond", "Ring_Left_RingFinger_GoldDiamond",
"Ring_Left_MiddleFinger_Silver", "Ring_Left_RingFinger_Silver", "Ring_Left_MiddleFinger_SilverDiamond", "Ring_Left_RingFinger_SilverDiamond",
"Ring_Left_MiddleFinger_GoldRuby", "Ring_Left_RingFinger_GoldRuby", "Ring_Left_MiddleFinger_SilverRuby", "Ring_Left_RingFinger_SilverRuby" };
shoesMale = { "Shoes_BlueTrainers", "Shoes_RedTrainers" , "Shoes_TrainerTINT", "Shoes_ArmyBoots", "Shoes_BlackBoots", "Shoes_Black", "Shoes_Brown"};
shoesFemale = { "Shoes_BlueTrainers", "Shoes_RedTrainers" , "Shoes_TrainerTINT", "Shoes_RidingBoots", "Shoes_BlackBoots", "Shoes_Black", "Shoes_Brown", "Shoes_Strapped" };

function SurvivorPreset:dressNpc(npc)
	local roll = ZombRand(#bags)+1;
    local bag = npc:getInventory():AddItem(bags[roll]);
    npc:setClothingItem_Back(nil);
	npc:setClothingItem_Back(bag);
	if npc:isFemale() then
		roll = ZombRand(#shoesFemale)+1;
		local shoes = npc:getInventory():AddItem(shoesFemale[roll]);
		npc:setWornItem(shoes:getBodyLocation(), shoes);
		roll = ZombRand(100);
		if roll < 50 then
			local socks = npc:getInventory():AddItem("Socks_Ankle");
			npc:setWornItem(socks:getBodyLocation(), socks);

			roll = ZombRand(#pants)+1;
			local pants = npc:getInventory():AddItem(pants[roll]);
			npc:setWornItem(pants:getBodyLocation(), pants);

			roll = ZombRand(#shirtsMale)+1;
			local shirts = npc:getInventory():AddItem(shirtsMale[roll]);
			npc:setWornItem(shirts:getBodyLocation(), shirts);
		elseif roll < 75 then
			roll = ZombRand(#stockings)+1;
			local stocking = npc:getInventory():AddItem(stockings[roll]);
			npc:setWornItem(stocking:getBodyLocation(), stocking);

			roll = ZombRand(#skirts)+1;
			local skirt = npc:getInventory():AddItem(skirts[roll]);
			npc:setWornItem(skirt:getBodyLocation(), skirt);

			roll = ZombRand(#shirtsFemale)+1;
			local top = npc:getInventory():AddItem(shirtsFemale[roll]);
			npc:setWornItem(top:getBodyLocation(), top);
		else
			roll = ZombRand(#stockings)+1;
			local stocking = npc:getInventory():AddItem(stockings[roll]);
			npc:setWornItem(stocking:getBodyLocation(), stocking);

			roll = ZombRand(#dresses)+1;
			local dress = npc:getInventory():AddItem(dresses[roll]);
			npc:setWornItem(dress:getBodyLocation(), dress);
		end
	else
		roll = ZombRand(#shoesMale)+1;
		local shoes = npc:getInventory():AddItem(shoesMale[roll]);
		npc:setWornItem(shoes:getBodyLocation(), shoes);

		local socks = npc:getInventory():AddItem("Socks_Ankle");
        npc:setWornItem(socks:getBodyLocation(), socks);

		roll = ZombRand(#pants)+1;
		local pants = npc:getInventory():AddItem(pants[roll]);
		npc:setWornItem(pants:getBodyLocation(), pants);

		roll = ZombRand(#shirtsMale)+1;
		local shirts = npc:getInventory():AddItem(shirtsMale[roll]);
		npc:setWornItem(shirts:getBodyLocation(), shirts);

		roll = ZombRand(#hoodies)+1;
		local hoodie = npc:getInventory():AddItem(hoodies[roll]);
		npc:setWornItem(hoodie:getBodyLocation(), hoodie);
	end
	roll = ZombRand(100);
	local desc = npc:getDescriptor();
	local weapon = nil;
	if roll < 90 then
		local typeRoll = ZombRand(3);
		if typeRoll == 0 then
			local itemRoll = ZombRand(#spears)+1;
			weapon = npc:getInventory():AddItem(spears[itemRoll]);
		elseif typeRoll == 1 then
			local itemRoll = ZombRand(#shortBlunt)+1;
			weapon = npc:getInventory():AddItem(shortBlunt[itemRoll]);
		else
			local itemRoll = ZombRand(#longBlunt)+1;
			weapon = npc:getInventory():AddItem(longBlunt[itemRoll]);
		end
	elseif roll < 95 then
		if desc:getProfession() == "policeofficer" then
			weapon = npc:getInventory():AddItem("Base.Revolver_Long");
		elseif desc:getProfession() == "parkranger" then
			weapon = npc:getInventory():AddItem("Base.HuntingRifle");
		elseif desc:getProfession() == "securityguard" then
			weapon = npc:getInventory():AddItem("Base.Pistol");
		elseif desc:getProfession() == "veteran" then
			weapon = npc:getInventory():AddItem("Base.AssaultRifle2");
		else
			local itemRoll = ZombRand(#guns)+1;
			weapon = npc:getInventory():AddItem(guns[itemRoll]);
		end
	else
		local itemRoll = ZombRand(#longBlade)+1;
		weapon = npc:getInventory():AddItem(longBlade[itemRoll]);
	end
	if instanceof(weapon, "HandWeapon") and weapon:isRanged() then
		if weapon:getMagazineType() == nil then
			weapon:setCurrentAmmoCount(weapon:getMaxAmmo());
		else
			weapon:setCurrentAmmoCount(weapon:getMaxAmmo());
			weapon:setContainsClip(true);
		end
		weapon:setRoundChambered(true);
		weapon:setJammed(false);
	end
	npc:setPrimaryHandItem(weapon);
	npc:setSecondaryHandItem(weapon);
end

function SurvivorPreset:dressNpcWithOutfit(npc, outfit)
	if outfit == "Shopkeeper" then
		local apron = npc:getInventory():AddItem("Apron_Black");
		npc:setWornItem(apron:getBodyLocation(), apron);

		local tshirt = npc:getInventory():AddItem("Tshirt_WhiteTINT");
		npc:setWornItem(tshirt:getBodyLocation(), tshirt);

		local trousers = npc:getInventory():AddItem("Trousers_Denim");
		npc:setWornItem(trousers:getBodyLocation(), trousers);

		local socks = npc:getInventory():AddItem("Socks_Ankle");
        npc:setWornItem(socks:getBodyLocation(), socks);

		local shoes = npc:getInventory():AddItem("Shoes_Brown");
		npc:setWornItem(shoes:getBodyLocation(), shoes);

		local belt = npc:getInventory():AddItem("Base.Belt2");
		npc:setWornItem(belt:getBodyLocation(), belt);

		local watch = npc:getInventory():AddItem("WristWatch_Left_DigitalBlack");
		npc:setWornItem(watch:getBodyLocation(), watch);

		local cap = npc:getInventory():AddItem("Hat_BaseballCap");
		npc:setWornItem(cap:getBodyLocation(), cap);

		local bat = npc:getInventory():AddItem("BaseballBat");
		npc:setPrimaryHandItem(bat);
		npc:setSecondaryHandItem(bat);
	elseif outfit == "ShopkeeperWithGun" then
		local apron = npc:getInventory():AddItem("Apron_Black");
		npc:setWornItem(apron:getBodyLocation(), apron);

		local shirt = npc:getInventory():AddItem("Shirt_Lumberjack");
		npc:setWornItem(shirt:getBodyLocation(), shirt);

		local trousers = npc:getInventory():AddItem("Trousers_Denim");
		npc:setWornItem(trousers:getBodyLocation(), trousers);

		local socks = npc:getInventory():AddItem("Socks_Ankle");
		npc:setWornItem(socks:getBodyLocation(), socks);

		local shoes = npc:getInventory():AddItem("Shoes_Brown");
		npc:setWornItem(shoes:getBodyLocation(), shoes);

		local belt = npc:getInventory():AddItem("Base.Belt2");
		npc:setWornItem(belt:getBodyLocation(), belt);

		local watch = npc:getInventory():AddItem("WristWatch_Left_DigitalBlack");
		npc:setWornItem(watch:getBodyLocation(), watch);

		local cap = npc:getInventory():AddItem("Hat_BaseballCap");
		npc:setWornItem(cap:getBodyLocation(), cap);

		local shotgun = npc:getInventory():AddItem("DoubleBarrelShotgun");
		npc:setPrimaryHandItem(shotgun);
		npc:setSecondaryHandItem(shotgun);
	end
end

function SurvivorPreset:new()
    local o = {}
	setmetatable(o, self)
	self.__index = self
    o.preset = NpcPreset.new("SurvivorNpc", o);
	o.preset:setBehaviorTree("SurvivorBehaviorTree");
	return o
end

Events.OnInitGlobalModData.Add(function() SurvivorPreset.instance = SurvivorPreset:new(); end)