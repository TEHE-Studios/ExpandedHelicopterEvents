---true actions dancing isn't on B42
--[[
local activeMods = {}
local activeModIDs = getActivatedMods()
for i=1, activeModIDs:size() do
    local modID = activeModIDs:get(i-1)
    if not activeMods[modID] then
        activeMods[modID] = true
    end
end



local OrdinaryDance = {
    "BobTA_African_Noodle", "BobTA_African_Rainbow", "BobTA_Arm_Push", "BobTA_Arm_Wave_One", "BobTA_Arm_Wave_Two",
    "BobTA_Arms_Hip_Hop", "BobTA_Around_The_World", "BobTA_Bboy_Hip_Hop_One", "BobTA_Bboy_Hip_Hop_Three", "BobTA_Bboy_Hip_Hop_Two",
    "BobTA_Body_Wave", "BobTA_Booty_Step", "BobTA_Breakdance_Brooklyn_Uprock", "BobTA_Cabbage_Patch", "BobTA_Can_Can",
    "BobTA_Charleston", "BobTA_Chicken", "BobTA_Crazy_Legs", "BobTA_Defile_De_Samba_Parade", "BobTA_Gandy", "BobTA_Hokey_Pokey",
    "BobTA_House_Dancing", "BobTA_Kick_Step", "BobTA_Locking", "BobTA_Macarena", "BobTA_Maraschino", "BobTA_MoonWalk_One",
    "BobTA_Moonwalk_Two", "BobTA_Northern_Soul_Spin", "BobTA_Northern_Soul_Spin_On_Floor", "BobTA_Raise_The_Roof",
    "BobTA_Really_Twirl", "BobTA_Rib_Pops", "BobTA_Rockette_Kick", "BobTA_Rumba_Dancing", "BobTA_Running_Man_One",
    "BobTA_Running_Man_Three", "BobTA_Running_Man_Two", "BobTA_Salsa", "BobTA_Salsa_Double_Twirl", "BobTA_Salsa_Double_Twirl_and_Clap",
    "BobTA_Salsa_Side_to_Side", "BobTA_Shim_Sham", "BobTA_Shimmy", "BobTA_Shuffling", "BobTA_Side_to_Side", "BobTA_Thriller_One",
    "BobTA_Twist_One", "BobTA_Twist_Two", "BobTA_Uprock_Indian_Step", "BobTA_YMCA",}
---@param char IsoGameCharacter
function forceDance(heli, char)

    for k,v in pairs(activeMods) do
        print("v:",v)
    end

    if not activeMods["TrueActionsDancing"] then return end

    if instanceof(char, "IsoPlayer") then

        local dancing = char:getVariableBoolean("emote")
        if (not dancing) then
            local dance = OrdinaryDance[ZombRand(#OrdinaryDance)+1]
            local danceRecipe = string.gsub(dance, "_", " ")
            if not char:isRecipeKnown(danceRecipe) then
                char:getKnownRecipes():add(danceRecipe)
            end
            char:playEmote(dance)
        end
    end
end
--]]
local swhSubEvents = {}

---@param heli eHelicopter
function swhSubEvents.dropAliensOff(heli)
    if not heli then return end

    local x, y, z = heli:getXYZAsInt()
    local xOffset = ZombRand(20,35)
    local yOffset = ZombRand(20,35)

    local targetPlayer = heli.targetPlayer
    if targetPlayer then
        local tX, tY = targetPlayer:getX(), targetPlayer:getY()
        xOffset=math.max(0,xOffset-tX)
        yOffset=math.max(0,yOffset-tY)
    end

    if ZombRand(101) <= 50 then
        xOffset=0-xOffset
    end
    if ZombRand(101) <= 50 then
        yOffset=0-yOffset
    end

    x = x+xOffset
    y = y+yOffset

    --[[DEBUG]] print("SWH: DEBUG: eHelicopter_dropCrewOff: "..x..","..y)
    --for k,v in pairs(heli.crew) do print(" -- k:"..tostring(k).." -- ("..tostring(v)..")") end

    eventMarkerHandler.setOrUpdate(getRandomUUID(), "media/ui/aliens.png", 550, x, y, heli.markerColor)
    heli:spawnDeadCrew(x, y, 0)
    heli.addedFunctionsToEvents.OnHover = false
end


local abductees = {}
---@param heli eHelicopter
function swhSubEvents.abductPlayer(heli, player)

    local targetPlayer = player or heli and heli.target
    if not targetPlayer then return end

    if targetPlayer and not instanceof(targetPlayer, "IsoPlayer") then return end

    if targetPlayer then
        heli.addedFunctionsToEvents.OnHover = false
        abductees[targetPlayer] = true

        local SleepHours = 4

        SleepHours = SleepHours + GameTime.getInstance():getTimeOfDay()
        if SleepHours >= 24 then SleepHours = SleepHours - 24 end

        targetPlayer:setVariable("ExerciseStarted", false)
        targetPlayer:setVariable("ExerciseEnded", true)

        targetPlayer:setForceWakeUpTime(SleepHours)
        targetPlayer:setAsleepTime(0.0)
        targetPlayer:setAsleep(true)
        getSleepingEvent():setPlayerFallAsleep(targetPlayer, SleepHours)

        local tNum = targetPlayer:getPlayerNum()
        UIManager.setFadeBeforeUI(tNum, true)
        UIManager.FadeOut(tNum, 0.5)

        local buildings = getWorld():getMetaGrid():getBuildings()
        local top5 = {}
        local count = 0

        for b = 0, buildings:size() - 1 do
            ---@type BuildingDef
            local building = buildings:get(b)
            if building then
                local level = building:getMaxLevel()
                if count < 5 or level > top5[count].level then
                    local inserted = false
                    for i = 1, count do
                        if level > top5[i].level then
                            for j = math.min(count, 4), i, -1 do top5[j + 1] = top5[j] end
                            top5[i] = { building = building, level = level }
                            inserted = true
                            break
                        end
                    end
                    if not inserted and count < 5 then top5[count + 1] = { building = building, level = level } end
                    if count < 5 then count = count + 1 end
                end
            end
        end

        local rand = ZombRand(#top5)+1
        local randTop = top5[rand]
        local foundBuilding = randTop.building
        local maxLevel = randTop.level

        local rX, rY, rZ
        ---@type RoomDef
        local roomFound

        if foundBuilding then
            local rooms = foundBuilding:getRooms()
            for r = 0, rooms:size()-1 do
                ---@type RoomDef
                local room = rooms:get(r)
                if room and room:getZ() == maxLevel then
                    roomFound = room
                    rX = room:getX() + room:getW()/2
                    rY = room:getY() + room:getH()/2
                    rZ = room:getZ()
                    break
                end
            end
        end

        if rX and rY and rZ then
            --if isClient() then --do MP later SendCommandToServer("/teleportto " .. tostring(rX) .. "," .. tostring(rY) .. ",".. tostring(rZ))

            targetPlayer:teleportTo(rX, rY, rZ)
            if roomFound then
                local zombies = getWorld():getCell():getZombieList()
                for z = 0, zombies:size()-1 do
                    ---@type IsoZombie
                    local zombie = zombies:get(z)
                    local zSq = zombie and zombie:getSquare()
                    local zRoom = zSq and zSq:getRoom()
                    local zRoomDef = zRoom and zRoom:getRoomDef()
                    if zRoomDef and math.abs(zRoomDef:getZ()-roomFound:getZ()) <= 3 then
                        zombie:teleportTo(zombie:getX(), zombie:getY(), 0)
                    end
                end
            end
        end

        local tBD = targetPlayer:getBodyDamage()
        local ayo = tBD:getBodyPart(BodyPartType.Groin)
        ayo:AddDamage(69)
        ayo:setAdditionalPain(ayo:getAdditionalPain()+69)

        local gifts = {"Chocolate_HeartBox","Roses","RubberHose","Gloves_Dish","Pillow_Heart","WaterBottle"}
        local itemContainer = targetPlayer:getInventory()
        for _,gift in pairs(gifts) do itemContainer:AddItems(gift, 1) end

        if IsoPlayer.allPlayersAsleep() then
            UIManager.getSpeedControls():SetCurrentGameSpeed(3)
            save(true)
        end

        if JoypadState.players[tNum+1] then setJoypadFocus(tNum, nil) end

        abductees[targetPlayer] = nil
    end
end

---@param cow IsoPlayer|IsoAnimal
function swhSubEvents.abductCow(heli, cow)

    if not cow then return end
    if cow and (not instanceof(cow, "IsoPlayer")) then return end

    if cow then
        heli.addedFunctionsToEvents.OnAttack = false
        cow:removeFromWorld()
        print("Cow Abducted")
    end
end

return swhSubEvents