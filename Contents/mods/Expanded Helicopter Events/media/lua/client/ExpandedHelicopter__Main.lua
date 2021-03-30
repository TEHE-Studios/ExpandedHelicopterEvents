---@class eHelicopter
---@field preflightDistance number
---@field target IsoObject
---@field targetPosition Vector3 @Vector3 "position" of target
---@field state boolean
---@field lastMovement Vector3 @consider this to be velocity (direction/angle and speed/stepsize)
---@field currentPosition Vector3 @consider this a pair of coordinates
---@field speed number
---@field emitter FMODSoundEmitter | BaseSoundEmitter
---@field ID number
---@field lastAnnouncedTime number
---@field announcerVoice string

eHelicopter = {}
eHelicopter.preflightDistance = nil
eHelicopter.target = nil
eHelicopter.targetPosition = Vector3.new()
eHelicopter.lastMovement = Vector3.new()
eHelicopter.currentPosition = Vector3.new()
eHelicopter.state = nil
eHelicopter.speed = 0.75
eHelicopter.height = 20
eHelicopter.ID = 0
eHelicopter.lastAnnouncedTime = nil
eHelicopter.announcerVoice = nil

function eHelicopter:new()

	local o = {}
	setmetatable(o, self)
	self.__index = self
	return o
end

--Global Vars
MAX_XY = 15000
MIN_XY = 2500
ALL_HELICOPTERS = {}


---These is the equivalent of getters for Vector3
--tostring output of a Vector3: "Vector2 (X: %f, Y: %f) (L: %f, D:%f)"
---@param ShmectorTree Vector3
---@return float x of ShmectorTree
function Vector3GetX(ShmectorTree)
	return string.match(tostring(ShmectorTree), "%(X%: (.-)%, Y%: ")
end


---@param ShmectorTree Vector3
---@return float y of ShmectorTree
function Vector3GetY(ShmectorTree)
	return string.match(tostring(ShmectorTree), "%, Y%: (.-)%) %(")
end


---Initialize Position
---@param targetedPlayer IsoMovingObject | IsoPlayer | IsoGameCharacter
---@param ignoreEdgePriority boolean Do not select the closer edge for flight paths.
function eHelicopter:initPos(targetedPlayer,ignoreEdgePriority)

	--player's location
	local tpX = targetedPlayer:getX()
	local tpY = targetedPlayer:getY()

	--assign a random spawn point for the helicopter within a radius from the player
	--these values are being clamped to not go passed MIN_XY/MAX edges
	local offset = 500
	local initX = ZombRand(math.max(MIN_XY, tpX-offset), math.min(MAX_XY, tpX+offset))
	local initY = ZombRand(math.max(MIN_XY, tpY-offset), math.min(MAX_XY, tpY+offset))

	if ignoreEdgePriority then
		--this takes either initX/initY and makes it either MIN_XY/MAX
		local initPosXY = {initX, initY}
		local randEdge = {MIN_XY, MAX_XY}
		
		--randEdge stops being a list and becomes a random part of itself
		randEdge = randEdge[ZombRand(#randEdge)+1]
		
		--a random part of initPosXY is set to randEdge
		initPosXY[ZombRand(#initPosXY)+1] = randEdge
		
		self.currentPosition:set(initPosXY[1], initPosXY[2], self.height)
		
		return
	end
	
	--Looks for the closest edge to initX and initY to modify it to be along either MIN_XY/MAX_XY
	--differences between initX and MIN_XY/MAX_XY edge values
	local xDiffToMin = math.abs(initX-MIN_XY)
	local xDiffToMax = math.abs(initX-MAX_XY)
	local yDiffToMin = math.abs(initY-MIN_XY)
	local yDiffToMax = math.abs(initY-MAX_XY)
	--this list uses xyDiff's values as keys storing respective corresponding edges
	local xyDiffCorrespondingEdge = {[xDiffToMin]=MIN_XY, [xDiffToMax]=MAX_XY, [yDiffToMin]=MIN_XY, [yDiffToMax]=MAX_XY}
	--get the smallest of the four differences
	local smallestDiff = math.min(xDiffToMin,xDiffToMax,yDiffToMin,yDiffToMax)
	
	--if the smallest is a X local var then set initX
	if (smallestDiff == xDiffToMin) or (smallestDiff == xDiffToMax) then
		initX = xyDiffCorrespondingEdge[smallestDiff]
	else
		--otherwise, set initY
		initY = xyDiffCorrespondingEdge[smallestDiff]
	end

	self.currentPosition:set(initX, initY, self.height)

end


function eHelicopter:isInBounds()

	local h_x = tonumber(Vector3GetX(self.currentPosition))
	local h_y = tonumber(Vector3GetY(self.currentPosition))

	if h_x <= MAX_XY and h_x >= MIN_XY and h_y <= MAX_XY and h_y >= MIN_XY then
		return true
	end

	return false
end

function eHelicopter:getDistanceToTarget()

	local a = Vector3GetX(self.targetPosition) - Vector3GetX(self.currentPosition)
	local b = Vector3GetY(self.targetPosition) - Vector3GetY(self.currentPosition)

	return math.sqrt((a*a)+(b*b))
end


---@param movement Vector3
function eHelicopter:dampen(movement)

	local dampenFactor = math.max(2.0, math.min(0.1, self:getDistanceToTarget() / self.preflightDistance))
	local x_movement = Vector3GetX(movement) * dampenFactor
	local y_movement = Vector3GetY(movement) * dampenFactor

	return movement:set(x_movement,y_movement,self.height)
end


function eHelicopter:setTargetPos()
	if self.target then
		self.targetPosition:set(self.target:getX(), self.target:getY(), self.height)
	end
end


---Aim eHelicopter at it's defined target
---@return Vector3
function eHelicopter:aimAtTarget()

	self:setTargetPos()

	local movement_x = Vector3GetX(self.targetPosition) - Vector3GetX(self.currentPosition)
	local movement_y = Vector3GetY(self.targetPosition) - Vector3GetY(self.currentPosition)

	--difference between target's and current's x/y
	local local_movement = Vector3.new(movement_x,movement_y,0)
	--normalize (shrink) the difference
	local_movement:normalize()
	--multiply the difference based on speed
	local_movement:setLength(self.speed)

	return local_movement
end


---@param re_aim boolean
---@param dampen boolean
function eHelicopter:move(re_aim, dampen)

	---@type Vector3
	local velocity

	if re_aim then
		velocity = self:aimAtTarget()
		self.lastMovement:set(velocity)
	else
		velocity = self.lastMovement:clone()
	end

	if dampen then
		velocity = self:dampen(velocity)
	end

	--account for sped up time
	local timeSpeed = getGameSpeed()
	local v_x = Vector3GetX(self.currentPosition)+(Vector3GetX(velocity)*timeSpeed)
	local v_y = Vector3GetY(self.currentPosition)+(Vector3GetY(velocity)*timeSpeed)

	--The actual movement occurs here when the modified `velocity` is added to `self.currentPosition`
	self.currentPosition:set(v_x, v_y, self.height)
	--Move emitter to position - note toNumber is needed for Vector3GetX/Y due to setPos not behaving with lua's pseudo "float"
	self.emitter:setPos(tonumber(v_x),tonumber(v_y),self.height)

	local heliVolume = 50
	--slight delay between randomly picked announcements
	if not self.lastAnnouncedTime or self.lastAnnouncedTime <= getTimestamp() then
		heliVolume = heliVolume+20
		self:announce()--"PleaseReturnToYourHomes")
	end

	--virtual sound event to attract zombies
	addSound(nil, v_x, v_y, 0, 250, heliVolume)

	self:Report(re_aim, dampen)
end


function eHelicopter:getIsoCoords()
	local ehX, ehY, ehZ = tonumber(Vector3GetX(self.currentPosition)), tonumber(Vector3GetY(self.currentPosition)), self.height
	return ehX, ehY, ehZ
end


---@param targetedPlayer IsoMovingObject | IsoPlayer | IsoGameCharacter random player if blank
function eHelicopter:launch(targetedPlayer)

	if not targetedPlayer then
		--the -1 is to offset playerIDs starting at 0
		local numActivePlayers = getNumActivePlayers()-1
		local randNumFromActivePlayers = ZombRand(numActivePlayers)
		targetedPlayer = getSpecificPlayer(randNumFromActivePlayers)
	end

	self.target = targetedPlayer
	self:setTargetPos()
	self:initPos(self.target)

	self.preflightDistance = self:getDistanceToTarget()

	local e_x, e_y, e_z = self:getIsoCoords()

	--note: look into why getFreeEmitter and playSoundImpl even need a location
	self.emitter = getWorld():getFreeEmitter(e_x, e_y, e_z)
	self.emitter:playSound("eHelicopter", e_x, e_y, e_z)

	self:chooseVoice()

	table.insert(ALL_HELICOPTERS, self)
	self.ID = #ALL_HELICOPTERS
	self.state = "passTarget"
end


---@param specificVoice string
function eHelicopter:chooseVoice(specificVoice)

	if not specificVoice then
		local randAnn = ZombRand(eHelicopter_announcerCount)+1
		for k,_ in pairs(eHelicopter_announcers) do
			randAnn = randAnn-1
			if randAnn <= 0 then
				specificVoice = k
				break
			end
		end
	end

	self.announcerVoice = eHelicopter_announcers[specificVoice]
end


---@param specificLine string
function eHelicopter:announce(specificLine)

	if not specificLine then

		local ann_num = ZombRand(self.announcerVoice["LineCount"])+1

		for k,_ in pairs(self.announcerVoice["Lines"]) do
			--print("announce: ann_num:"..ann_num.." #eHelicopter.announcements:"..#eHelicopter.announcements)
			ann_num = ann_num-1
			if ann_num <= 0 then
				specificLine = k
				break
			end
		end
	end

	local line = self.announcerVoice["Lines"][specificLine]
	local announcePick = line[ZombRand(#line)+1]
	local lineDelay = math.floor(string.len(specificLine)/10)*2

	--print("announce:"..tostring(specificLine)..":"..tostring(line)..":"..announcePick..":"..lineDelay)
	self.lastAnnouncedTime = getTimestamp()+lineDelay
	self.emitter:playSound(announcePick, tonumber(Vector3GetX(self.currentPosition)), tonumber(Vector3GetY(self.currentPosition)), self.height)
end


function eHelicopter:update()

	--threshold for reaching player should be self.speed * getGameSpeed
	if (self.state == "passTarget") and (self:getDistanceToTarget() <= ((2*self.speed)*tonumber(getGameSpeed()))) then
		print("HELI: "..self.ID.." FLEW OVER TARGET".." (x:"..Vector3GetX(self.currentPosition)..", y:"..Vector3GetY(self.currentPosition)..")")
		self.state = "goHome"
		self.target = getSquare(self.target:getX(),self.target:getY(),0)
		self:setTargetPos()
	end

	local lockOn = true
	if self.state == "goHome" then
		lockOn = false
	end

	self:move(lockOn, true)

	if not self:isInBounds() then
		self:unlaunch()
	end
end


function updateAllHelicopters()
	for key,_ in ipairs(ALL_HELICOPTERS) do
		---@type eHelicopter heli

		local heli = ALL_HELICOPTERS[key]

		if heli.state ~= "unlaunched" then
			heli:update()
		end
	end
end


function eHelicopter:unlaunch()
	print("HELI: "..self.ID.." UN-LAUNCH".." (x:"..Vector3GetX(self.currentPosition)..", y:"..Vector3GetY(self.currentPosition)..")")
	ALL_HELICOPTERS[self.ID] = nil
	self.emitter:stopAll()
end


Events.OnTick.Add(updateAllHelicopters)



--- debug purposes -- this will flood your output
function eHelicopter:Report(aiming, dampen)
	---@type eHelicopter heli
	local heli = self
	local report = " a:"..tostring(aiming).." d:"..tostring(dampen).." s:"..heli.speed.." t:"..getGameSpeed().." "
	print("HELI: "..heli.ID.." (x:"..Vector3GetX(heli.currentPosition)..", y:"..Vector3GetY(heli.currentPosition)..")")
	print("(dist: "..heli:getDistanceToTarget().."  "..report)
	print("TARGET: (x:"..Vector3GetX(heli.targetPosition)..", y:"..Vector3GetY(heli.targetPosition)..")")
	print("-----------------------------------------------------------------")
end

--- Used only for testing purposes
Events.OnCustomUIKey.Add(function(key)
if key == Keyboard.KEY_0 then
	---@type eHelicopter heli
	local heli = eHelicopter:new()
	heli:launch()
	print("HELI: "..heli.ID.." LAUNCHED".." (x:"..Vector3GetX(heli.currentPosition)..", y:"..Vector3GetY(heli.currentPosition)..")")
	end
end)
