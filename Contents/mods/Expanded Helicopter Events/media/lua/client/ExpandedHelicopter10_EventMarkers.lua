--[[ Base code derived from: Sound Direction Indicator -- Nolan Ritchie ]]--

EHE_EventMarker = ISUIElement:derive("EHE_EventMarker")

EHE_EventMarker.iconSize = 96
EHE_EventMarker.clickableSize = 45
EHE_EventMarker.maxRange = 500

function EHE_EventMarker:initialise()
	ISUIElement.initialise(self)
	self:addToUIManager()
	--self.javaObject:setWantKeyEvents(false)
	--self.javaObject:setConsumeMouseEvents(false)
	self.moveWithMouse = true
	self:setVisible(false)
end


function EHE_EventMarker:onMouseUp(x, y)
	if not self.moveWithMouse then
		return
	end
	if not self:getIsVisible() then
		return
	end

	self.moving = false
	if ISMouseDrag.tabPanel then
		ISMouseDrag.tabPanel:onMouseUp(x,y)
	end

	ISMouseDrag.dragView = nil
end

function EHE_EventMarker:onMouseUpOutside(x, y)
	if not self.moveWithMouse then
		return
	end
	if not self:getIsVisible() then
		return
	end

	self.moving = false
	ISMouseDrag.dragView = nil
end

function EHE_EventMarker:onMouseDown(x, y)
	if not self.moveWithMouse then
		return true
	end
	if not self:getIsVisible() then
		return
	end
	if not self:isMouseOver() then
		return -- this happens with setCapture(true)
	end

	self.downX = x
	self.downY = y
	self.moving = true
	self:bringToTop()
end

function EHE_EventMarker:onMouseMoveOutside(dx, dy)
	if not self.moveWithMouse then
		return
	end
	self.mouseOver = false

	if self.moving then

		if self.parent then
			self.parent:setX(self.parent.x + dx)
			self.parent:setY(self.parent.y + dy)
		else
			self:setX(self.x + dx)
			self:setY(self.y + dy)
			self:bringToTop()
		end

		local p = self:getPlayer()
		if p then
			p:getModData()["EHE_markerPlacement"] = {self.x, self.y}
		end
	end
end

function EHE_EventMarker:onMouseMove(dx, dy)
	if not self.moveWithMouse then
		return
	end
	self.mouseOver = true

	if self.moving then

		if self.parent then
			self.parent:setX(self.parent.x + dx)
			self.parent:setY(self.parent.y + dy)
		else
			self:setX(self.x + dx)
			self:setY(self.y + dy)
			self:bringToTop()
		end

		local p = self:getPlayer()
		if p then
			p:getModData()["EHE_markerPlacement"] = {self.x, self.y}
		end
		--ISMouseDrag.dragView = self
	end
end


function EHE_EventMarker:setDistance(dist)
	self.distanceToPoint = dist
end
function EHE_EventMarker:setAngleFromPoint(x,y)
	if(x and y) then
		local radians = math.atan2(y - self.playerObj:getY(), x - self.playerObj:getX()) + math.pi
		local degrees = ((radians * 180 / math.pi + 270) + 45) % 360

		self.angle = degrees
		self.lastpx = x
		self.lastpy = y
	end

end


function EHE_EventMarker:setAngle(value)
	self.angle = value
end

function EHE_EventMarker:setDuration(value)
	self.duration = value
end


function EHE_EventMarker:render()
	if self.visible and self.duration > 0 then--and self.distanceToPoint>4 then
		self.setAngleFromPoint(self.lastpx,self.lastpy)

		local centerX = self.width / 2
		local centerY = self.height / 2

		-- texture, x, y, a, r, g, b
		local Base_r, Base_g, Base_b = math.min(0.78,math.max(0.094,(1-(self.distanceToPoint/self.radius))*0.78)), 0.094, 0.094
		self:drawTexture(self.textureBG, centerX-(EHE_EventMarker.iconSize/2), centerY-(EHE_EventMarker.iconSize/2), 1, Base_r, Base_g, Base_b)

		local textureForPoint = self.texturePoint
		local distanceOverRadius = self.distanceToPoint/self.radius

		if distanceOverRadius <= (8/EHE_EventMarker.maxRange) then
			textureForPoint = self.texturePointClose
		elseif distanceOverRadius <= (125/EHE_EventMarker.maxRange) then
			--no change
		elseif distanceOverRadius <= (375/EHE_EventMarker.maxRange) then
			textureForPoint = self.texturePointMedium
		else
			textureForPoint = self.texturePointFar
		end

		self:DrawTextureAngle(textureForPoint, centerX, centerY, self.angle)

		self:drawTexture(self.textureIcon, centerX-(EHE_EventMarker.iconSize/2), centerY-(EHE_EventMarker.iconSize/2), 1, 1, 1, 1)
		if self.playerObj and getOnlinePlayers():size()>1 then
			self:drawTexture(self.textureCoopNum[self.playerObj:getPlayerNum()+1], centerX-(EHE_EventMarker.iconSize/2), centerY-(EHE_EventMarker.iconSize/2), 1, 1, 1, 1)
		end

		ISUIElement.render(self)
	end
end


function EHE_EventMarker:setEnabled(value)
	self.enabled = value
end

function EHE_EventMarker:prerender()
end

function EHE_EventMarker:refresh()
	self.opacity = 0
	self.opacityGain = 2
end


---@return IsoPlayer | IsoGameCharacter | IsoMovingObject | IsoObject
function EHE_EventMarker:getPlayer()
	return self.playerObj
end


function EHE_EventMarker:new(poi, player, screenX, screenY, width, height, icon, duration)
	local o = {}
	o = ISUIElement:new(screenX, screenY, 1, 1)
	setmetatable(o, self)
	self.__index = self
	o.source = poi
	o.playerObj = player
	o.xoff = screenX
	o.yoff = screenY
	o.lastpx = 0
	o.lastpy = 0
	o.width = width
	o.height = height
	o.angle = 0
	o.opacity = 255
	o.opacityGain = 2
	o.duration = duration
	o.enabled = true
	o.visible = true
	o.title = ""
	o.distanceToPoint = EHE_EventMarker.maxRange
	o.radius = nil
	o.mouseOver = false
	o.tooltip = nil
	o.center = false
	o.bConsumeMouseEvents = false
	o.joypadFocused = false
	o.translation = nil
	o.texturePoint = getTexture("media/ui/eventMarker.png")
	o.texturePointClose = getTexture("media/ui/eventMarker_close.png")
	o.texturePointMedium = getTexture("media/ui/eventMarker_medium.png")
	o.texturePointFar = getTexture("media/ui/eventMarker_far.png")
	o.textureBG = getTexture("media/ui/eventMarkerBase.png")
	o.textureCoopNum = {
		getTexture("media/ui/coop1.png"),
		getTexture("media/ui/coop2.png"),
		getTexture("media/ui/coop3.png"),
		getTexture("media/ui/coop4.png")}
	if icon then
		o.textureIcon = getTexture(icon)
	end

	o:initialise()
	return o
end


---@param playerIndex number
function EHE_EventMarker:update(playerIndex)
	if not playerIndex then
		return
	end

	---@type IsoObject | IsoMovingObject | IsoGameCharacter | IsoPlayer
	local player = getSpecificPlayer(playerIndex)

	if not player then
		return
	end

	if self.duration > 0 then
		self.duration = self.duration-1
		--if instanceof(poi, "BaseVehicle") then print("EHE:DEBUG: Duration-1 = "..self.duration) end
		if(self.duration <= 0) then
			self:setVisible(false)
			return
		end
	end

	local dist
	local poi = self.source
	local x,y,z

	if not self.radius then
		self.radius = EHE_EventMarker.maxRange
	end

	if (not instanceof(poi, "BaseVehicle")) and (not instanceof(poi, "IsoGridSquare")) then
		dist=poi:getDistanceToIsoObject(player)
		x,y,z = poi:getXYZAsInt()
	else
		x,y,z = poi:getX(), poi:getY(), poi:getZ()
		dist=IsoUtils.DistanceTo(x,y,player:getX(),player:getY())
	end

	if(player:HasTrait("EagleEyed")) then self.radius = (self.radius * 1.2)
	elseif(player:HasTrait("ShortSighted")) then self.radius = (self.radius * 0.8) end

	local HOUR = getGameTime():getHour()
	if player:HasTrait("NightVision") and HOUR < 6 and HOUR > 22 then
		self.radius = self.radius*1.2
	end

	if (dist <= self.radius) then--and player:isOutside() then
		self:setDistance(dist)
		self:setAngleFromPoint(x,y)
		--self:setDuration(10)
		self:setVisible(true)
	else
		self:setVisible(false)
	end
end
