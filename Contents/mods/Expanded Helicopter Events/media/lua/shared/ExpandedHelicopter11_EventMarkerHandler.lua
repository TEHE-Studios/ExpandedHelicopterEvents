require "ExpandedHelicopter10_EventMarkers"
require "ExpandedHelicopter00a_Util"

eventMarkerHandler = {}
eventMarkerHandler.markers = {} --[player] = {["id"]=marker}
eventMarkerHandler.expirations = {} --[player] = {["id]=time}

--set
--updatePos
--unSet
--OnPlayerUpdate

function eventMarkerHandler.setOrUpdate(eventID, icon, duration, posX, posY, override)
	if eHelicopterSandbox.config.eventMarkersOn == false then
		return
	end
	--print("eventMarker: eventID:"..tostring(eventID).." icon:"..tostring(icon).." duration:"..tostring(duration).." posX:"..tostring(posX).." posY:"..tostring(posY).." override:"..tostring(override))
	if not override and isClient() then
		sendClientCommand("eventMarkerHandler", "setOrUpdateMarker", {eventID=eventID, icon=icon, duration=duration, posX=posX, posY=posY})
	else
		for p=1, getNumActivePlayers() do
			local player = getSpecificPlayer(p-1)
			if player then

				--print(" - player:"..player:getUsername())
				eventMarkerHandler.markers[player] = eventMarkerHandler.markers[player] or {}
				eventMarkerHandler.expirations[player] = eventMarkerHandler.expirations[player] or {}

				local marker = eventMarkerHandler.markers[player][eventID]
				eventMarkerHandler.expirations[player][eventID] = getGametimeTimestamp()+duration

				if not marker and duration>0 then
					local dist = IsoUtils.DistanceTo(posX, posY, player:getX(), player:getY())
					if dist and (dist <= EHE_EventMarker.maxRange) then
						--print(" -- not marker: generating")
						local oldX
						local oldY
						local pModData = player:getModData()["EHE_eventMarkerPlacement"]
						if pModData then
							oldX = pModData[1]
							oldY = pModData[2]
						end
						local screenX = oldX or (getCore():getScreenWidth()/2) - (EHE_EventMarker.iconSize/2)
						local screenY = oldY or (EHE_EventMarker.iconSize/2)
						--print("eventMarkerHandler: generateNewMarker: "..p:getUsername().." ".."("..screenX..","..screenY..")")

						marker = EHE_EventMarker:new(eventID, icon, duration, posX, posY, player, screenX, screenY)
						eventMarkerHandler.markers[player][eventID] = marker
					else
						--print("-- dist not valid: "..tostring(dist))
					end
				end

				if marker then
					--print(" --- marker given duration")
					marker.textureIcon = getTexture(icon)
					marker:setDuration(duration)
					marker:update(posX,posY)
				end
			end
		end
	end
end