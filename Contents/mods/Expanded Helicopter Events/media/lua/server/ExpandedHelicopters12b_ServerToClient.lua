function EHE_ServerCommand(_module, _command, player, _args)
	if isServer() then
		print("EHE_ServerCommand")
		if _module == "EHEMarkers" and _command == "receiveMarker" then
			print("--receiveMarker")
			sendServerCommand(player, _module, _command, _args)
			--EHE_EventMarkerHandler.setOrUpdateMarkers(_args.poi, _args.icon, _args.duration, _args.x, _args.y)
		end
	end
end
Events.OnClientCommand.Add(EHE_ServerCommand)