local Commands = {}
Commands.EHEMarkers = {}
Commands.EHE = {}
function Commands.EHEMarkers.Receive(player, args)
	print(" -SHARED: Commands.EHEMarkers.Receive"..player:getUsername())
	if args then
		print(" --ARGS FOUND")
		EHE_EventMarkerHandler.setOrUpdateMarkers(args.poi, args.icon, args.duration, args.x, args.y)
	end
end

function Commands.EHE.TempTest(player, args)
	print(" -SHARED: Commands.EHE.TempTest - "..player:getUsername())
end

function onServerCommand(module, command, arguments)
	if Commands[module] and Commands[module][command] then
		Commands[module][command](arguments)
	end
end
Events.OnClientCommand.Add(onServerCommand)
Events.OnServerCommand.Add(onServerCommand)