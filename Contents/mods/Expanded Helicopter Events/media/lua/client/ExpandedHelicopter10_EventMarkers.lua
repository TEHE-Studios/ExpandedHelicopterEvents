require "ISUI/ISUIElement"
require "ExpandedHelicopter00a_Util"

--[[ Base code derived from: Sound Direction Indicator -- Nolan Ritchie ]]--

EHE_EventMarker = ISUIElement:derive("EHE_EventMarker")

EHE_EventMarker.iconSize = 96
EHE_EventMarker.clickableSize = 45
EHE_EventMarker.maxRange = 500

function EHE_EventMarker:initialise()
	ISUIElement.initialise(self)
	self:addToUIManager()
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
			p:getModData()["EHE_eventMarkerPlacement"] = {self.x, self.y}
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
			p:getModData()["EHE_eventMarkerPlacement"] = {self.x, self.y}
		end
	end
end


function EHE_EventMarker:setDistance(dist)
	self.distanceToPoint = dist
end
function EHE_EventMarker:setAngleFromPoint(posX,posY)
	if(posX and posY) then
		local radians = math.atan2(posY - self.player:getY(), posX - self.player:getX()) + math.pi
		local degrees = ((radians * 180 / math.pi + 270) + 45) % 360

		self.angle = degrees
		self.posY = posX
		self.posY = posY
	end

end


function EHE_EventMarker:setAngle(value)
	self.angle = value
end

function EHE_EventMarker:setDuration(value)
	self.duration = value
	if value <= 0 then
		self:setVisible(false)
	end
end


function EHE_EventMarker:render()
	if self.visible and self.duration > 0 then--and self.distanceToPoint>4 then
		self.setAngleFromPoint(self.posX,self.posY)

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

		if self.player and getNumActivePlayers()>1 then
			self:drawTexture(self.textureCoopNum[self.player:getPlayerNum()+1], centerX-(EHE_EventMarker.iconSize/2), centerY-(EHE_EventMarker.iconSize/2), 1, 1, 1, 1)
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
	return self.player
end


function EHE_EventMarker:new(eventID, icon, duration, posX, posY, player, screenX, screenY)
	print(" --- marker new: eventID:"..eventID..": tex:"..icon.." d:"..duration.." x/y:"..posX..","..posY.." "..tostring(player).." screen:"..screenX..","..screenY)
	local o = {}
	o = ISUIElement:new(screenX, screenY, 1, 1)
	setmetatable(o, self)
	self.__index = self
	o.eventID = eventID
	o.player = player
	o.x = screenX
	o.y = screenY
	o.posX = posX or 0
	o.posY = posY or 0
	o.width = EHE_EventMarker.clickableSize
	o.height = EHE_EventMarker.clickableSize
	o.angle = 0
	o.opacity = 255
	o.opacityGain = 2
	o.duration = duration
	o.lastUpdateTime = -1
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


function EHE_EventMarker:update(posX,posY)

	local timeStamp = getTimeInMillis()
	if (self.lastUpdateTime+5 >= timeStamp) then
		return
	else
		self.lastUpdateTime = timeStamp
	end

	--print(" ---- marker "..self.eventID.." update")
	local dist
	posX = posX or self.posX
	posY = posY or self.posY

	if posX and posY and self.player then
		dist = IsoUtils.DistanceTo(posX, posY, self.player:getX(), self.player:getY())
		--print(" ----- marker:"..self.eventID.." x("..x..") y("..y..") and player("..tostring(self.player)..") found : attempting to set dist("..dist..")")
	end

	if not self.radius then
		self.radius = EHE_EventMarker.maxRange*0.83
	end

	if(self.player:HasTrait("EagleEyed")) then self.radius = (self.radius * 1.2)
	elseif(self.player:HasTrait("ShortSighted")) then self.radius = (self.radius * 0.8) end

	local HOUR = getGameTime():getHour()
	if HOUR < 6 and HOUR > 22 then
		if self.player:HasTrait("NightVision") then
			self.radius = self.radius*1.1
		else
			self.radius = self.radius*0.75
		end
	end

	self.radius = math.max(EHE_EventMarker.maxRange/3, math.min(self.radius,EHE_EventMarker.maxRange))

	if self.duration > 0 then--and player:isOutside() then
		--print(" ----- marker:"..self.eventID.." x("..posX..") y("..posY..") and dist("..tostring(dist)..") found : attempting to compare to radius("..self.radius..")")
		self.posX = posX
		self.posY = posY
		if dist and (dist <= self.radius) then
			--print(" ------ marker "..self.eventID.." in range - visible")
			self:setDistance(dist)
			self:setAngleFromPoint(self.posX,self.posY)
			self:setVisible(true)
		else
			self:setVisible(false)
		end
	else
		--print(" ------ hiding marker "..self.eventID)
		self:setVisible(false)
	end
end
