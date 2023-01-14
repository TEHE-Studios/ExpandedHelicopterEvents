LuaEventManager.AddEvent("EHE_ServerModDataReady")

local function onServerModDataReady(isNewGame)
	sendServerCommand("EHE_ServerModData", "severModData_received", {})
end
Events.EHE_ServerModDataReady.Add(onServerModDataReady)

require "ExpandedHelicopter00c_SpawnerAPI"
require "ExpandedHelicopter01f_ShadowSystem"

--sendClientCommand(player, module, command, args) end -- to server
local function onCommand(_module, _command, _player, _data)
	--serverside
	if _module == "eventMarkerHandler" and _command == "setOrUpdateMarker" then
		sendServerCommand("eventMarkerHandler", "setOrUpdateMarker", _data)

	elseif _module == "eventShadowHandler" and _command == "setShadowPos" then
		sendServerCommand("eventShadowHandler", "setShadowPos", _data)

	elseif _module == "SpawnerAPI" then
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
Events.OnClientCommand.Add(onCommand)--/client/ to server
