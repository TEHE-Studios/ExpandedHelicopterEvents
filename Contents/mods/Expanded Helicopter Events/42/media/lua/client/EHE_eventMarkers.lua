require "ISUI/ISUIElement"
require "EHE_util"


EHE_EventMarker = ISUIElement:derive("EHE_EventMarker")

EHE_EventMarker.iconSize = 96
EHE_EventMarker.clickableSize = 45
EHE_EventMarker.maxRange = (eheBounds.threshold * 0.75)

EHE_EventMarker.textureIsoPointer = getTexture("media/ui/eventPointer.png")
EHE_EventMarker.textureBG = getTexture("media/ui/eventPointerBase.png")

EHE_EventMarker.textureCoopNum = {
	getTexture("media/ui/coop1.png"),
	getTexture("media/ui/coop2.png"),
	getTexture("media/ui/coop3.png"),
	getTexture("media/ui/coop4.png")}

function EHE_EventMarker:initialise()
	ISUIElement.initialise(self)
	self:addToUIManager()
	self.moveWithMouse = true
	self:setVisible(false)
end


function EHE_EventMarker:onMouseDoubleClick(x, y)
	--[[DEBUG]] if getDebug() then print("EHE: "..self.eventID) end
	return self:setDuration(0)
end


function EHE_EventMarker:onMouseUp(x, y)
	if not self.moveWithMouse then return end
	if not self:getIsVisible() then return end

	self.moving = false
	if ISMouseDrag.tabPanel then ISMouseDrag.tabPanel:onMouseUp(x,y) end

	ISMouseDrag.dragView = nil
end


function EHE_EventMarker:onMouseUpOutside(x, y)
	if not self.moveWithMouse then return end
	if not self:getIsVisible() then return end
	self.moving = false
	ISMouseDrag.dragView = nil
end


function EHE_EventMarker:onMouseDown(x, y)
	if not self.moveWithMouse then return true end
	if not self:getIsVisible() then return end
	if not self:isMouseOver() then return end

	self.downX = x
	self.downY = y
	self.moving = true
	self:bringToTop()
end


function EHE_EventMarker:onMouseMoveOutside(dx, dy)
	if not self.moveWithMouse then return end
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
		if p then p:getModData()["EHE_eventMarkerPlacement"] = {self.x, self.y} end
	end
end


function EHE_EventMarker:onMouseMove(dx, dy)
	if not self.moveWithMouse then return end
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
		if p then p:getModData()["EHE_eventMarkerPlacement"] = {self.x, self.y} end
	end
end


function EHE_EventMarker:setDistance(dist) self.distanceToPoint = dist end


function EHE_EventMarker:setDuration(value)
	self.duration = value
	if value <= 0 then self:setVisible(false) end
end


function EHE_EventMarker:getDuration() return self.duration end


local function colorBlend(color, underLayer, fade)

	local fadedColor = {r=color.r*fade, g=color.g*fade, b=color.b*fade, a=fade}
	local _color = {r=1, g=1, b=1, a=1}
	local alphaShift = 1 - (1 - fadedColor.a) * (1 - underLayer.a)

	_color.r = fadedColor.r * fadedColor.r / alphaShift + underLayer.r * underLayer.a * (1 - fadedColor.a) / alphaShift
	_color.g = fadedColor.g * fadedColor.g / alphaShift + underLayer.g * underLayer.a * (1 - fadedColor.a) / alphaShift
	_color.b = fadedColor.b * fadedColor.b / alphaShift + underLayer.b * underLayer.a * (1 - fadedColor.a) / alphaShift

	return _color
end


function EHE_EventMarker:setAngleFromPoint(posX, posY)
	if posX and posY and self.player then
		local px, py = self.player:getX(), self.player:getY()
		local dx, dy = posX - px, posY - py

		--- isometric projection
		local screen_dx = (dx - dy) * 0.5
		local screen_dy = (dx + dy) * 0.25

		local radians = math.atan2(screen_dy, screen_dx)
		local degrees = (math.deg(radians) + 360) % 360
		self.angle = degrees
	end
end


function EHE_EventMarker:calcPointer(offset, angle, stretch, tex, centerX, centerY)

	local width = tex:getWidth() * stretch
	local height = tex:getHeight()

	local hw = width / 2
	local hh = height / 2

	local cosA = math.cos(angle)
	local sinA = math.sin(angle)

	local offsetX = math.cos(angle) * offset
	local offsetY = math.sin(angle) * offset

	local cx = self.x + centerX + offsetX
	local cy = self.y + centerY + offsetY

	local x1 = cx - cosA * hw + sinA * hh
	local y1 = cy - sinA * hw - cosA * hh

	local x2 = cx + cosA * hw + sinA * hh
	local y2 = cy + sinA * hw - cosA * hh

	local x3 = cx + cosA * hw - sinA * hh
	local y3 = cy + sinA * hw + cosA * hh

	local x4 = cx - cosA * hw - sinA * hh
	local y4 = cy - sinA * hw + cosA * hh

	return x1, y1, x2, y2, x3, y3, x4, y4
end


function EHE_EventMarker:render()
	if self.visible and self.duration > 0 then--and self.distanceToPoint>4 then
		self.setAngleFromPoint(self.posX,self.posY)

		local centerX = self.width / 2
		local centerY = self.height / 2

		local aFromDist = 0.2 + (0.8*(1-(self.distanceToPoint/self.radius)))
		local mColor = {r=self.markerColor.r, g=self.markerColor.g, b=self.markerColor.b, a=1}
		local base = {r=0.44, g=0.44, b=0.44, a=1}

		local _color = colorBlend(mColor, base, aFromDist)

		self:drawTexture(self.textureBG, centerX-(EHE_EventMarker.iconSize/2), centerY-(EHE_EventMarker.iconSize/2), 1, _color.r, _color.g, _color.b)

		local tex = self.textureIsoPointer
		if tex then
			local angle = math.rad(self.angle or 0)
			local distFraction = math.min(1, self.distanceToPoint / self.radius)

			local stretch = 0.1 + (1.2 * distFraction)

			local offset = 24 + (8 * (distFraction*2))
			local x1, y1, x2, y2, x3, y3, x4, y4 = self:calcPointer(offset, angle, stretch, tex, centerX, centerY)

			local _offset = 29 + (8 * (distFraction*2))
			local _x1, _y1, _x2, _y2, _x3, _y3, _x4, _y4 = self:calcPointer(_offset, angle, stretch*(1+(distFraction/3)), tex, centerX, centerY)
			---deeper call from renderer allows for skewing/stretching/rotating
			getRenderer():render(tex, x1, y1, _x2, _y2, _x3, _y3, x4, y4, 1, 1, 1, 1, nil)

			---deeper call from renderer allows for skewing/stretching/rotating
			getRenderer():render(tex, x1, y1, x2, y2, x3, y3, x4, y4, _color.r, _color.g, _color.b, 1, nil)
		end

		self:drawTexture(self.textureIcon, centerX-(EHE_EventMarker.iconSize/2), centerY-(EHE_EventMarker.iconSize/2), 1, 1, 1, 1)

		if self.player and getNumActivePlayers()>1 then
			self:drawTexture(self.textureCoopNum[self.player:getPlayerNum()+1], centerX-(EHE_EventMarker.iconSize/2), centerY-(EHE_EventMarker.iconSize/2), 1, 1, 1, 1)
		end

		ISUIElement.render(self)
	end
end


function EHE_EventMarker:setEnabled(value) self.enabled = value end
function EHE_EventMarker:getEnabled() return self.enabled end

function EHE_EventMarker:refresh()
	self.opacity = 0
	self.opacityGain = 2
end


---@return IsoPlayer | IsoGameCharacter | IsoMovingObject | IsoObject
function EHE_EventMarker:getPlayer() return self.player end


function EHE_EventMarker:new(eventID, icon, duration, posX, posY, player, screenX, screenY, color, shadow)

	local o = {}
	o = ISUIElement:new(screenX, screenY, 1, 1)
	setmetatable(o, self)
	self.__index = self
	o.eventID = eventID
	o.player = player
	o.x = screenX
	o.y = screenY
	o.markerColor = color or {r=1,g=1,b=1}
	o.shadow = shadow and getTexture("media/textures/highlights/"..shadow..".png") or getTexture("media/textures/highlights/helicopter_shadow.png")
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
	o.textureIcon = icon and getTexture(icon)
	o:initialise()
	return o
end


function EHE_EventMarker:update(posX,posY)
	if not self.enabled then return end

	local timeStamp = getTimeInMillis()
	if (self.lastUpdateTime+5 >= timeStamp) then
		return
	else
		self.lastUpdateTime = timeStamp
	end

	local dist
	posX = posX or self.posX
	posY = posY or self.posY

	if posX and posY and self.player then
		dist = IsoUtils.DistanceTo(posX, posY, self.player:getX(), self.player:getY())
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

	if not self.player:isOutside() then
		self.radius = self.radius*0.33
	end

	self.radius = math.max(EHE_EventMarker.maxRange/3, math.min(self.radius,EHE_EventMarker.maxRange))

	if self.duration > 0 then
		self.posX = posX
		self.posY = posY
		if dist and (dist <= self.radius) then
			self:setDistance(dist)
			self:setAngleFromPoint(self.posX,self.posY)
			self:setVisible(true)
		else
			self:setVisible(false)
		end
	else
		self:setVisible(false)
	end
end
