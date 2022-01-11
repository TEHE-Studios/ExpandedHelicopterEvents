require "ExpandedHelicopter00c_SpawnerAPI"
require "ExpandedHelicopter01f_ShadowSystem"
require "ExpandedHelicopter01b_MainSounds"

--if isClient() then sendClientCommand(player, module, command, args) end -- to server
local function onCommand(_module, _command, _dataA, _dataB)
	--serverside
	if _module == "sendLooper" then
		if _command == "ping" then
			--print("--sendLooper:ping -- ".._dataB.command)
			sendServerCommand("sendLooper", _dataB.command, _dataB)
		end

	elseif _module == "eventMarkerHandler" and _command == "setOrUpdateMarker" then
		sendServerCommand("eventMarkerHandler", "setOrUpdateMarker", _dataB)

	elseif _module == "eventShadowHandler" and _command == "setShadowPos" then
		sendServerCommand("eventShadowHandler", "setShadowPos", _dataB)

	elseif _module == "SpawnerAPI" then
		if _command == "spawnZombie" then
			--print("--spawnZombie")
			--_dataA = player, _dataB = args
			SpawnerTEMP.spawnZombie(_dataB.outfitID, _dataB.x, _dataB.y, _dataB.z, _dataB.extraFunctions, _dataB.femaleChance, _dataB.processSquare)
		elseif _command == "spawnVehicle" then
			--print("--spawnVehicle")
			SpawnerTEMP.spawnVehicle(_dataB.vehicleType, _dataB.x, _dataB.y, _dataB.z, _dataB.extraFunctions, _dataB.extraParam, _dataB.processSquare)
		elseif _command == "spawnItem" then
			--print("--spawnItem")
			SpawnerTEMP.spawnItem(_dataB.itemType, _dataB.x, _dataB.y, _dataB.z, _dataB.extraFunctions, _dataB.extraParam, _dataB.processSquare)
		end
	end
end
Events.OnClientCommand.Add(onCommand)--/client/ to server
--Events.OnServerCommand.Add(onCommand)--/server/ to client
