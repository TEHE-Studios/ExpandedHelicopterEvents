--if isClient() then sendClientCommand(player, module, command, args) end -- to server
function SpawnerTEMP.onCommand(_module, _command, _dataA, _dataB)
	print("SpawnerTEMP.onCommand")
	if _module ~= "SpawnerAPI" then
		return
	end
	if isServer() then
		if _command == "spawnZombie" then
			--_dataA = player, _dataB = args
			SpawnerTEMP.spawnZombie(_dataB.outfitID, _dataB.x, _dataB.y, _dataB.z, _dataB.extraFunctions, _dataB.femaleChance, _dataB.processSquare)
		elseif _command == "spawnVehicle" then
			SpawnerTEMP.spawnVehicle(_dataB.vehicleType, _dataB.x, _dataB.y, _dataB.z, _dataB.extraFunctions, _dataB.extraParam, _dataB.processSquare)
		--elseif _command == "spawnItem" then
		end
	end
end
Events.OnClientCommand.Add(SpawnerTEMP.onCommand)--/client/ to server
