spawnerAPI = {}

function spawnerAPI.getOrSetPendingSpawnsList()
	return ModData.getOrCreate("farSquarePendingSpawns")
end


---@param itemType string
---@param x number
---@param y number
---@param z number
---@param extraFunctions table
---@param extraParam any
---@param processSquare function
---@return InventoryItem
function spawnerAPI.spawnItem(itemType, x, y, z, extraFunctions, extraParam, processSquare)
	if not itemType then
		return
	end

	local currentSquare = getSquare(x,y,z)
	if processSquare then
		currentSquare = processSquare(currentSquare)
	end

	if currentSquare then
		x, y, z = currentSquare:getX(), currentSquare:getY(), currentSquare:getZ()
		local item = currentSquare:AddWorldInventoryItem(itemType, x, y, z)
		if item then
			spawnerAPI.processExtraFunctionsOnto(item,extraFunctions)
		end
	else
		spawnerAPI.setToSpawn("Item", itemType, x, y, z, extraFunctions, extraParam, processSquare)
	end
end

---@param vehicleType string
---@param x number
---@param y number
---@param z number
---@param extraFunctions table
---@param extraParam any
---@param processSquare function
---@return InventoryItem
function spawnerAPI.spawnVehicle(vehicleType, x, y, z, extraFunctions, extraParam, processSquare)
	if not vehicleType then
		return
	end

	local currentSquare = getSquare(x,y,z)
	if processSquare then
		currentSquare = processSquare(currentSquare)
	end

	if currentSquare then
		local vehicle = addVehicleDebug(vehicleType, IsoDirections.getRandom(), nil, currentSquare)
		if vehicle then
			spawnerAPI.processExtraFunctionsOnto(vehicle,extraFunctions)
		end
	else
		spawnerAPI.setToSpawn("Vehicle", vehicleType, x, y, z, extraFunctions, extraParam, processSquare)
	end
end

---@param outfitID string
---@param x number
---@param y number
---@param z number
---@param extraFunctions table
---@param femaleChance number extraParam for other spawners 0-100
---@param processSquare function
---@return InventoryItem
function spawnerAPI.spawnZombie(outfitID, x, y, z, extraFunctions, femaleChance, processSquare)
	if not outfitID then
		return
	end

	local currentSquare = getSquare(x,y,z)
	if processSquare then
		currentSquare = processSquare(currentSquare)
	end

	if currentSquare then
		x, y, z = currentSquare:getX(), currentSquare:getY(), currentSquare:getZ()
		local zombies = addZombiesInOutfit(x, y, z, 1, outfitID, femaleChance)
		if zombies and zombies:size()>0 then
			spawnerAPI.processExtraFunctionsOnto(zombies,extraFunctions)
		end
	else
		spawnerAPI.setToSpawn("Zombie", outfitID, x, y, z, extraFunctions, femaleChance, processSquare)
	end
end



---@param spawned IsoObject | ArrayList
---@param functions table table of functions
function spawnerAPI.processExtraFunctionsOnto(spawned,functions)
	if spawned and functions and (type(functions)=="table") then
		for k,func in pairs(functions) do
			if func then
				func(spawned)
			end
		end
	end
end


---@param spawnFuncType string This string is concated to the end of 'spawnerAPI.spawn' to run a corresponding function.
---@param objectType string Module.Type for Items and Vehicles, OutfitID for Zombies
---@param x number
---@param y number
---@param z number
---@param funcsToApply table Table of functions which gets applied on the results of whatever is spawned.
function spawnerAPI.setToSpawn(spawnFuncType, objectType, x, y, z, funcsToApply, extraParam, processSquare)
	local farSquarePendingSpawns = spawnerAPI.getOrSetPendingSpawnsList()
	table.insert(farSquarePendingSpawns,{ spawnFuncType=spawnFuncType, objectType=objectType, x=x, y=y, z=z,
		funcsToApply=funcsToApply, extraParam=extraParam, processSquare=processSquare })
end


---@param square IsoGridSquare
function spawnerAPI.parseSquare(square)
	local farSquarePendingSpawns = spawnerAPI.getOrSetPendingSpawnsList()

	if #farSquarePendingSpawns < 1 then
		return
	end

	local sqX, sqY, sqZ = square:getX(), square:getY(), square:getZ()
	for key,entry in pairs(farSquarePendingSpawns) do
		if (not entry.spawned) and entry.x==sqX and entry.y==sqY and entry.z==sqZ then


			local shiftedSquare = square
			if entry.processSquare then
				shiftedSquare = entry.processSquare(shiftedSquare)
			end

			if shiftedSquare then
				local spawnFunc = spawnerAPI["spawn"..entry.spawnFuncType]

				if spawnFunc then
					local spawnedObject = spawnFunc(entry.objectType, sqX, sqY, sqZ, entry.funcsToApply, entry.extraParam)
					if not spawnedObject then
						print("spawnerAPI: ERR: item not spawned: "..entry.objectType.." ("..sqX..","..sqY..","..sqZ..")")
					end
				end
			end
			farSquarePendingSpawns[key] = nil
		end
	end
end
Events.LoadGridsquare.Add(spawnerAPI.parseSquare)