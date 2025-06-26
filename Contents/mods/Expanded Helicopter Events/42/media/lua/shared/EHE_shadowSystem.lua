require "EHE_util"

eventShadowHandler = {}
storedShadows = {}
storedShadowsUpdateTimes = {}
--eventShadowHandler:setShadowPos(self.ID, self.shadowTexture, currentSquare:getX(),currentSquare:getY(),currentSquare:getX(),currentSquare:getZ())

function eventShadowHandler:setShadowPos(ID, texture, x, y, z)
	if isServer() then
		sendServerCommand("eventShadowHandler", "setShadowPos", {ID=ID,texture=texture,x=x,y=y,z=z})
		return
	end

	if not ID or not x or not y or not z or not texture then return end

	if not getSquare(x, y, 0) then return end

	local shadow = storedShadows["HELI"..ID]
	if not shadow then
		storedShadows["HELI"..ID] = getTexture("media/textures/highlights/"..texture..".png")
		shadow = storedShadows["HELI"..ID]
		print("texture: ", texture, "  shadow:", shadow)
	end

	storedShadowsUpdateTimes["HELI"..ID] = getTimeInMillis()

	local w, h = 10, 10
	local halfW, halfH = w / 2, h / 2

	local x1, y1 = x - halfW, y - halfH
	local x2, y2 = x + halfW, y - halfH
	local x3, y3 = x + halfW, y + halfH
	local x4, y4 = x - halfW, y + halfH

	local sx1, sy1 = ISCoordConversion.ToScreen(x1, y1, z)
	local sx2, sy2 = ISCoordConversion.ToScreen(x2, y2, z)
	local sx3, sy3 = ISCoordConversion.ToScreen(x3, y3, z)
	local sx4, sy4 = ISCoordConversion.ToScreen(x4, y4, z)

	print("screen:",getPlayerScreenWidth(0))
	print("-cords:",sx1,",", sy1,",", sx2,",", sy2,",", sx3,",", sy3,",", sx4,",", sy4)

	getRenderer():render(shadow, 250, 250, 350, 350, 450, 450, 550, 550, 1 , 1, 1, 1, nil)

	getRenderer():render(shadow, sx1/2, sy1/2, sx2/2, sy2/2, sx3/2, sy3/2, sx4/2, sy4/2, 1.0, 1.0, 1.0, 0.8, nil)
end