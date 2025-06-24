require "EHE_globalModData"
require "EHE_mainVariables"
require "EHE_util"
require "EHE_presets"

---===---===---===---===---===---===--- TEMP
local stringyUtil = {}
--- Transform a square position into a unique string
---@param square IsoGridSquare
---@return string
function stringyUtil.SquareToId(square)
	return square:getX() .. "|" .. square:getY() .. "|" .. square:getZ()
end

--- Transform a position into a unique string
---@param x number
---@param y number
---@param z number
---@return string
function stringyUtil.PositionToId(x, y ,z)
	return x .. "|" .. y .. "|" .. z
end
---===---===---===---===---===---===---

EHE_spawner = {}

EHE_spawner.functionDictionary = {}

function EHE_spawner.fetchFromDictionary(ID)
	if ID then
		if EHE_spawner.functionDictionary[ID] then
			return EHE_spawner.functionDictionary[ID]
		end
	end
end

function EHE_spawner.setDictionary()
	EHE_spawner.functionDictionary.getOutsideSquareFromAbove_vehicle = getOutsideSquareFromAbove_vehicle
	EHE_spawner.functionDictionary.getOutsideSquareFromAbove = getOutsideSquareFromAbove
	EHE_spawner.functionDictionary.applyCrashOnVehicle = applyCrashOnVehicle
	EHE_spawner.functionDictionary.applyFlaresToEvent = applyFlaresToEvent
	EHE_spawner.functionDictionary.ageInventoryItem = ageInventoryItem
	EHE_spawner.functionDictionary.applyDeathOrCrawlerToCrew = applyDeathOrCrawlerToCrew
	EHE_spawner.functionDictionary.applyParachuteToCarePackage = applyParachuteToCarePackage

	for presetID,presetVars in pairs(eHelicopter_PRESETS) do
		local presetAddedFunc = presetVars["addedFunctionsToEvents"]
		if presetAddedFunc then
			for eventID,func in pairs(presetAddedFunc) do
				EHE_spawner.functionDictionary[presetID..eventID] = func
			end
		end
	end
end
Events.OnGameBoot.Add(EHE_spawner.setDictionary)
---=-=-=-=-=-=-=-=-=-=-=-=-

function EHE_spawner.getOrSetPendingSpawnsList()
	local modData = getExpandedHeliEventsModData and getExpandedHeliEventsModData()
	if not modData.FarSquarePendingSpawns then modData.FarSquarePendingSpawns = {} end
	return modData.FarSquarePendingSpawns
end


---@param itemType string
---@param x number
---@param y number
---@param z number
---@param extraFunctions table
---@param extraParam any
---@param processSquare function
function EHE_spawner.spawnItem(itemType, x, y, z, extraFunctions, extraParam, processSquare)
	if not itemType then
		return
	end
	if isClient() then
		sendClientCommand("SpawnerAPI", "spawnItem",
				{itemType=itemType,x=x,y=y,z=z,extraFunctions=extraFunctions,extraParam=extraParam,processSquare=processSquare})
	else
		local currentSquare = getSquare(x,y,z)

		if currentSquare then
			if processSquare then
				local func = EHE_spawner.fetchFromDictionary(processSquare)
				if func then
					currentSquare = func(currentSquare)
				end
			end
		end

		if currentSquare then
			--x, y, z = currentSquare:getX(), currentSquare:getY(), currentSquare:getZ()
			local item = currentSquare:AddWorldInventoryItem(itemType, 0, 0, 0)
			if item and extraFunctions then
				EHE_spawner.processExtraFunctionsOnto(item,extraFunctions)
			end
		else
			EHE_spawner.setToSpawn("Item", itemType, x, y, z, extraFunctions, extraParam, processSquare)
		end
	end
end

---@param vehicleType string
---@param x number
---@param y number
---@param z number
---@param extraFunctions table
---@param extraParam any
---@param processSquare function
function EHE_spawner.spawnVehicle(vehicleType, x, y, z, extraFunctions, extraParam, processSquare)
	if not vehicleType then
		return
	end
	if isClient() then
		sendClientCommand("SpawnerAPI", "spawnVehicle",
				{vehicleType=vehicleType,x=x,y=y,z=z,extraFunctions=extraFunctions,extraParam=extraParam,processSquare=processSquare})
	else
		local currentSquare = getSquare(x,y,z)

		if currentSquare then
			if processSquare then
				local func = EHE_spawner.fetchFromDictionary(processSquare)
				if func then
					currentSquare = func(currentSquare)
				end
			end
		end

		if currentSquare then
			local vehicle = addVehicleDebug(vehicleType, IsoDirections.getRandom(), nil, currentSquare)
			if vehicle then
				EHE_spawner.processExtraFunctionsOnto(vehicle,extraFunctions)
			end
		else
			EHE_spawner.setToSpawn("Vehicle", vehicleType, x, y, z, extraFunctions, extraParam, processSquare)
		end
	end
end

---@param outfitID string
---@param x number
---@param y number
---@param z number
---@param extraFunctions table
---@param femaleChance number extraParam for other spawners; 0-100
---@param processSquare function
function EHE_spawner.spawnZombie(outfitID, x, y, z, extraFunctions, femaleChance, processSquare)
	if not outfitID then
		return
	end
	if isClient() then
		sendClientCommand("SpawnerAPI", "spawnZombie",
				{outfitID=outfitID,x=x,y=y,z=z,extraFunctions=extraFunctions,femaleChance=femaleChance,processSquare=processSquare})
	else
		local currentSquare = getSquare(x,y,z)

		if currentSquare then
			if processSquare then
				local func = EHE_spawner.fetchFromDictionary(processSquare)
				if func then
					currentSquare = func(currentSquare)
				end
			end
		end

		if currentSquare then
			x, y, z = currentSquare:getX(), currentSquare:getY(), currentSquare:getZ()
			local zombies = addZombiesInOutfit(x, y, z, 1, outfitID, femaleChance)
			if zombies and zombies:size()>0 then
				EHE_spawner.processExtraFunctionsOnto(zombies, extraFunctions)
			end
		else
			EHE_spawner.setToSpawn("Zombie", outfitID, x, y, z, extraFunctions, femaleChance, processSquare)
		end
	end
end


if not isClient() then

	---@param spawned IsoObject | ArrayList
	---@param functions table table of functions
	function EHE_spawner.processExtraFunctionsOnto(spawned,functions)
		if spawned and functions and (type(functions)=="table") then
			for k,funcID in pairs(functions) do
				--print("EHE: DEBUG: processExtraFunctionsOnto: "..funcID)
				local func = EHE_spawner.fetchFromDictionary(funcID)
				if func then
					func(spawned)
				end
			end
		end
	end


	---@param spawnFuncType string This string is concated to the end of 'EHE_spawner.spawn' to run a corresponding function.
	---@param objectType string Module.Type for Items and Vehicles, OutfitID for Zombies
	---@param x number
	---@param y number
	---@param z number
	---@param funcsToApply table Table of functions which gets applied on the results of whatever is spawned.
	function EHE_spawner.setToSpawn(spawnFuncType, objectType, x, y, z, funcsToApply, extraParam, processSquare)
		local farSquarePendingSpawns = EHE_spawner.getOrSetPendingSpawnsList()
		local positionID = stringyUtil.PositionToId(x, y ,z)
		if not farSquarePendingSpawns[positionID] then
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

		table.insert(farSquarePendingSpawns[positionID],newEntry)
	end


	---@param square IsoGridSquare
	function EHE_spawner.parseSquare(square)
		local farSquarePendingSpawns = EHE_spawner.getOrSetPendingSpawnsList()
		local positionID = stringyUtil.SquareToId(square)
		local pendingItems = farSquarePendingSpawns[positionID]

		if not pendingItems then
			return
		end
		if #pendingItems < 1 then
			return
		end

		for key,entry in pairs(pendingItems) do
			local shiftedSquare = square
			if entry.processSquare then
				local func = EHE_spawner.fetchFromDictionary(entry.processSquare)
				if func then
					shiftedSquare = func(shiftedSquare)
				end
			end

			if shiftedSquare then
				local spawnFunc = EHE_spawner["spawn"..entry.spawnFuncType]

				if spawnFunc then
					local spawnedObject = spawnFunc(entry.objectType, entry.x, entry.y, entry.z, entry.funcsToApply, entry.extraParam)
				end
			end
			--farSquarePendingSpawns[positionID][key] = nil
		end
		farSquarePendingSpawns[positionID] = nil
	end
	Events.LoadGridsquare.Add(EHE_spawner.parseSquare)

end