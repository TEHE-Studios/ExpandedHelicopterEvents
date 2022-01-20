require "ExpandedHelicopter00a_Util"

eventShadowHandler = {}
storedShadows = {}
storedShadowsUpdateTimes = {}

--eventShadowHandler:setShadowPos(self.ID, self.shadowTexture, currentSquare:getX(),currentSquare:getY(),currentSquare:getX(),currentSquare:getZ())
function eventShadowHandler:setShadowPos(ID, texture, x, y, z, override)
	if not override and isClient() then
		sendClientCommand("eventShadowHandler", "setShadowPos", {ID=ID,texture=texture,x=x,y=y,z=z})
	else
		--print("set Shadow Pos: "..ID.." - "..tostring(texture).." - "..tostring(x)..","..tostring(y)..","..tostring(z))
		if not ID or not x or not y then
			return
		end

		local square
		if x and y then
			square = getSquare(x, y, 0)
		end
		local outsideSquare
		if square then
			outsideSquare = getOutsideSquareFromAbove(square) or square
		end

		if not texture or not x or not y or not z then
			--print("-- clear shadow")
			outsideSquare = nil
		end

		---@type WorldMarkers.GridSquareMarker
		local shadow = storedShadows["HELI"..ID]

		if not shadow and outsideSquare then
			--print("-- no shadow but yes square")
			shadow = getWorldMarkers():addGridSquareMarker(texture, nil, outsideSquare, 0.2, 0.2, 0.2, true, 1, 0, 0.25, 0.25)
		end

		if shadow then

			storedShadowsUpdateTimes["HELI"..ID] = getGametimeTimestamp()

			--print("-- -- yes shadow, square:?")
			if not outsideSquare then
				--print("-- -- -- no square : hide shadow")
				shadow:setAlpha(0)
			else
				--print("-- -- -- yes square : show")
				shadow:setAlpha(0.25)
				shadow:setPosAndSize(outsideSquare:getX(),outsideSquare:getY(),outsideSquare:getZ(), 5)
			end
			storedShadows["HELI"..ID] = shadow
		end
	end
end