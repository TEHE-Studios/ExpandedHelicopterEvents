local flareSystem = require "ExpandedHelicopter_Flares"
--local heatMap = require "ExpandedHelicopter_HeatMap" --/server/

local heatMap = {}

heatMap.events = {}
heatMap.cells = {} --heatLevel, centerX, centerY
heatMap.cellsIDs = {}

function heatMap.initModData(isNewGame)

    local cellData = ModData.getOrCreate("heatMap_cellData")
    if not cellData.cellsIDs then cellData.cellsIDs = {} end
    if not cellData.cells then cellData.cells = {} end

    heatMap.cellsIDs = cellData.cellsIDs
    heatMap.cells = cellData.cells

    heatMap.events = ModData.getOrCreate("heatMap_events")
end
Events.OnInitGlobalModData.Add(heatMap.initModData)


function heatMap.getHottestCell()
    heatMap.sortCellsByHeat()
    local hottestCell = heatMap.cells[heatMap.cellsIDs[1]]
    return hottestCell
end


function heatMap.getObjectRelativeHeatMapCell(object)
    if not object then return end
    local oX, oY = math.floor(object:getX()), math.floor(object:getY())
    local cellID = "x:"..math.floor(oX/300).."|y:"..math.floor(oY/300)
    local relativeCell = heatMap.cells[cellID]
    return relativeCell
end


function heatMap.sortCellsByHeat()
    table.sort(heatMap.cellsIDs, function(a,b) return heatMap.cells[a].heatLevel > heatMap.cells[b].heatLevel end)
end


function heatMap.calibrateCell(cellID, eventData)
    local cellData = heatMap.cells[cellID]

    local intensityFactor = eventData.intensity/cellData.heatLevel
    local avgX, avgY = (cellData.centerX+eventData.x)/2, (cellData.centerY+eventData.y)/2
    local xDiff, yDiff = math.abs(cellData.centerX-avgX), math.abs(cellData.centerX-avgY)
    local iX, iY = math.floor(xDiff*intensityFactor), math.floor(yDiff*intensityFactor)

    if cellData.centerX >= eventData.x then cellData.centerX = cellData.centerX-iX else cellData.centerX = cellData.centerX+iX end
    if cellData.centerY >= eventData.y then cellData.centerY = cellData.centerY-iX else cellData.centerY = cellData.centerY+iY end

    cellData.heatLevel = cellData.heatLevel+eventData.intensity
    cellData.eventCount = cellData.eventCount+1
end


function heatMap.coolOff()
    for key,e in pairs(heatMap.events) do
        if e and e.timeStamp+(e.intensity*1000) < getTimeInMillis() then

            if heatMap.cells[e.cellID] then

                local cellData = heatMap.cells[e.cellID]
                cellData.heatLevel = cellData.heatLevel-e.intensity
                cellData.eventCount = cellData.eventCount-1

                if cellData.eventCount <= 0 or cellData.heatLevel <= 0 then
                    heatMap.cells[e.cellID] = nil
                    for n,cellID in pairs(heatMap.cellsIDs) do
                        if cellID == e.cellID then
                            heatMap.cellsIDs[n] = nil
                        end
                    end
                end
            end
            heatMap.events[key] = nil
        end
    end
    if getDebug() then heatMap.sortCellsByHeat() end
end
Events.EveryHours.Add(heatMap.coolOff)


function heatMap.adjustByZone(x, y)
    local square = getSquare(x, y, 0)

    local intensity = 0.7
    if square then
        local zone = square:getZone()
        if zone then
            local zoneType = zone:getType()
            if zoneType then
                if (zoneType == "DeepForest") then intensity = 0.3
                elseif (zoneType == "Forest" or zoneType == "Vegitation") then intensity = 0.4
                elseif (zoneType == "FarmLand") then intensity = 0.5
                elseif (zoneType == "Farm") then intensity = 0.6
                elseif (zoneType == "TrailerPark" or zoneType == "Nav") then intensity = 0.9
                elseif (zoneType == "TownZone") then intensity = 1
                end
            end
        end
    end

    return intensity
end


function heatMap.registerEventByXY(x, y, intensity, type, timeStamp)
    intensity = intensity or 1
    type = type or "none"
    timeStamp = timeStamp or getTimeInMillis()

    intensity = intensity * heatMap.adjustByZone(x, y)

    if getDebug() then print("heatMap: "..type.."  x:"..x..", y:"..y) end

    local cellID = "x:"..math.floor(x/300).."|y:"..math.floor(y/300)

    if not heatMap.cells[cellID] then
        table.insert(heatMap.cellsIDs, cellID)
        heatMap.cells[cellID] = {heatLevel=intensity, centerX=math.floor(x), centerY=math.floor(y), eventCount=0}
    end

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


---@param flare InventoryItem|IsoObject
function heatMap.EHE_OnActivateFlare(flare)
    local containing = flare:getOutermostContainer()
    local flareLoc = (containing and containing:getParent()) or flare:getWorldItem()
    if flareLoc then
        local flareSq = flareLoc:getSquare()
        if flareSq and flareSq:isOutside() then heatMap.registerEventByObject(flareSq, 100, "activatedFlare") end
    end
end
Events.EHE_OnActivateFlare.Add(heatMap.EHE_OnActivateFlare)


---@param zombie IsoZombie|IsoGameCharacter|IsoMovingObject|IsoObject
---@param player IsoPlayer|IsoGameCharacter|IsoMovingObject|IsoObject
---@param weapon HandWeapon|InventoryItem
function heatMap.OnHitZombie(zombie, player, bodyPart, weapon)
    if zombie:isOutside() or player:isOutside() then heatMap.registerEventByObject(player, 10, "zombieHit") end
end
Events.OnHitZombie.Add(heatMap.OnHitZombie)


---@param zombie IsoZombie|IsoGameCharacter|IsoMovingObject|IsoObject
function heatMap.OnZombieDead(zombie)
    if zombie:isOutside() then heatMap.registerEventByObject(zombie, 20, "zombieKilled") end
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
        heatMap.registerEventByObject(player, 1, "playerMove")
    end
end
Events.OnPlayerMove.Add(heatMap.OnPlayerMove)


---@param player IsoPlayer|IsoGameCharacter|IsoMovingObject|IsoObject
function heatMap.OnPlayerDeath(player)
    if not player:isOutside() then return end
    heatMap.registerEventByObject(player, 20, "playerDeath")
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
            heatMap.registerEventByObject(player, intensity/2, "gunFire")
        end
    end
end
Events.OnWeaponSwing.Add(heatMap.OnWeaponSwing)



return heatMap