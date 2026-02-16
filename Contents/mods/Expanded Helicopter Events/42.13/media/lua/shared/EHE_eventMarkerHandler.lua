require "EHE_eventMarkers"
require "EHE_util"

eventMarkerHandler = {}
eventMarkerHandler.markers = {} --[player] = {["id"]=marker}
eventMarkerHandler.expirations = {} --[player] = {["id]=time}

function eventMarkerHandler.setOrUpdate(eventID, icon, duration, posX, posY, color)
	if SandboxVars.ExpandedHeli.EventMarkers == false then return end

	if isServer() then
		sendServerCommand("eventMarkerHandler", "setOrUpdateMarker", {eventID=eventID, icon=icon, duration=duration, posX=posX, posY=posY, color=color})
	else
		for p=1, getNumActivePlayers() do
			local player = getSpecificPlayer(p-1)
			if player then

				eventMarkerHandler.markers[player] = eventMarkerHandler.markers[player] or {}
				eventMarkerHandler.expirations[player] = eventMarkerHandler.expirations[player] or {}

				local marker = eventMarkerHandler.markers[player][eventID]
				eventMarkerHandler.expirations[player][eventID] = getGametimeTimestamp()+duration

				if not marker and duration>0 then
					if EHE_EventMarker then

						local dist = IsoUtils.DistanceTo(posX, posY, player:getX(), player:getY())
						if dist and (dist <= EHE_EventMarker.maxRange) then

							local oldX
							local oldY
							local pModData = player:getModData()["EHE_eventMarkerPlacement"]
							if pModData then
								oldX = pModData[1]
								oldY = pModData[2]
							end
							local screenX = oldX or (getCore():getScreenWidth()/2) - (EHE_EventMarker.iconSize/2)
							local screenY = oldY or (EHE_EventMarker.iconSize/2)

							marker = EHE_EventMarker:new(eventID, icon, duration, posX, posY, player, screenX, screenY, color)
							eventMarkerHandler.markers[player][eventID] = marker
						end
					end
				end

				if marker then
					marker.textureIcon = getTexture(icon)
					marker:setDuration(duration)
					marker:update(posX,posY)
				end
			end
		end
	end
end