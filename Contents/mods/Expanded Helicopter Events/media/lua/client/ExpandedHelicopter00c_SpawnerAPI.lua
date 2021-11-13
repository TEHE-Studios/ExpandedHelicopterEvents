---===---===---===---===---===---===--- TEMP
local StringUtils = {}
--- Transform a square position into a unique string
---@param square IsoGridSquare
---@return string
function StringUtils.SquareToId(square)
	return square:getX() .. "|" .. square:getY() .. "|" .. square:getZ()
end

--- Transform a position into a unique string
---@param x number
---@param y number
---@param z number
---@return string
function StringUtils.PositionToId(x, y ,z)
	return x .. "|" .. y .. "|" .. z
end
---===---===---===---===---===---===---


SpawnerAPI = {}

function SpawnerAPI.getOrSetPendingSpawnsList()
	return ModData.getOrCreate("farSquarePendingSpawns")
end


---@param itemType string
---@param x number
---@param y number
---@param z number
---@param extraFunctions table
---@param extraParam any
---@param processSquare function
function SpawnerAPI.spawnItem(itemType, x, y, z, extraFunctions, extraParam, processSquare)
	if not itemType then
		return
	end

	local currentSquare = getSquare(x,y,z)

	if currentSquare then
		if processSquare then
			currentSquare = processSquare(currentSquare)
		end
	end

	if currentSquare then
		x, y, z = currentSquare:getX(), currentSquare:getY(), currentSquare:getZ()
		local item = currentSquare:AddWorldInventoryItem(itemType, x, y, z)
		if item then
			SpawnerAPI.processExtraFunctionsOnto(item,extraFunctions)
		end
	else
		SpawnerAPI.setToSpawn("Item", itemType, x, y, z, extraFunctions, extraParam, processSquare)
	end
end

---@param vehicleType string
---@param x number
---@param y number
---@param z number
---@param extraFunctions table
---@param extraParam any
---@param processSquare function
function SpawnerAPI.spawnVehicle(vehicleType, x, y, z, extraFunctions, extraParam, processSquare)
	if not vehicleType then
		return
	end

	local currentSquare = getSquare(x,y,z)

	if currentSquare then
		if processSquare then
			currentSquare = processSquare(currentSquare)
		end
	end

	if currentSquare then
		local vehicle = addVehicleDebug(vehicleType, IsoDirections.getRandom(), nil, currentSquare)
		if vehicle then
			SpawnerAPI.processExtraFunctionsOnto(vehicle,extraFunctions)
		end
	else
		SpawnerAPI.setToSpawn("Vehicle", vehicleType, x, y, z, extraFunctions, extraParam, processSquare)
	end
end

---@param outfitID string
---@param x number
---@param y number
---@param z number
---@param extraFunctions table
---@param femaleChance number extraParam for other spawners; 0-100
---@param processSquare function
function SpawnerAPI.spawnZombie(outfitID, x, y, z, extraFunctions, femaleChance, processSquare)
	if not outfitID then
		return
	end

	local currentSquare = getSquare(x,y,z)

	if currentSquare then
		if processSquare then
			currentSquare = processSquare(currentSquare)
		end
	end

	if currentSquare then
		x, y, z = currentSquare:getX(), currentSquare:getY(), currentSquare:getZ()
		local zombies = addZombiesInOutfit(x, y, z, 1, outfitID, femaleChance)
		if zombies and zombies:size()>0 then
			SpawnerAPI.processExtraFunctionsOnto(zombies,extraFunctions)
		end
	else
		SpawnerAPI.setToSpawn("Zombie", outfitID, x, y, z, extraFunctions, femaleChance, processSquare)
	end
end



---@param spawned IsoObject | ArrayList
---@param functions table table of functions
function SpawnerAPI.processExtraFunctionsOnto(spawned,functions)
	if spawned and functions and (type(functions)=="table") then
		for k,func in pairs(functions) do
			if func then
				func(spawned)
			end
		end
	end
end


---@param spawnFuncType string This string is concated to the end of 'SpawnerAPI.spawn' to run a corresponding function.
---@param objectType string Module.Type for Items and Vehicles, OutfitID for Zombies
---@param x number
---@param y number
---@param z number
---@param funcsToApply table Table of functions which gets applied on the results of whatever is spawned.
function SpawnerAPI.setToSpawn(spawnFuncType, objectType, x, y, z, funcsToApply, extraParam, processSquare)
	local farSquarePendingSpawns = SpawnerAPI.getOrSetPendingSpawnsList()
	local positionID = StringUtils.PositionToId(x, y ,z)
	local positionList = farSquarePendingSpawns[positionID]
	if not positionList then
		farSquarePendingSpawns[positionID] = {}
	end

	local newEntry = {
		spawnFuncType=spawnFuncType,
		objectType=objectType,
		x=x,
		y=y,
		z=z,
		funcsToApply=funcsToApply,
		extraParam=extraParam,
		processSquare=processSquare
	}

	table.insert(positionList,newEntry)
end


---@param square IsoGridSquare
function SpawnerAPI.parseSquare(square)
	local farSquarePendingSpawns = SpawnerAPI.getOrSetPendingSpawnsList()

	if #farSquarePendingSpawns < 1 then
		return
	end

	local positionID = StringUtils.SquareToId(square)
	local positions = farSquarePendingSpawns[positionID]

	if #positions < 1 then
		return
	end

	for key,entry in pairs(positions) do
		if (not entry.spawned) then

			local shiftedSquare = square
			if entry.processSquare then
				shiftedSquare = entry.processSquare(shiftedSquare)
			end

			if shiftedSquare then
				local spawnFunc = SpawnerAPI["spawn"..entry.spawnFuncType]

				if spawnFunc then
					local spawnedObject = spawnFunc(entry.objectType, entry.x, entry.y, entry.z, entry.funcsToApply, entry.extraParam)
					if not spawnedObject then
						print("SpawnerAPI: ERR: item not spawned: "..entry.objectType.." ("..entry.x..","..entry.y..","..entry.z..")")
					end
				end
			end
			positions[key] = nil
		end
	end
	farSquarePendingSpawns[positionID] = nil
end
Events.LoadGridsquare.Add(SpawnerAPI.parseSquare)