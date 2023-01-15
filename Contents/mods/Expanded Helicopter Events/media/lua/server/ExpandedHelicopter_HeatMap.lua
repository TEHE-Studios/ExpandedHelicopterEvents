require "ExpandedHelicopter_Flares"

local heatMap = {}

heatMap.events = {}
heatMap.cells = {}

function heatMap.initModData(isNewGame)
    heatMap.events = ModData.getOrCreate("heatMap_events")
    heatMap.cells = ModData.getOrCreate("heatMap_cells")
end
Events.OnInitGlobalModData.Add(heatMap.initModData)


function heatMap.calibrateCell(cellID, eventData)
    local cellData = heatMap.cells[cellID]

    local intensityPull = eventData.intensity/cellData.level

    cellData.level = cellData.level+eventData.intensity
    cellData.eventCount = cellData.eventCount+1

    cellData.centerX = math.floor((cellData.centerX + (eventData.x*intensityPull) ) /2)
    cellData.centerY = math.floor((cellData.centerY + (eventData.y*intensityPull) ) /2)
end


function heatMap.coolOff()
    for key,e in pairs(heatMap.events) do
        if e and e.timeStamp+(e.intensity*1000) > getTimeInMillis() then

            if heatMap.cells[e.cellID] then

                local cellData = heatMap.cells[e.cellID]
                cellData.level = cellData.level-e.intensity
                cellData.eventCount = cellData.eventCount-1
                if cellData.eventCount <= 0 or cellData.level <= 0 then
                    heatMap.cells[e.cellID] = nil
                end
            end

            heatMap.events[key] = nil
        end
    end
end
Events.EveryTenMinutes.Add(heatMap.coolOff)


function heatMap.registerEventByXY(x, y, intensity, type, timeStamp)
    intensity = intensity or 1
    type = type or "none"
    timeStamp = timeStamp or getTimeInMillis()

    if getDebug() then print("registerEventByXY: "..type.."  x:"..x..", y:"..y) end

    local cellID = "x:"..math.floor(x/300).."-y:"..math.floor(y/300)
    heatMap.cells[cellID] = heatMap.cells[cellID] or {level=intensity, centerX=x, centerY=y, eventCount=0}

    local eventData = {cellID=cellID, x=x, y=y, intensity=intensity, type=type, timeStamp=timeStamp}

    heatMap.calibrateCell(cellID, eventData)
    table.insert(heatMap.events, eventData)
end


function heatMap.registerEventByObject(object, intensity, type, timeStamp)

    local x, y
    if instanceof(object, "IsoObject") or instanceof(object,"IsoGridSquare") then
        x, y = math.floor(object:getX()), math.floor(object:getY())
    else
        print("ERROR: registerEventByObject: invalid object: "..tostring(object))
        return
    end

    if not (x and y) then
        print("ERROR: registerEventByObject: invalid loc:  x:"..tostring(x)..", y:"..tostring(y))
        return
    end

    heatMap.registerEventByXY(x, y, intensity, type, timeStamp)
end


function heatMap.EHE_OnActivateFlare(flare)
    if flare:isOutside() then heatMap.registerEventByObject(flare, 10, "activatedFlare") end
end
Events.EHE_OnActivateFlare.Add(heatMap.EHE_OnActivateFlare)


---@param zombie IsoZombie|IsoGameCharacter|IsoMovingObject|IsoObject
---@param player IsoPlayer|IsoGameCharacter|IsoMovingObject|IsoObject
---@param weapon HandWeapon|InventoryItem
function heatMap.OnHitZombie(zombie, player, bodyPart, weapon)
    if zombie:isOutside() or player:isOutside() then heatMap.registerEventByObject(player, 1, "zombieHit") end
end
Events.OnHitZombie.Add(heatMap.OnHitZombie)


---@param zombie IsoZombie|IsoGameCharacter|IsoMovingObject|IsoObject
function heatMap.OnZombieDead(zombie)
    if zombie:isOutside() then heatMap.registerEventByObject(zombie, 2, "zombieKilled") end
end
Events.OnZombieDead.Add(heatMap.OnZombieDead)


local onceEveryList, soManyTicks = {}, 100
---@param player IsoPlayer|IsoGameCharacter|IsoMovingObject|IsoObject
function heatMap.OnPlayerMove(player)
    if not player:isOutside() then return end
    onceEveryList[player] = onceEveryList[player] or soManyTicks
    onceEveryList[player] = onceEveryList[player]-1
    if onceEveryList[player] <= 0 then
        onceEveryList[player] = soManyTicks
        heatMap.registerEventByObject(player, 0.1, "playerMove")
    end
end
Events.OnPlayerMove.Add(heatMap.OnPlayerMove)


---@param player IsoPlayer|IsoGameCharacter|IsoMovingObject|IsoObject
function heatMap.OnPlayerDeath(player)
    if not player:isOutside() then return end
    heatMap.registerEventByObject(player, 2, "playerDeath")
end
Events.OnPlayerDeath.Add(heatMap.OnPlayerDeath)


---@param player IsoPlayer|IsoGameCharacter|IsoMovingObject|IsoObject
---@param weapon HandWeapon|InventoryItem
function heatMap.OnWeaponSwing(player,weapon)
    if player and weapon then
        local wepOk = (weapon:getCategory() == "Weapon") and weapon:isRanged() and (not weapon:isJammed())
        local notShoving = (player.isShoving and not player:isShoving()) or (player.isDoShove and not player:isDoShove())
        local hasAmmo = (weapon:haveChamber() and weapon:isRoundChambered()) or (not weapon:haveChamber() and weapon:getCurrentAmmoCount() > 0)

        if wepOk and notShoving and hasAmmo then
            local intensity = weapon:getSoundRadius()
            if isClient() or isServer() then intensity = intensity / 1.8 end
            heatMap.registerEventByObject(player, intensity/10, "gunFire")
        end
    end
end
Events.OnWeaponSwing.Add(heatMap.OnWeaponSwing)



return heatMap