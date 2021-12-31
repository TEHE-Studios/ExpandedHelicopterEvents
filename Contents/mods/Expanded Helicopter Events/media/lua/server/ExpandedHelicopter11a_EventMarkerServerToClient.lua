function EHE_SendMarker(poi, icon, duration, x, y)
	--print(" - EHEMarkers:")
	if not isClient() then --getCore():getGameMode() ~= "Multiplayer" then
		--print(" -- ELSE")
		EHE_EventMarkerHandler.setOrUpdateMarkers(poi, icon, duration, x, y)
	else
		--print(" -- MP")

		local players = getActualPlayers(true)
		for k,player in pairs(players) do
			sendClientCommand(player,"EHEMarkers", "Receive", { poi=poi, icon=icon, duration=duration, x=x, y=y })
			sendServerCommand(player,"EHEMarkers", "Receive", { poi=poi, icon=icon, duration=duration, x=x, y=y })
		end
		--sendServerCommand("EHEMarkers", "Receive", { poi=poi, icon=icon, duration=duration, x=x, y=y })
	end
end


local Commands = {}
Commands.EHEMarkers = {}
Commands.EHE = {}
function Commands.EHEMarkers.Receive(player, args)
	print(" -SERVER: Commands.EHEMarkers.Receive"..player:getUsername())
	if args then
		print(" --ARGS FOUND")
		EHE_EventMarkerHandler.setOrUpdateMarkers(args.poi, args.icon, args.duration, args.x, args.y)
	end
end

function Commands.EHE.TempTest(player)
	print(" -SERVER: Commands.EHE.TempTest"..player:getUsername())
end

function onServerCommand(module, command, player, arguments)
	if Commands[module] and Commands[module][command] then
		Commands[module][command](player, arguments)
	end
end
Events.OnClientCommand.Add(onServerCommand)
Events.OnServerCommand.Add(onServerCommand)