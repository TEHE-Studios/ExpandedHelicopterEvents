if isClient() then return end

require "EHE_globalModData"
require "EHE_mainVariables"
require "EHE_util"
require "EHE_presets"

EHE_spawner = EHE_spawner or {}


EHE_spawner.functionDictionary = false--{}
function EHE_spawner.fetchFromDictionary(ID)
	if not EHE_spawner.functionDictionary then EHE_spawner.setDictionary() end

	local func = EHE_spawner.functionDictionary[ID]
	if not func then print("WARNING: ",ID," not found in EHE_spawner.functionDictionary.") end

	return func
end


function EHE_spawner.setDictionary()
	EHE_spawner.functionDictionary = {}
	EHE_spawner.functionDictionary.getOutsideSquareFromAbove = getOutsideSquareFromAbove
	EHE_spawner.functionDictionary.applyCrashOnVehicle = applyCrashOnVehicle
	EHE_spawner.functionDictionary.applyFlaresToEvent = applyFlaresToEvent
	EHE_spawner.functionDictionary.ageInventoryItem = ageInventoryItem
	EHE_spawner.functionDictionary.applyDeathOrCrawlerToCrew = applyDeathOrCrawlerToCrew
	EHE_spawner.functionDictionary.applyParachuteToCarePackage = applyParachuteToCarePackage
	EHE_spawner.functionDictionary.applyCrashDamageToWorld = applyCrashDamageToWorld

	for presetID,presetVars in pairs(eHelicopter_PRESETS) do
		local presetAddedFunc = presetVars["addedFunctionsToEvents"]
		if presetAddedFunc then
			for eventID,func in pairs(presetAddedFunc) do
				EHE_spawner.functionDictionary[presetID..eventID] = func
			end
		end
	end
	print("Expanded Helicopter Events: EHE_spawner.functionDictionary set.")
end


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