---@param heli eHelicopter
function eHelicopter_dropAliensOff(heli)
    if not heli then
        return
    end

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

    eventMarkerHandler.setOrUpdate(getRandomUUID(), "media/ui/aliens.png", 750, x, y, heli.markerColor)
    heli:spawnCrew(x, y, 0)
    heli.addedFunctionsToEvents.OnHover = false
end


local abductees = {}
---@param heli eHelicopter
function eHelicopter_abductPlayer(heli, player)

    local targetPlayer = player or heli and heli.targetPlayer
    if not targetPlayer then return end

    if targetPlayer and not instanceof(targetPlayer, "IsoPlayer") then return end

    if targetPlayer then

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
                print("zombies:size(): ", zombies:size())
                for z = 0, zombies:size()-1 do
                    ---@type IsoZombie
                    local zombie = zombies:get(z)
                    local zSq = zombie and zombie:getSquare()
                    local zRoom = zSq and zSq:getRoom()
                    local zRoomDef = zRoom and zRoom:getRoomDef()
                    if zRoomDef and zRoomDef:getZ() == roomFound:getZ() then
                        zombie:teleportTo(zombie:getX(), zombie:getY(), 0)
                    end
                end
            end
        end

        local tBD = targetPlayer:getBodyDamage()
        local ayo = tBD:getBodyPart(BodyPartType.Groin)
        ayo:AddDamage(690)
        ayo:setAdditionalPain(ayo:getAdditionalPain()+690)

        local gifts = {"Chocolate_HeartBox","Roses","RubberHose","Gloves_Dish","Pillow_Heart"}
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