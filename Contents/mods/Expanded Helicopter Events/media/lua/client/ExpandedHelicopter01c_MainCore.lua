
ALL_HELICOPTERS = {}

---Do not call this function directly for new helicopters; use: getFreeHelicopter instead
function eHelicopter:new()

	local o = {}
	setmetatable(o, self)
	self.__index = self
	table.insert(ALL_HELICOPTERS, o)
	o.ID = #ALL_HELICOPTERS

	return o
end


---returns first "unLaunched" helicopter found in ALL_HELICOPTERS -OR- creates a new instance
function getFreeHelicopter(preset)
	---@type eHelicopter heli
	local heli
	for _,h in ipairs(ALL_HELICOPTERS) do
		if h.state == "unLaunched" then
			heli = h
			break
		end
	end

	if not heli then
		heli = eHelicopter:new()
	end

	if preset then
		heli:loadPreset(preset)
	end

	return heli
end


---Initialize Position
---@param targetedPlayer IsoMovingObject | IsoPlayer | IsoGameCharacter
---@param randomEdge boolean true = uses random edge, false = prefers closer edge
function eHelicopter:initPos(targetedPlayer, randomEdge)

	setDynamicGlobalXY()

	--player's location
	local tpX = targetedPlayer:getX()
	local tpY = targetedPlayer:getY()

	--assign a random spawn point for the helicopter within a radius from the player
	--these values are being clamped to not go passed MIN_XY/MAX edges
	local offset = 500
	local initX = ZombRand(math.max(eheBounds.MIN_X, tpX-offset), math.min(eheBounds.MAX_X, tpX+offset))
	local initY = ZombRand(math.max(eheBounds.MIN_Y, tpY-offset), math.min(eheBounds.MAX_Y, tpY+offset))

	if not self.currentPosition then
		self.currentPosition = Vector3.new()
	end

	if randomEdge then
		print(" EHE: randomEdge")
		local initPosXY = {initX, initY}
		local minMax = {eheBounds.MIN_X, eheBounds.MIN_Y, eheBounds.MAX_X, eheBounds.MAX_Y}

		--pick X=1 or Y=2 position
		local randXYEdge = ZombRand(1, #initPosXY+1)

		--pick min=1,2 or max=3,4 (50% to be max)
		local randXYMinMax = ZombRand(1, #initPosXY+1)
		if ZombRand(1,3) <= 1 then
			randXYMinMax = randXYMinMax+2
		end

		print("  EHE: randXYEdge: "..randXYEdge.."   randXYMinMax: "..randXYMinMax)

		--this sets either [1] or [2] of initPosXY as [1] through [4] of minMax
		initPosXY[randXYEdge] = minMax[randXYMinMax]

		self.currentPosition:set(initPosXY[1], initPosXY[2], self.height)
		return
	end

	--Looks for the closest edge to initX and initY to modify it to be along either eheBounds.MIN_X/Y/MAX_X/Y
	--differences between initX and eheBounds.MIN_X/Y/MAX_X/Y edge values
	local xDiffToMin = math.abs(initX-eheBounds.MIN_X)
	local xDiffToMax = math.abs(initX-eheBounds.MAX_X)
	local yDiffToMin = math.abs(initY-eheBounds.MIN_Y)
	local yDiffToMax = math.abs(initY-eheBounds.MAX_Y)
	--this list uses x/yDifftoMin/Max's values as keys storing their respective corresponding edges
	local xyDiffCorrespondingEdge = {[xDiffToMin]=eheBounds.MIN_X, [xDiffToMax]=eheBounds.MAX_X, [yDiffToMin]=eheBounds.MIN_Y, [yDiffToMax]=eheBounds.MAX_Y}
	--get the smallest of the four differences
	local smallestDiff = math.min(xDiffToMin,xDiffToMax,yDiffToMin,yDiffToMax)

	--if the smallest is a X local var then set initX to the closer edge
	if (smallestDiff == xDiffToMin) or (smallestDiff == xDiffToMax) then
		initX = xyDiffCorrespondingEdge[smallestDiff]
	else
		--otherwise, set initY to the closer edge
		initY = xyDiffCorrespondingEdge[smallestDiff]
	end

	self.currentPosition:set(initX, initY, self.height)
end


---@return int, int, int XYZ of eHelicopter
function eHelicopter:getXYZAsInt()
	local ehX = math.floor(Vector3GetX(self.currentPosition) + 0.5)
	local ehY = math.floor(Vector3GetY(self.currentPosition) + 0.5)
	local ehZ = self.height

	return ehX, ehY, ehZ
end


---@return IsoGridSquare of eHelicopter
function eHelicopter:getIsoGridSquare()
	local ehX, ehY, _ = self:getXYZAsInt()
	local square = getCell():getOrCreateGridSquare(ehX, ehY, 0)
	return square
end


---@return boolean
function eHelicopter:isInBounds()
	local h_x, h_y, _ = self:getXYZAsInt()

	if h_x <= eheBounds.MAX_X and h_x >= eheBounds.MIN_X and h_y <= eheBounds.MAX_Y and h_y >= eheBounds.MIN_Y then
		return true
	end
	--[[DEBUG]] print("- EHE: OUT OF BOUNDS: HELI: "..self.ID..": "..h_x..", "..h_y)
	return false
end


--This attempts to get the outside (roof or ground) IsoGridSquare to any X/Y coordinate
---@param square IsoGridSquare
---@return IsoGridSquare
function getOutsideSquareFromAbove(square)
	if not square then
		return
	end

	if square:isOutside() and square:isSolidFloor() then
		return square
	end

	local x, y = square:getX(), square:getY()
	local cell = square:getCell()

	for i=1, 7 do
		local sq = cell:getOrCreateGridSquare(x, y, i)
		if sq and sq:isOutside() and sq:isSolidFloor() then
			return sq
		end
	end
end


---@param vector Vector3
---@return number
function eHelicopter:getDistanceToVector(vector)

	if (not vector) or (not self.currentPosition) then
		print("ERR: getDistanceToVector: no vector or no currentPosition")
		return
	end

	local a = Vector3GetX(vector) - Vector3GetX(self.currentPosition)
	local b = Vector3GetY(vector) - Vector3GetY(self.currentPosition)

	return math.sqrt((a*a)+(b*b))
end


---@param object IsoObject
---@return number
function eHelicopter:getDistanceToIsoObject(object)
	if (not object) or (not self.currentPosition) then
		print("ERR: getDistanceToIsoObject: no object or no currentPosition")
		return
	end

	local a = object:getX() - Vector3GetX(self.currentPosition)
	local b = object:getY() - Vector3GetY(self.currentPosition)

	return math.sqrt((a*a)+(b*b))
end


---@param movement Vector3
---@return Vector3
function eHelicopter:dampen(movement)
	self:setTargetPos()
	--finds the fraction of distance to target and preflight distance to target
	local distanceCompare = self:getDistanceToVector(self.targetPosition) / self.preflightDistance
	--clamp with a max of self.topSpeedFactor and min of 0.1 (10%) is applied to the fraction
	local dampenFactor = math.max(self.topSpeedFactor, math.min(0.025, distanceCompare))
	--this will slow-down/speed-up eHelicopter the closer/farther it is to the target
	local x_movement = Vector3GetX(movement) * dampenFactor
	local y_movement = Vector3GetY(movement) * dampenFactor

	return movement:set(x_movement,y_movement,self.height)
end


---Sets targetPosition (Vector3) to match target (IsoObject)
function eHelicopter:setTargetPos()
	if not self.target then
		return
	end
	local tx, ty, tz = self.target:getX(), self.target:getY(), self.height

	if not self.targetPosition then
		self.targetPosition = Vector3.new(tx, ty, tz)
	else
		self.targetPosition:set(tx, ty, tz)
	end
end


---Aim eHelicopter at it's defined target
---@return Vector3
function eHelicopter:aimAtTarget()

	self:setTargetPos()

	local movement_x = Vector3GetX(self.targetPosition) - Vector3GetX(self.currentPosition)
	local movement_y = Vector3GetY(self.targetPosition) - Vector3GetY(self.currentPosition)

	--difference between target's and current's x/y
	---@type Vector3 local_movement
	local local_movement = Vector3.new(movement_x,movement_y,0)
	--normalize (shrink) the difference
	local_movement:normalize()
	--multiply the difference based on speed
	local_movement:setLength(self.speed)

	return local_movement
end


---@param re_aim boolean recalculate angle to target
---@param dampen boolean adjust speed based on distance to target
function eHelicopter:move(re_aim, dampen)

	---@type Vector3
	local velocity

	if not self.lastMovement then
		re_aim = true
	end

	local storedSpeed = self.speed
	--if there's more than 5 targets
	if #self.hostilesToFireOn > 5 then
		--slow speed down while shooting
		self.speed = self.speed/2
	end

	if re_aim then
		velocity = self:aimAtTarget()

		if not self.lastMovement then
			self.lastMovement = Vector3.new(velocity)
		else
			self.lastMovement:set(velocity)
		end

	else
		velocity = self.lastMovement:clone()
	end

	if dampen then
		velocity = self:dampen(velocity)
	end

	--restore speed
	self.speed = storedSpeed

	--account for sped up time
	local timeSpeed = getGameSpeed()
	local v_x = Vector3GetX(self.currentPosition)+(Vector3GetX(velocity)*timeSpeed)
	local v_y = Vector3GetY(self.currentPosition)+(Vector3GetY(velocity)*timeSpeed)
	--The actual movement occurs here when the modified `velocity` is added to `self.currentPosition`
	self.currentPosition:set(v_x, v_y, self.height)
	--move announcer emitter
	if self.announceEmitter then
		self.announceEmitter:setPos(v_x,v_y,self.height)
	end
	--Move held emitters to position
	for _,emitter in pairs(self.heldEventSoundEffectEmitters) do
		emitter:setPos(v_x,v_y,self.height)
	end
	--self:Report(re_aim, dampen)
end


---@param range number
function eHelicopter:findTarget(range)
	--the -1 is to offset playerIDs starting at 0
	local weightPlayersList = {}
	local maxWeight = 10
	local playersFound = 0
	local blankWeights = 0

	for character,value in pairs(EHEIsoPlayers) do
		---@type IsoPlayer | IsoGameCharacter p
		local p = character
		--[DEBUG]] print("EHE: Potential Target:"..p:getFullName().." = "..tostring(value))
		if p and ((not range) or (self:getDistanceToIsoObject(p) <= range)) then
			playersFound = playersFound+1
			local iterations = 7
			local zone = p:getCurrentZone()
			if zone then
				local zoneType = zone:getType()
				if zoneType then
					if (zoneType == "DeepForest") then
						iterations = 3
					elseif (zoneType == "Forest") then
						iterations = 4
					elseif (zoneType == "FarmLand") then
						iterations = 6
					elseif (zoneType == "Farm") then
						iterations = 7
					elseif (zoneType == "TrailerPark") then
						iterations = 9
					elseif (zoneType == "TownZone") then
						iterations = 10
					end
				end
			end

			for _=1, maxWeight do
				if iterations > 0 then
					iterations = iterations-1
					table.insert(weightPlayersList, p)
				else
					blankWeights = blankWeights+1
				end
			end

		end
	end

	print(" -- HELI "..self.ID..": seeking target from pool of "..#weightPlayersList)

	--load blanks if there is only 1 potential player target
	if playersFound == 1 then
		print(" --- adding blanks to pool")
		for _=1, blankWeights do
			table.insert(weightPlayersList, false)
		end
	end

	local target

	if #weightPlayersList then
		target = weightPlayersList[ZombRand(1, #weightPlayersList+1)]
	end

	if not target then
		print(" --- HELI "..self.ID..": unable to find target.")
	end

	return target
end


---@param targetedPlayer IsoMovingObject | IsoPlayer | IsoGameCharacter random player if blank
function eHelicopter:launch(targetedPlayer)

	print(" - EHE: HELI:"..self.ID.." launched.")

	if not targetedPlayer then
		targetedPlayer = self:findTarget()
	end

	if targetedPlayer then
		print(" - target set: "..targetedPlayer:getFullName())
	else
		print(" -- ERR: no targetedPlayer set")
		self:unlaunch()
		return
	end

	--sets target to a square near the player so that the heli doesn't necessarily head straight for the player
	local tpX = targetedPlayer:getX()+ZombRand(-10,11)
	local tpY = targetedPlayer:getY()+ZombRand(-10,11)
	self.target = getCell():getOrCreateGridSquare(tpX, tpY, 0)
	--maintain trueTarget
	self.trueTarget = targetedPlayer
	--setTargetPos is a vector format of self.target
	self:setTargetPos()

	if not self.target then
		print(" -- ERR: no self.target set")
		self:unlaunch()
		return
	end

	self:initPos(self.target, self.randomEdgeStart)
	self.preflightDistance = self:getDistanceToVector(self.targetPosition)

	self:playEventSound("flightSound", nil, true)
	self:playEventSound("additionalFlightSound", nil, true)

	if self.hoverOnTargetDuration and type(self.hoverOnTargetDuration) == "table" then
		if #self.hoverOnTargetDuration >= 2 then
			self.hoverOnTargetDuration = ZombRand(self.hoverOnTargetDuration[1],self.hoverOnTargetDuration[2])
		else
			self.hoverOnTargetDuration = false
		end
	end

	if not self.attackDistance then
		self.attackDistance = ((self.attackScope*2)+1)*((self.attackSpread*2)+1)
	end

	if self.announcerVoice ~= false then
		self:chooseVoice(self.announcerVoice)
	end

	self.state = "gotoTarget"

	--weatherImpact is a float, 0 to 1
	local _, weatherImpact = eHeliEvent_weatherImpact()
	local GTMData = getGameTime():getModData()

	--increase crash chance as the apocalypse goes on
	local cutOffDay = self.cutOffFactor*eHelicopterSandbox.config.cutOffDay
	local daysIntoApoc = GTMData["DaysBeforeApoc"]+getGameTime():getNightsSurvived()
	local apocImpact = math.min(1,(daysIntoApoc/cutOffDay)/2)
	local dayOfLastCrash = GTMData["DayOfLastCrash"]
	local expectedMaxDaysWithOutCrash = 14/(apocImpact+1)
	local daysSinceCrashImpact = ((getGameTime():getNightsSurvived()-dayOfLastCrash)/expectedMaxDaysWithOutCrash)/4
	local crashChance = (weatherImpact+apocImpact+daysSinceCrashImpact)*100

	print(" -- crashChance:"..crashChance)
	--[[DEBUG]] print(" --- cutOffDay:"..cutOffDay.."  daysIntoApoc:"..daysIntoApoc)
	--[[DEBUG]] print(" --- apocImpact:"..apocImpact.."  weatherImpact:"..weatherImpact)
	--[[DEBUG]] print(" --- expectedMaxDaysWithOutCrash:"..expectedMaxDaysWithOutCrash)
	--[[DEBUG]] print(" --- dayOfLastCrash:"..dayOfLastCrash.."   daysSinceCrashImpact:"..daysSinceCrashImpact)

	if self.crashType and (not self.crashing) and (ZombRand(0,100) <= crashChance) then
		--[DEBUG]] print ("  - HELI: "..self.ID.." : crashing set to true.")
		self.crashing = true
	end
	print(" ------ \n")
end


---Heli goes home
function eHelicopter:goHome()
	self.state = "goHome"
	--set truTarget to target's current location -- this prevents changing course while flying away
	self.trueTarget = self:getIsoGridSquare()
	self.target = self.trueTarget
	self:setTargetPos()
end


function eHelicopter:unlaunch()
	print(" ---- HELI: "..self.ID.." UN-LAUNCH".." (x:"..Vector3GetX(self.currentPosition)..", y:"..Vector3GetY(self.currentPosition)..")")
	--stop old emitter to prevent occasional "phantom" announcements
	if self.announceEmitter and self.lastAnnouncedLine then
		self.announceEmitter:stopSoundByName(self.lastAnnouncedLine)
	end
	self:stopAllHeldEventSounds()
	if self.shadow and type(self.shadow)~="boolean" then
		self.shadow:remove()
	end
	self.state = "unLaunched"
end


