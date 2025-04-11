if not isServer() then return end;
if not IPPJModCheck then return end;
require "ImprovedProjectile_Server.lua";

ImprovedProjectileServer.hitPlayer = function(args)
    local attacker = getPlayerByOnlineID(args[1]);
    local npc = getNpcFromOnlineId(tostring(args[2]));
    if npc then
        local hitDamage = args[4];

        local headShot = {
            BodyPartType.Head,			BodyPartType.Head,
            BodyPartType.Neck
        };
        local bodyShot = {
            BodyPartType.Torso_Upper,	BodyPartType.Torso_Lower,
            BodyPartType.Torso_Upper,	BodyPartType.Torso_Lower,
            BodyPartType.Torso_Upper,	BodyPartType.Torso_Lower,
            BodyPartType.Groin,
            BodyPartType.UpperArm_L,	BodyPartType.UpperArm_R,
            BodyPartType.ForeArm_L,		BodyPartType.ForeArm_R,
            BodyPartType.UpperLeg_L,	BodyPartType.UpperLeg_R,
            BodyPartType.UpperLeg_L,	BodyPartType.UpperLeg_R,
            BodyPartType.LowerLeg_L,	BodyPartType.LowerLeg_R
        };
        local terminalShot = {
            BodyPartType.Hand_L,		BodyPartType.Hand_R,
            BodyPartType.Foot_L,		BodyPartType.Foot_R
        };

        local hitPart = BodyPartType.Torso_Upper;

        local sandboxVars = SandboxVars.KnoxEventExpanded;
        if sandboxVars.OnlyTorsoInjuries then
            if args[3] > 0.4 then
                hitPart = headShot[ZombRand(3) + 1];
            else
                hitPart = bodyShot[ZombRand(17) + 1];
            end
        else
            if args[3] > 0.8 then
                hitPart = headShot[ZombRand(3) + 1];
            elseif args[3] > 0.4 then
                hitPart = bodyShot[ZombRand(17) + 1];
            else
                hitPart = terminalShot[ZombRand(4) + 1];
            end
        end

        local hitPlayerPart = npc:getBodyDamage():getBodyPart(hitPart);
        local defenseBullet	= npc:getBodyPartClothingDefense(hitPart:index(), false, true);
        local defenseBite	= npc:getBodyPartClothingDefense(hitPart:index(), true, false);
        local finalDefense	= (100 + (defenseBullet * 1.5) + (defenseBite * 0.5)) / 100;
        local originalDamage = hitDamage;

        if SandboxVars.KnoxEventExpanded.General_RangedDamageHitMultiplier then
            hitDamage = hitDamage * SandboxVars.KnoxEventExpanded.General_RangedDamageHitMultiplier;
        end
        hitDamage = hitDamage / finalDefense;

        if SandboxVars.ImprovedProjectile.IPPJPVPEnableWound then
            if ZombRand(100) >= defenseBullet then
                if hitPlayerPart:haveBullet() then
                    hitPlayerPart:generateDeepWound();
                else
                    hitPlayerPart:setHaveBullet(true, 3);
                end
            end
        end

        local stats = npc:getStats();
        local pain = math.min(stats:getPain() + npc:getBodyDamage():getInitialBitePain() * BodyPartType.getPainModifyer(hitPart:index()), 100);
        stats:setPain(pain);

        npc:addBlood(50);
        hitPlayerPart:ReduceHealth(hitDamage);
        local actualDamage = hitDamage * BodyPartType.getDamageModifyer(hitPart:index());
        local weapon = "Pistol";
        if args[8] ~= nil then
            weapon = args[8]
        end
        local handweapon = InventoryItemFactory.CreateItem(weapon);
        npc:handleNpcHitReaction(handweapon, attacker);
        npc:setAttackedBy(attacker);

        if SandboxVars.ImprovedProjectile.IPPJPVPLog then
            ImprovedProjectileServer.writePVPLog({args[1], args[2], BodyPartType.ToString(hitPart), originalDamage, hitDamage, actualDamage, args[5], args[6], npc:isDead()});
        end
    else
	    sendServerCommand(getPlayerByOnlineID(args[2]), "IPPJ", "hitPlayer", args);
        local victim = getPlayerByOnlineID(args[2]);
        if victim then
            victim:setAttackedBy(attacker);
        end
    end
end