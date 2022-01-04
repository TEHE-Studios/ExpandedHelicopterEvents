
eventShadowHandler = {}
eventShadowHandler.storedShadows = {}

--eventShadowHandler:setShadowPos(self.ID, self.shadowTexture, currentSquare:getX(),currentSquare:getY(),currentSquare:getX(),currentSquare:getZ())
function eventShadowHandler:setShadowPos(ID, texture, x, y, z)
	if isClient() then
		sendClientCommand("eventShadowHandler", "setShadowPos", {ID=ID,texture=texture,x=x,y=y,z=z})
	else
		local square = getSquare(x, y, z)
		if square then
			square = getOutsideSquareFromAbove(square) or square
		end

		local shadow = eventShadowHandler.storedShadows["HELI"..ID]

		if not shadow and square then
			shadow = getWorldMarkers():addGridSquareMarker(texture, nil, square, 0.2, 0.2, 0.2, true, 1, 0, 0.25, 0.25)
		end

		if not square then
			if shadow then
				shadow:setAlpha(0)
			end
		else
			shadow:setAlpha(0.25)
			shadow:setPos(square:getX(),square:getY(),square:getZ())
		end
	end
end