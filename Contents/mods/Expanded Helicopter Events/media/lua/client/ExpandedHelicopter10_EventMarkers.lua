--[[ Base code derived from: Sound Direction Indicator -- Nolan Ritchie ]]--

EHE_EventMarkers = ISUIElement:derive("EHE_EventMarkers")

function EHE_EventMarkers:initialise()
	ISUIElement.initialise(self)
	self:addToUIManager()
	self.javaObject:setWantKeyEvents(false)
	self.javaObject:setConsumeMouseEvents(false)
	self:setVisible(false)
end

---need these mouse functions to return false to prevent interfering with aiming and context menu click attempts on the UIElement
function EHE_EventMarkers:onMouseMove(d) return false end
function EHE_EventMarkers:onMouseUp(d) return false end
function EHE_EventMarkers:onRightMouseUp(d) return false end
function EHE_EventMarkers:onMouseDown(d) return false end
function EHE_EventMarkers:onRightMouseDown(d) return false end
function EHE_EventMarkers:onRightMouseDownOutside(d) return false end
function EHE_EventMarkers:onRightMouseUpOutside(d) return false end


function EHE_EventMarkers:setDistance(dist)
	self.distancetoPoint = dist
end
function EHE_EventMarkers:setAngleFromPoint(x,y)
	if(x and y) then
		local radians = math.atan2(y - self.playerObj:getY(), x - self.playerObj:getX()) + math.pi
		local degrees = ((radians * 180 / math.pi + 270) + 45) % 360 -- add 45 deg because of the isometric view? or idk for some reason i need to

		self.angle = degrees
		self.lastpx = x
		self.lastpy = y
	end

end


function EHE_EventMarkers:setAngle(value)
	self.angle = value
end

function EHE_EventMarkers:setDuration(value)
	self.duration = value
	self.flashticks = 0
	self.flashingon = true
end


function EHE_EventMarkers:render()

	if((self.visible) and (self.duration > 0)) then

		self.setAngleFromPoint(self.lastpx,self.lastpy)

		local centerX = self.width / 2
		local centerY = self.height / 2

		local flashbaseline = (self.distancetoPoint * 3)
		local texturetoUse = self.texturePoint

		---TODO: color via code perchance?
		--[[
		if(self.distancetoPoint <= 1) then
			texturetoUse = self.texSameSquare
		elseif(self.distancetoPoint <= 4) then
			texturetoUse = self.texRed
		elseif (self.distancetoPoint <= 9) then
			texturetoUse = self.texOrange
		elseif (self.distancetoPoint <= 14) then
			texturetoUse = self.texYellow
		end
		]]

		if((self.flashingon) and (self.flashticks < (flashbaseline))) then
			self:DrawTextureAngle(texturetoUse, centerX, centerY, self.angle)
			ISUIElement.render(self)
			self.flashticks = self.flashticks + 1
		elseif((not self.flashingon) and (self.flashticks < (flashbaseline))) then
			self.flashticks = self.flashticks + 1
		else
			self.flashticks = 0
			self.flashingon = not self.flashingon
			if(not self.flashingon) then self.flashticks = (flashbaseline/2) end -- flash off time half as long as flash on

		end

		self.duration = self.duration - 1
		if(self.duration == 0) then self:setVisible(false) end
	end

end


function EHE_EventMarkers:setEnabled(value)
	self.enabled = value
end

function EHE_EventMarkers:prerender()
end

function EHE_EventMarkers:refresh()
	self.opacity = 0
	self.opacityGain = 2
end

function EHE_EventMarkers:getPlayer()
	return self.playerObj
end


function EHE_EventMarkers:new(heli, player, x, y, width, height, title)
	local o = {}
	o = ISUIElement:new(x, y, 1, 1)
	setmetatable(o, self)
	self.__index = self
	o.SoundSource = heli
	o.playerObj = player
	o.xoff = x
	o.yoff = y
	o.lastpx = 0
	o.SoundSource = nil
	o.lastpy = 0
	o.flashticks = 0
	o.flashingon = true
	o.width = width
	o.height = height
	o.angle = 0
	o.opacity = 255
	o.opacityGain = 2
	o.duration = 0
	o.enabled = true
	o.visible = true
	o.title = title
	o.distancetoPoint = 999
	o.mouseOver = false
	o.tooltip = nil
	o.center = false
	o.bConsumeMouseEvents = false
	o.joypadFocused = false
	o.translation = nil
	o.texturePoint = getTexture("media/ui/eventMarker.png")

	return o
end


function EHE_EventMarkers:update(heli,player)

	if not heli or not player then
		return
	end

	local dist = heli:getDistanceToIsoObject(player)
	local radius = (heli.flightVolume*2)+1
	local x,y,z = heli:getXYZAsInt()

	if(player:HasTrait("Deaf")) then radius = 0
	elseif(player:HasTrait("KeenHearing")) then radius = (radius * 1.2)
	elseif(player:HasTrait("HardOfHearing")) then radius = (radius * 0.8) end

	if( dist < (radius)) then
		self:setDistance(dist)
		self:setAngleFromPoint(x,y)
		self:setDuration(30)
		self:setVisible(true)
	end
end

-------------STATIC-FUNCS------------------

---@param player IsoObject | IsoMovingObject | IsoGameCharacter | IsoPlayer
function eHelicopter:generateNewMarker(player)
	if(player) then
		local SY = 0 - (64+35)
		local SX = (getCore():getScreenWidth()/2) - 35

		local newMarker = EHE_EventMarkers:new(self,player,SX, SY,165, 165, "")
		self.markers[player] = newMarker
		newMarker:initialise()
		print("Sound Direction Indicator initialised")
		return newMarker
	else
		print("EHE: ERR: could not initialise Sound Direction Indicator: `player` was nil")
	end
end


function eHelicopter:updateMarkers()
	for playerIndex=0, getNumActivePlayers()-1 do
		local p = getSpecificPlayer(playerIndex)
		local marker = self.markers[p]

		if not marker then
			marker = self:generateNewMarker(p)
		end

		if p and marker then
			marker:update(self,p)
		end
		--marker:render()
	end
end



