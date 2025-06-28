if isClient() then return end

require "EHE_globalModData"
require "EHE_mainVariables"
require "EHE_util"
require "EHE_presets"

EHE_spawner = {}

EHE_spawner.functionDictionary = {}
function EHE_spawner.fetchFromDictionary(ID) return EHE_spawner.functionDictionary[ID] end


function EHE_spawner.setDictionary()
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


local targetSquareOnLoad = require "!_TargetSquare_OnLoad"
function EHE_spawner.addCommand()
	targetSquareOnLoad.instance.OnLoadCommands.spawn = function(square, myCommand)
		EHE_spawner.spawn(square, myCommand.funcType, myCommand.spawnThis, myCommand.extraFunctions, myCommand.extraParam, myCommand.processSquare) end
end
Events.OnSGlobalObjectSystemInit.Add(EHE_spawner.addCommand)


function EHE_spawner.attemptToSpawn(x, y, z, funcType, spawnThis, extraFunctions, extraParam, processSquare)
	if not funcType or not spawnThis then return end

	local currentSquare = getSquare(x,y,z)

	if not currentSquare then
		targetSquareOnLoad.instance.addCommand(x,y,z, { command="spawn", funcType=funcType, spawnThis=spawnThis,
				  extraFunctions=extraFunctions, extraParam=extraParam, processSquare=processSquare })
		return
	else
		EHE_spawner.spawn(currentSquare, funcType, spawnThis, extraFunctions, extraParam, processSquare)
	end
end


function EHE_spawner.spawn(sq, funcType, spawnThis, extraFunctions, extraParam, processSquare)
	local currentSquare = sq
	if currentSquare and processSquare then
		local func = EHE_spawner.fetchFromDictionary(processSquare)
		if func then currentSquare = func(currentSquare) end
	end

	local spawned

	if funcType == "item" then spawned = currentSquare:AddWorldInventoryItem(spawnThis, 0, 0, 0) end

	if funcType == "vehicle" then spawned = addVehicleDebug(spawnThis, IsoDirections.getRandom(), nil, currentSquare) end

	if funcType == "zombie" then
		local x, y, z = currentSquare:getX(), currentSquare:getY(), currentSquare:getZ()
		spawned = addZombiesInOutfit(x, y, z, 1, spawnThis, extraParam)
	end

	if spawned and extraFunctions then EHE_spawner.processExtraFunctionsOnto(spawned,extraFunctions) end
end


---@param spawned IsoObject | ArrayList
---@param functions table table of functions
function EHE_spawner.processExtraFunctionsOnto(spawned,functions)
	if spawned and functions and (type(functions)=="table") then
		for k,funcID in pairs(functions) do
			local func = EHE_spawner.fetchFromDictionary(funcID)
			if func then
				func(spawned)
			end
		end
	end
end