EHE_spawner = EHE_spawner or {}

function EHE_spawner.spawn(sq, funcType, spawnThis, extraFunctions, extraParam, processSquare)
    local currentSquare = sq

    if currentSquare and processSquare then
        local func = EHE_spawner.fetchFromDictionary(processSquare)
        if func then
            currentSquare = func(currentSquare)
        end
    end

    local spawned

    if funcType == "item" then spawned = currentSquare:AddWorldInventoryItem(spawnThis, 0, 0, 0) end

    if funcType == "vehicle" then spawned = addVehicleDebug(spawnThis, IsoDirections.getRandom(), nil, currentSquare) end

    if funcType == "zombie" then
        local x, y, z = currentSquare:getX(), currentSquare:getY(), currentSquare:getZ()
        spawned = addZombiesInOutfit(x, y, z, 1, spawnThis, extraParam)
    end

    if funcType == "NPCs" then
        print("SHAM")
        local player = getPlayer()
        local sq_above = getOutsideSquareFromAbove(sq)
        if sq_above then
            spawnThis.x = sq_above:getX()
            spawnThis.y = sq_above:getY()
            spawnThis.z = sq_above:getZ()
        end
        BanditServer.Spawner.Clan(player, spawnThis)
    end

    if spawned and extraFunctions then EHE_spawner.processExtraFunctionsOnto(spawned,extraFunctions) end
end