--for targeting
local bodyPartSelectionWeight = {
    ["Hand_L"]=5,["Hand_R"]=5,["ForeArm_L"]=10,["ForeArm_R"]=10,
    ["UpperArm_L"]=15,["UpperArm_R"]=15,["Torso_Upper"]=15,["Torso_Lower"]=15,
    ["Head"]=1,["Neck"]=1,["Groin"]=2,["UpperLeg_L"]=15,["UpperLeg_R"]=15,
    ["LowerLeg_L"]=10,["LowerLeg_R"]=10,["Foot_L"]=5,["Foot_R"]=5
}
local bodyPartSelection = {}
for type,weight in pairs(bodyPartSelectionWeight) do
    for i=1, weight do
        --print("body parts: "..i.." - "..type)
        table.insert(bodyPartSelection,type)
    end
end


local function getZombieByID(ID)
    ---@type IsoCell
    local cell = getCell()
    if not cell then return end

    local zombies = cell:getZombieList()
    if not zombies then return end

    for i=0, zombies:size()-1 do
        ---@type IsoZombie|IsoGameCharacter|IsoMovingObject|IsoObject
        local zombie = zombies:get(i)
        if zombie:getOnlineID()==ID then return zombie end
    end
end


function heliEventAttackHitOnIsoGameCharacter(damage, targetType, targetID)

    if isServer() then
        sendServerCommand("helicopterEvent", "attack", {damage=damage, targetType=targetType, targetID=targetID})
        return
    end

    ---@type IsoGameCharacter|IsoZombie|IsoPlayer|IsoMovingObject
    local targetHostile

    if targetType=="IsoZombie" and targetID then
        targetHostile = getZombieByID(targetID)
    elseif targetType=="IsoPlayer" then
        targetHostile = getPlayerByOnlineID(targetID)
    end

    if not targetHostile then
        if getDebug() then print("ERROR: event failed to find targetHostile to process attack hit.") end
        return
    end

    local bpRandSelect = bodyPartSelection[ZombRand(#bodyPartSelection)+1]
    local bpType = BodyPartType.FromString(bpRandSelect)
    local clothingBP = BloodBodyPartType.FromString(bpRandSelect)


    if (bpType == BodyPartType.Neck) or (bpType == BodyPartType.Head) then
        damage = damage*4
    elseif (bpType == BodyPartType.Torso_Upper) then
        damage = damage*2
    end

    targetHostile:addHole(clothingBP)
    targetHostile:addBlood(clothingBP, true, true, true)
    
    if instanceof(targetHostile, "IsoPlayer") then
        --Messy process just to knock down the player effectively
        targetHostile:clearVariable("BumpFallType")
        targetHostile:setBumpType("stagger")
        targetHostile:setBumpDone(false)
        targetHostile:setBumpFall(ZombRand(0, 101) <= 25)
        local bumpFallType = {"pushedBehind","pushedFront"}
        bumpFallType = bumpFallType[ZombRand(1,3)]
        targetHostile:setBumpFallType(bumpFallType)

        --print("  EHE:[hit-player]: damage:"..damage)
        --apply localized body part damage
        local bodyDMG = targetHostile:getBodyDamage()
        if bodyDMG then
            local bodyPart = bodyDMG:getBodyPart(bpType)
            if bodyPart then
                local protection = targetHostile:getBodyPartClothingDefense(BodyPartType.ToIndex(bpType), false, true)/100
                damage = damage * (1-(protection*0.75))
                --print("   -- [dampened] damage:"..damage.." protection:"..protection)
                bodyDMG:AddDamage(bpType,damage)
                bodyPart:damageFromFirearm(damage)
            end
        end

    elseif instanceof(targetHostile, "IsoZombie") then
        --Zombies receive damage directly because they don't have body parts or clothing protection
        targetHostile:addBlood(damage/100)
        damage = (damage*3)/50
        if not targetHostile:isStaggerBack() and not targetHostile:isbFalling() and not targetHostile:isOnFloor() then targetHostile:knockDown(ZombRand(2)==1 and true) end
        targetHostile:setHealth(math.max(0,targetHostile:getHealth()-damage))
        --print("  EHE:[hit-zombie]: damage:"..damage.." hp-after:"..targetHostile:getHealth())
        if targetHostile:getHealth() <= 0 then
            targetHostile:changeState(ZombieOnGroundState.instance())
            targetHostile:setAttackedBy(getCell():getFakeZombieForHit())
            targetHostile:becomeCorpse()
        end
    end


    --splatter a few times
    local splatIterations = ZombRand(3)+1
    for n=1, splatIterations do targetHostile:splatBloodFloor() end
end