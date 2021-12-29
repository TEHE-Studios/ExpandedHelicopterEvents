local Commands = {}
Commands.EHEMarkers = {}
function Commands.EHEMarkers.Receive(args)
	print(" - OnClient: Commands.EHEMarkers.Receive")
	if args then
		print(" --ARGS FOUND")
		EHE_EventMarkerHandler.setOrUpdateMarkers(args.poi, args.icon, args.duration, args.x, args.y)
	end
end
function onServerCommand(module, command, arguments)
	if Commands[module] and Commands[module][command] then
		Commands[module][command](arguments);
	end
end
Events.OnClientCommand.Add(onServerCommand);



function EHE_SendMarker(poi, icon, duration, x, y)

	print(" - EHEMarkers:")

	if getCore():getGameMode() ~= "Multiplayer" then
		print(" -- ELSE")
		EHE_EventMarkerHandler.setOrUpdateMarkers(poi, icon, duration, x, y)
	else
		print(" -- MP")
		sendClientCommand("EHEMarkers", "Receive", { poi=poi, icon=icon, duration=duration, x=x, y=y })
		sendServerCommand("EHEMarkers", "Receive", { poi=poi, icon=icon, duration=duration, x=x, y=y })
	end
end

