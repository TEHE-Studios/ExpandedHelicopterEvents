require "ExpandedHelicopter00e_EHEGlobalModData"
require "ExpandedHelicopter01a_MainVariables"
require "ExpandedHelicopter00a_Util"
require "ExpandedHelicopter02a_Presets"

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

--TODO: DELETE THIS FILE AFTER CAPI IS MADE PUBLIC
SpawnerTEMP = {}

---=-=-=-=-=-=-=-=-=-=-=-=-[TEMPORARY STOPGAP]-=-=-=-=-=-=-=-=---
SpawnerTEMP.functionDictionary = {}

function SpawnerTEMP.fetchFromDictionary(ID)
	if ID then
		if SpawnerTEMP.functionDictionary[ID] then
			return SpawnerTEMP.functionDictionary[ID]
		end
	end
end

function SpawnerTEMP.setDictionary()
	SpawnerTEMP.functionDictionary.getOutsideSquareFromAbove_vehicle = getOutsideSquareFromAbove_vehicle
	SpawnerTEMP.functionDictionary.getOutsideSquareFromAbove = getOutsideSquareFromAbove
	SpawnerTEMP.functionDictionary.applyCrashOnVehicle = applyCrashOnVehicle
	SpawnerTEMP.functionDictionary.ageInventoryItem = ageInventoryItem
	SpawnerTEMP.functionDictionary.applyDeathOrCrawlerToCrew = applyDeathOrCrawlerToCrew
	SpawnerTEMP.functionDictionary.applyParachuteToCarePackage = applyParachuteToCarePackage

	for presetID,presetVars in pairs(eHelicopter_PRESETS) do
		local presetAddedFunc = presetVars["addedFunctionsToEvents"]
		if presetAddedFunc then
			for eventID,func in pairs(presetAddedFunc) do
				SpawnerTEMP.functionDictionary[presetID..eventID] = func
			end
		end
	end
end
Events.OnGameBoot.Add(SpawnerTEMP.setDictionary)
---=-=-=-=-=-=-=-=-=-=-=-=-

function SpawnerTEMP.getOrSetPendingSpawnsList()
	local modData = getExpandedHeliEventsModData()
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
function SpawnerTEMP.spawnItem(itemType, x, y, z, extraFunctions, extraParam, processSquare)
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
				local func = SpawnerTEMP.fetchFromDictionary(processSquare)
				if func then
					currentSquare = func(currentSquare)
				end
			end
		end

		if currentSquare then
			--x, y, z = currentSquare:getX(), currentSquare:getY(), currentSquare:getZ()
			local item = currentSquare:AddWorldInventoryItem(itemType, 0, 0, 0)
			if item and extraFunctions then
				SpawnerTEMP.processExtraFunctionsOnto(item,extraFunctions)
			end
		else
			SpawnerTEMP.setToSpawn("Item", itemType, x, y, z, extraFunctions, extraParam, processSquare)
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
function SpawnerTEMP.spawnVehicle(vehicleType, x, y, z, extraFunctions, extraParam, processSquare)
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
				local func = SpawnerTEMP.fetchFromDictionary(processSquare)
				if func then
					currentSquare = func(currentSquare)
				end
			end
		end

		if currentSquare then
			local vehicle = addVehicleDebug(vehicleType, IsoDirections.getRandom(), nil, currentSquare)
			if vehicle then
				SpawnerTEMP.processExtraFunctionsOnto(vehicle,extraFunctions)
			end
		else
			SpawnerTEMP.setToSpawn("Vehicle", vehicleType, x, y, z, extraFunctions, extraParam, processSquare)
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
function SpawnerTEMP.spawnZombie(outfitID, x, y, z, extraFunctions, femaleChance, processSquare)
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
				local func = SpawnerTEMP.fetchFromDictionary(processSquare)
				if func then
					currentSquare = func(currentSquare)
				end
			end
		end

		if currentSquare then
			x, y, z = currentSquare:getX(), currentSquare:getY(), currentSquare:getZ()
			local zombies = addZombiesInOutfit(x, y, z, 1, outfitID, femaleChance)
			if zombies and zombies:size()>0 then
				SpawnerTEMP.processExtraFunctionsOnto(zombies, extraFunctions)
			end
		else
			SpawnerTEMP.setToSpawn("Zombie", outfitID, x, y, z, extraFunctions, femaleChance, processSquare)
		end
	end
end



---@param spawned IsoObject | ArrayList
---@param functions table table of functions
function SpawnerTEMP.processExtraFunctionsOnto(spawned,functions)
	if spawned and functions and (type(functions)=="table") then
		for k,funcID in pairs(functions) do
			--print("EHE: DEBUG: processExtraFunctionsOnto: "..funcID)
			local func = SpawnerTEMP.fetchFromDictionary(funcID)
			if func then
				func(spawned)
			end
		end
	end
end


---@param spawnFuncType string This string is concated to the end of 'SpawnerTEMP.spawn' to run a corresponding function.
---@param objectType string Module.Type for Items and Vehicles, OutfitID for Zombies
---@param x number
---@param y number
---@param z number
---@param funcsToApply table Table of functions which gets applied on the results of whatever is spawned.
function SpawnerTEMP.setToSpawn(spawnFuncType, objectType, x, y, z, funcsToApply, extraParam, processSquare)
	local farSquarePendingSpawns = SpawnerTEMP.getOrSetPendingSpawnsList()
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
function SpawnerTEMP.parseSquare(square)
	local farSquarePendingSpawns = SpawnerTEMP.getOrSetPendingSpawnsList()
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
			local func = SpawnerTEMP.fetchFromDictionary(entry.processSquare)
			if func then
				shiftedSquare = func(shiftedSquare)
			end
		end

		if shiftedSquare then
			local spawnFunc = SpawnerTEMP["spawn"..entry.spawnFuncType]

			if spawnFunc then
				local spawnedObject = spawnFunc(entry.objectType, entry.x, entry.y, entry.z, entry.funcsToApply, entry.extraParam)
			end
		end
		--farSquarePendingSpawns[positionID][key] = nil
	end
	farSquarePendingSpawns[positionID] = nil
end
Events.LoadGridsquare.Add(SpawnerTEMP.parseSquare)