require "EHE_util"

eventShadowHandler = {}
eventShadowHandler.storedShadows = {}

function eventShadowHandler:setShadowPos(ID, texture, x, y, z)
	if not ID or not texture then return end
	z=0
	if isServer() then
		sendServerCommand("eventShadowHandler", "setShadowPos", {ID=ID,texture=texture,x=x,y=y,z=z})
		return
	end

	local shadow = eventShadowHandler.storedShadows["HELI"..ID]
	if not shadow then
		print("made new shadow for: ", "HELI"..ID)
		eventShadowHandler.storedShadows["HELI"..ID] = { texture = getTexture("media/textures/highlights/"..texture..".png") }
	end
	eventShadowHandler.storedShadows["HELI"..ID].x = x
	eventShadowHandler.storedShadows["HELI"..ID].y = y
	eventShadowHandler.storedShadows["HELI"..ID].z = z
	eventShadowHandler.storedShadows["HELI"..ID].updateTime = getTimeInMillis()
end


function eventShadowHandler.render(ID)

	local shadow = eventShadowHandler.storedShadows[ID]
	if not shadow then return end

	local x, y , z = shadow.x, shadow.y, shadow.z
	local texture = shadow.texture

	if not getSquare(x, y, 0) then return end

	local zoom = getCore():getZoom(0)

	local w, h = 9, 9
	local halfW, halfH = w / 2, h / 2

	local x1, y1 = x - halfW, y - halfH
	local x2, y2 = x + halfW, y - halfH
	local x3, y3 = x + halfW, y + halfH
	local x4, y4 = x - halfW, y + halfH

	local sx1, sy1 = ISCoordConversion.ToScreen(x1, y1, z)
	local sx2, sy2 = ISCoordConversion.ToScreen(x2, y2, z)
	local sx3, sy3 = ISCoordConversion.ToScreen(x3, y3, z)
	local sx4, sy4 = ISCoordConversion.ToScreen(x4, y4, z)

	getRenderer():renderPoly(texture, sx1/zoom, sy1/zoom, sx2/zoom, sy2/zoom, sx3/zoom, sy3/zoom, sx4/zoom, sy4/zoom, 1, 1, 1, 0.6)

	if getDebug() then
		local tx1, ty1 = ISCoordConversion.ToScreen(x - w / 2, y - h / 2, z)
		getRenderer():renderRect(tx1/zoom, ty1/zoom, w/zoom, h/zoom, 1, 0, 0, 1)
	end
end