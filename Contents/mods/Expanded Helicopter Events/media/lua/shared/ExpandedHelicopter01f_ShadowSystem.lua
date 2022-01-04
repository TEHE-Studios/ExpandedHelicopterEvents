require "ExpandedHelicopter00a_Util"

eventShadowHandler = {}
storedShadows = {}

--eventShadowHandler:setShadowPos(self.ID, self.shadowTexture, currentSquare:getX(),currentSquare:getY(),currentSquare:getX(),currentSquare:getZ())
function eventShadowHandler:setShadowPos(ID, texture, x, y, z)
	if isClient() then
		sendClientCommand("eventShadowHandler", "setShadowPos", {ID=ID,texture=texture,x=x,y=y,z=z})
	else
		print("set Shadow Pos: "..ID.." - "..texture.." - "..x..","..y..","..z)

		local square = getCell():getOrCreateGridSquare(x, y, 0)
		local outsideSquare
		if square then
			outsideSquare = getOutsideSquareFromAbove(square) or square
		end

		if not texture or not x or not y or not z then
			print("-- clear shadow")
			outsideSquare = nil
		end

		---@type WorldMarkers.GridSquareMarker
		local shadow = storedShadows["HELI"..ID]

		if not shadow and outsideSquare then
			print("-- no shadow but yes square")
			shadow = getWorldMarkers():addGridSquareMarker(texture, nil, outsideSquare, 0.2, 0.2, 0.2, true, 1, 0, 0.25, 0.25)
			if shadow then
				print("-- -- yes shadow and yes square")
				shadow:setAlpha(0.25)
				shadow:setPosAndSize(outsideSquare:getX(),outsideSquare:getY(),outsideSquare:getZ(), 5)
				storedShadows["HELI"..ID] = shadow
			end
		end

		if not outsideSquare then
			print("-- no square")
			if shadow then
				print("-- -- yes shadow : hide")
				shadow:setAlpha(0)
			end
		end
	end
end