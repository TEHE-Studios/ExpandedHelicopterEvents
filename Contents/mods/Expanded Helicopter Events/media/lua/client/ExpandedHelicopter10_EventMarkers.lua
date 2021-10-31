--[[ Base code derived from: Sound Direction Indicator -- Nolan Ritchie ]]--

EHE_EventMarker = ISUIElement:derive("EHE_EventMarker")

EHE_EventMarker.iconSize = 75

function EHE_EventMarker:initialise()
	ISUIElement.initialise(self)
	self:addToUIManager()
	--self.javaObject:setWantKeyEvents(false)
	--self.javaObject:setConsumeMouseEvents(false)
	self.moveWithMouse = true
	self:setVisible(false)
end


function EHE_EventMarker:onMouseUp(x, y)
	if not self.moveWithMouse then return; end
	if not self:getIsVisible() then
		return;
	end

	self.moving = false;
	if ISMouseDrag.tabPanel then
		ISMouseDrag.tabPanel:onMouseUp(x,y);
	end

	ISMouseDrag.dragView = nil;
end

function EHE_EventMarker:onMouseUpOutside(x, y)
	if not self.moveWithMouse then return; end
	if not self:getIsVisible() then
		return;
	end

	self.moving = false;
	ISMouseDrag.dragView = nil;
end

function EHE_EventMarker:onMouseDown(x, y)
	if not self.moveWithMouse then return true; end
	if not self:getIsVisible() then
		return;
	end
	if not self:isMouseOver() then
		return -- this happens with setCapture(true)
	end

	self.downX = x;
	self.downY = y;
	self.moving = true;
	self:bringToTop();
end

function EHE_EventMarker:onMouseMoveOutside(dx, dy)
	if not self.moveWithMouse then return; end
	self.mouseOver = false;

	if self.moving then
		if self.parent then
			self.parent:setX(self.parent.x + dx);
			self.parent:setY(self.parent.y + dy);
		else
			self:setX(self.x + dx);
			self:setY(self.y + dy);
			self:bringToTop();
		end
	end
end

function EHE_EventMarker:onMouseMove(dx, dy)
	if not self.moveWithMouse then return; end
	self.mouseOver = true;

	if self.moving then
		if self.parent then
			self.parent:setX(self.parent.x + dx);
			self.parent:setY(self.parent.y + dy);
		else
			self:setX(self.x + dx);
			self:setY(self.y + dy);
			self:bringToTop();
		end
		--ISMouseDrag.dragView = self;
	end
end


function EHE_EventMarker:setDistance(dist)
	self.distanceToPoint = dist
end
function EHE_EventMarker:setAngleFromPoint(x,y)
	if(x and y) then
		local radians = math.atan2(y - self.playerObj:getY(), x - self.playerObj:getX()) + math.pi
		local degrees = ((radians * 180 / math.pi + 270) + 45) % 360 -- add 45 deg because of the isometric view? or idk for some reason i need to

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
	self.flashTicks = 0
	self.flashingOn = true
end


function EHE_EventMarker:render()
	if self.visible then
		self.setAngleFromPoint(self.lastpx,self.lastpy)

		local centerX = self.width / 2
		local centerY = self.height / 2
		local flashBaseline = (self.distanceToPoint * 3)

		if((self.flashingOn) and (self.flashTicks < (flashBaseline))) then
			-- texture, x, y, a, r, g, b
			local Base_r, Base_g, Base_b = math.min(0.78,math.max(0.094,(1-(self.distanceToPoint/self.radius))*0.78)), 0.094, 0.094
			self:drawTexture(self.textureBG, centerX-(EHE_EventMarker.iconSize/2), centerY-(EHE_EventMarker.iconSize/2), 1, Base_r, Base_g, Base_b)

			self:DrawTextureAngle(self.texturePoint, centerX, centerY, self.angle)
			self:drawTexture(self.textureIcon, centerX-(EHE_EventMarker.iconSize/2), centerY-(EHE_EventMarker.iconSize/2), 1, 1, 1, 1)
			ISUIElement.render(self)
			self.flashTicks = self.flashTicks + 1
		elseif((not self.flashingOn) and (self.flashTicks < (flashBaseline))) then
			self.flashTicks = self.flashTicks + 1
		else
			self.flashTicks = 0
			self.flashingOn = not self.flashingOn
			if(not self.flashingOn) then self.flashTicks = (flashBaseline/2) end -- flash off time half as long as flash on
		end
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

function EHE_EventMarker:getPlayer()
	return self.playerObj
end


function EHE_EventMarker:new(poi, player, x, y, width, height, icon, duration, title)
	local o = {}
	o = ISUIElement:new(x, y, 1, 1)
	setmetatable(o, self)
	self.__index = self
	o.source = poi
	o.playerObj = player
	o.xoff = x
	o.yoff = y
	o.lastpx = 0
	o.lastpy = 0
	o.flashTicks = 0
	o.flashingOn = true
	o.width = width
	o.height = height
	o.angle = 0
	o.opacity = 255
	o.opacityGain = 2
	o.duration = duration
	o.enabled = true
	o.visible = true
	o.title = title or ""
	o.distanceToPoint = 999
	o.radius = nil
	o.mouseOver = false
	o.tooltip = nil
	o.center = false
	o.bConsumeMouseEvents = false
	o.joypadFocused = false
	o.translation = nil
	o.texturePoint = getTexture("media/ui/eventMarker.png")
	o.textureBG = getTexture("media/ui/eventMarkerBase.png")
	if icon then
		o.textureIcon = getTexture(icon)
	end

	o:initialise()
	return o
end


---@param poi IsoObject | IsoMovingObject | eHelicopter
---@param player IsoObject | IsoMovingObject | IsoGameCharacter | IsoPlayer
function EHE_EventMarker:update(poi,player)

	if not poi or not player then
		return
	end

	if self.duration > 0 then
		self.duration = self.duration - 1
		if(self.duration <= 0) then
			self:setVisible(false)
			return
		end
	end

	local dist
	local x,y,z

	if not self.radius then
		self.radius = 1000
	end

	if poi.getDistanceToIsoObject then
		dist=poi:getDistanceToIsoObject(player)
		self.radius=(poi.flightVolume*5)+1
		x,y,z = poi:getXYZAsInt()
	else
		dist=poi:getDistanceSq(player)
		x,y,z = poi:getX(), poi:getY(), poi:getZ()
	end

	if(player:HasTrait("EagleEyed")) then self.radius = (self.radius * 1.2)
	elseif(player:HasTrait("ShortSighted")) then self.radius = (self.radius * 0.8) end

	local HOUR = getGameTime():getHour()
	if player:HasTrait("NightVision") and HOUR < 6 and HOUR > 22 then
		self.radius = self.radius*1.2
	end

	if((dist <= self.radius) and player:isOutside()) then
		self:setDistance(dist)
		self:setAngleFromPoint(x,y)
		self:setDuration(10)
		self:setVisible(true)
	end
end


EHE_EventMarkerHandler = {}
EHE_EventMarkerHandler.allPOI = {}

---@param player IsoObject | IsoMovingObject | IsoGameCharacter | IsoPlayer
function EHE_EventMarkerHandler.generateNewMarker(poi, player, icon, duration)
	if(player) then
		local SX = (getCore():getScreenWidth()/2) - (EHE_EventMarker.iconSize/2)
		local SY = (EHE_EventMarker.iconSize/2)
		local newMarker = EHE_EventMarker:new(poi, player, SX, SY,EHE_EventMarker.iconSize, EHE_EventMarker.iconSize, icon, duration)
		return newMarker
	end
end


function EHE_EventMarkerHandler.setOrUpdateMarkers(poi, icon, duration)

	if eHelicopterSandbox.config.eventMarkersOn == false then
		return
	end
	
	for playerIndex=0, getNumActivePlayers()-1 do
		local p = getSpecificPlayer(playerIndex)

		local POI = EHE_EventMarkerHandler.allPOI[poi]

		if not POI then
			EHE_EventMarkerHandler.allPOI[poi] = {markers={}}
			POI = EHE_EventMarkerHandler.allPOI[poi]
		end

		local marker = POI.markers[p]

		if not marker then
			POI.markers[p] = EHE_EventMarkerHandler.generateNewMarker(poi, p, icon, duration)
			--print("EHE:DEBUG: #"..poi.ID.." no marker found.")
		end
	end
end

function EHE_EventMarkerHandler.disableMarkersForPOI(poi)
	local POI = EHE_EventMarkerHandler.allPOI[poi]
	if POI then
		for player,marker in pairs(POI.markers) do
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
		for player,marker in pairs(poiData.markers) do
			marker:update(poiObject,player)
		end
	end
end

Events.OnTick.Add(EHE_EventMarkerHandler.updateAll)

