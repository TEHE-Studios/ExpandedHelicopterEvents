local util = require("EHE_util.lua")
EHE_spawner = EHE_spawner or {}

function EHE_spawner.getLandSquare(square, range)
    if not square:isWaterSquare() then return square end
    local x, y, z = square:getX(), square:getY(), square:getZ()
    for r=1, range do
        for dx=-r, r do
            for dy=-r, r do
                if math.abs(dx)==r or math.abs(dy)==r then
                    local sq = getSquare(x+dx, y+dy, z)
                    if sq and sq:isOutside() and not sq:isWaterSquare() then return sq end
                end
            end
        end
    end
end


function EHE_spawner.spawn(sq, funcType, spawnThis, extraFunctions, extraParam, processSquare)
    local currentSquare = sq

    if currentSquare and processSquare then
        local func = EHE_spawner.fetchFromDictionary(processSquare)
        if func then
            currentSquare = func(currentSquare)
        end
    end

    if not currentSquare then return end
    if funcType == "item" and currentSquare:isWaterSquare() then return end
    currentSquare = EHE_spawner.getLandSquare(currentSquare, 15)
    if not currentSquare then return end

    local spawned

    if funcType == "item" then spawned = currentSquare:AddWorldInventoryItem(spawnThis, 0, 0, 0) end

    if funcType == "vehicle" then spawned = addVehicleDebug(spawnThis, IsoDirections.getRandom(), nil, currentSquare) end

    if funcType == "zombie" then
        local x, y, z = currentSquare:getX(), currentSquare:getY(), currentSquare:getZ()
        spawned = addZombiesInOutfit(x, y, z, 1, spawnThis, extraParam)
    end

    if funcType == "NPCs" then
        local player = getPlayer()
        local sq_above = util.getOutsideSquareFromAbove(sq)
        if sq_above then
            spawnThis.x = sq_above:getX()
            spawnThis.y = sq_above:getY()
            spawnThis.z = sq_above:getZ()
        end
        BanditServer.Spawner.Clan(player, spawnThis)
    end

    if spawned and extraFunctions then EHE_spawner.processExtraFunctionsOnto(spawned,extraFunctions,extraParam) end
end