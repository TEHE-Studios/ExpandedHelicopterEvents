function EHE_SendMarker(poi, icon, duration, x, y)
	if isClient() then
		--local player = getSpecificPlayer(0)
		--sendClientCommand(player,"EHEMarkers", "receiveMarker", { poi=poi, icon=icon, duration=duration, x=x, y=y })
	else
		EHE_EventMarkerHandler.setOrUpdateMarkers(poi, icon, duration, x, y)
	end
end

function EHE_ClientCommand(_module, _command, _args)
	if isClient() then
		print("EHE_ClientCommand")
		if _module == "EHEMarkers" and _command == "receiveMarker" then
			print("--receiveMarker")
			EHE_EventMarkerHandler.setOrUpdateMarkers(_args.poi, _args.icon, _args.duration, _args.x, _args.y)
		end
	end
end
Events.OnServerCommand.Add(EHE_ClientCommand)