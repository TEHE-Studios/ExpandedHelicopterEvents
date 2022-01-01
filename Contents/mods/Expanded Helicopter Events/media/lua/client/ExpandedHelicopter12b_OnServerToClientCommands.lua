--[[

--if isClient() then sendClientCommand(player, module, command, args) end -- to server
--if isServer() then sendServerCommand(player, module, command, args) end -- to client
function SpawnerTEMP.onCommand(_module, _command, _dataA, _dataB)
	if _module ~= "SpawnerAPI" then
		return
	end

	if isServer() then
		if _command == "spawnZombie" then
			--_dataA = player, _dataB = args
			SpawnerTEMP.spawnZombie(_dataB.outfitID, _dataB.x, _dataB.y, _dataB.z, _dataB.extraFunctions, _dataB.femaleChance, _dataB.processSquare)
		elseif _command == "spawnVehicle" then
			--elseif _command == "spawnItem" then
		end
	end

	if isClient() then
		if _command == "spawnZombie" then
			print("--spawnZombie-client")
			--_dataA = args, _dataB = null
		elseif _command == "spawnVehicle" then
		--elseif _command == "spawnItem" then
		end
	end

end
--Events.OnClientCommand.Add(SpawnerTEMP.onCommand)--/client/ to server
--Events.OnServerCommand.Add(SpawnerTEMP.onCommand)--/server/ to client

--]]