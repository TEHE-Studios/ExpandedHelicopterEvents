EHE_EventMarkerHandler = {}
EHE_EventMarkerHandler.allPOI = {}

---@param player IsoObject | IsoMovingObject | IsoGameCharacter | IsoPlayer
function EHE_EventMarkerHandler.generateNewMarker(poi, player, icon, duration)
	if(player) then

		local oldx, oldy

		local pModData = player:getModData()["EHE_markerPlacement"]

		if pModData then
			oldx, oldy = pModData[1], pModData[2]
		end

		local screenX = oldx or (getCore():getScreenWidth()/2) - (EHE_EventMarker.iconSize/2)
		local screenY = oldy or (EHE_EventMarker.iconSize/2)
		local newMarker = EHE_EventMarker:new(poi, player, screenX, screenY, EHE_EventMarker.clickableSize, EHE_EventMarker.clickableSize, icon, duration)
		return newMarker
	end
end


function EHE_EventMarkerHandler.setOrUpdateMarkers(poi, icon, duration, x , y)
	if eHelicopterSandbox.config.eventMarkersOn == false then
		return
	end

	if not poi then
		poi = getCell():getOrCreateGridSquare(x,y,0)
	end

	local POI = EHE_EventMarkerHandler.allPOI[poi]

	if not POI then
		EHE_EventMarkerHandler.allPOI[poi] = {markers={}}
		POI = EHE_EventMarkerHandler.allPOI[poi]
	end

	--print("EHE: getOnlinePlayers():size(): "..getOnlinePlayers():size())

	local playersOnline = getOnlinePlayers()
	for i=0, playersOnline:size()-1 do
		---@type IsoPlayer
		local p = playersOnline:get(i)
		local marker = POI.markers[p:getPlayerIndex()+1]
		local isNew = false
		if not marker then
			marker = EHE_EventMarkerHandler.generateNewMarker(poi, p, icon, duration)
			POI.markers[p:getPlayerIndex()+1] = marker
			isNew = true
			--print("EHE:DEBUG: #"..poi.ID.." no marker found.")
		end

		if marker then
			if not isNew then
				marker.source = poi
				marker.textureIcon = getTexture(icon)
				marker.playerObj = p
			end
			marker:setDuration(duration)
		end
	end
end


function EHE_EventMarkerHandler.disableMarkersForPOI(poi)
	local POI = EHE_EventMarkerHandler.allPOI[poi]
	if POI then
		for playerIndex,marker in pairs(POI.markers) do
			marker:setVisible(false)
		end
	end
end


EHE_EventMarkerHandler.lastUpdateTime = -1
function EHE_EventMarkerHandler.updateAll()

	local timeStamp = getTimestampMs()
	if (EHE_EventMarkerHandler.lastUpdateTime+5 >= timeStamp) then
		return
	else
		EHE_EventMarkerHandler.lastUpdateTime = timeStamp
	end

	for poiObject,poiData in pairs(EHE_EventMarkerHandler.allPOI) do
		for playerIndex,marker in pairs(poiData.markers) do
			marker:update(playerIndex)
		end
	end
end
Events.OnTick.Add(EHE_EventMarkerHandler.updateAll)

