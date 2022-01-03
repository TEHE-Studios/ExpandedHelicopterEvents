require "ExpandedHelicopter00c_SpawnerAPI"

--if isClient() then sendClientCommand(player, module, command, args) end -- to server
local function onCommand(_module, _command, _dataA, _dataB)
	--serverside
	if _module == "sendLooper" then
		if _command == "ping" then
			--print("--sendLooper:ping -- ".._dataB.command)
			sendServerCommand("sendLooper", _dataB.command, _dataB)
		end

	elseif _module == "EHE_EventMarkerHandler" then
		if _command == "new" then
			return EHE_EventMarker:new(_dataB.poi, _dataB.p, _dataB.sX, _dataB.sY, _dataB.w, _dataB.h, _dataB.icon, _dataB.duration)
		elseif _command == "update" then
			EHE_EventMarkerHandler.updateAll()
		end

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
