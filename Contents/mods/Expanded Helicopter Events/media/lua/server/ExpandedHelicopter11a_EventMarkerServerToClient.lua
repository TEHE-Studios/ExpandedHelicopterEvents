local Commands = {};
Commands.ModuleName = {};
function Commands.ModuleName.CommandName(arguments)
	--- do things on the client when this command has been received
	--- arguments is the kahlua table containing the data
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
		sendServerCommand("EHEMarkers", "Receive", { poi=poi, icon=icon, duration=duration, x=x, y=y })
	end
end

