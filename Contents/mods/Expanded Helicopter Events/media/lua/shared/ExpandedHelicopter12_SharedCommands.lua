function EHE_SendMarker(poi, icon, duration, x, y)
	if isClient() then
		local player = getSpecificPlayer(0)
		sendClientCommand(player,"EHEMarkers", "receiveMarker", { poi=poi, icon=icon, duration=duration, x=x, y=y })
	else
		EHE_EventMarkerHandler.setOrUpdateMarkers(poi, icon, duration, x, y)
	end
end

function EHE_onCommand(_module, _command, _dataA, _dataB)
	if isServer() then
		print("EHE_ServerCommand")
		if _module == "EHEMarkers" and _command == "receiveMarker" then
			print("--receiveMarker")
			--_dataA = player
			--_dataB = args
			sendServerCommand(_dataA, _module, _command, _dataB)
			--EHE_EventMarkerHandler.setOrUpdateMarkers(_args.poi, _args.icon, _args.duration, _args.x, _args.y)
		end
	end
	if isClient() then
		print("EHE_ClientCommand")
		if _module == "EHEMarkers" and _command == "receiveMarker" then
			print("--receiveMarker")
			--_dataA = args
			--_dataB = null
			EHE_EventMarkerHandler.setOrUpdateMarkers(_dataA.poi, _dataA.icon, _dataA.duration, _dataA.x, _dataA.y)
		end
	end
end
Events.OnClientCommand.Add(EHE_onCommand)--server/
Events.OnServerCommand.Add(EHE_onCommand)--client/