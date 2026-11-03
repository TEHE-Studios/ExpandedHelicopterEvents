LuaEventManager.AddEvent("EHE_ServerModDataReady")

local function onServerModDataReady(isNewGame) sendServerCommand("EHE_ServerModData", "severModData_received", {}) end
Events.EHE_ServerModDataReady.Add(onServerModDataReady)

require "ExpandedHelicopter00c_SpawnerAPI"
require "ExpandedHelicopter01f_ShadowSystem"
local eheFlareSystem = require "ExpandedHelicopter_Flares"

--sendClientCommand(player, module, command, args) end -- to server
local function onClientCommand(_module, _command, _player, _data)
	--serverside

	if _module == "CustomDebugPanel" then
		if _command == "launchHeliTest" then
			CustomDebugPanel.launchHeliTest(_data.presetID, _player, _data.moveCloser, _data.crashIt)
		end
	end

	if _module == "flare" then
		if _command == "activate" then
			eheFlareSystem.activateFlare(_data.flare, _data.duration, _data.loc)

		elseif _command == "validate" then
			eheFlareSystem.validateFlare(_data.flare, _data.timestamp, _data.loc)
		end
	end

	if _module == "SpawnerAPI" then
		if _command == "spawnZombie" then
			--print("--spawnZombie")
			--_dataA = player, _data = args
			SpawnerTEMP.spawnZombie(_data.outfitID, _data.x, _data.y, _data.z, _data.extraFunctions, _data.femaleChance, _data.processSquare)
		elseif _command == "spawnVehicle" then
			--print("--spawnVehicle")
			SpawnerTEMP.spawnVehicle(_data.vehicleType, _data.x, _data.y, _data.z, _data.extraFunctions, _data.extraParam, _data.processSquare)
		elseif _command == "spawnItem" then
			--print("--spawnItem")
			SpawnerTEMP.spawnItem(_data.itemType, _data.x, _data.y, _data.z, _data.extraFunctions, _data.extraParam, _data.processSquare)
		end
	end
end
Events.OnClientCommand.Add(onClientCommand)--/client/ to server
