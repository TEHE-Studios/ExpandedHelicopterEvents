function eHelicopter:update()

	if (not self.target) or (not self.trueTarget) then

		if (not self.target) then
			print(" - EHE: ERR: "..self:heliToString().." no target in update()")
		end
		if (not self.trueTarget) then
			print(" - EHE: ERR: "..self:heliToString().." no trueTarget in update()")
		end

		self.trueTarget = self:findTarget(self.attackDistance)
		return
	end

	local timeStampMS = getTimestampMs()
	local thatIsCloseEnough = (self.topSpeedFactor*self.speed)*tonumber(getGameSpeed())
	local distanceToTrueTarget = self:getDistanceToIsoObject(self.trueTarget)

	--if trueTarget is within range
	if distanceToTrueTarget and (distanceToTrueTarget <= (self.attackDistance*4)) then
		--if trueTarget is outside then sync targets
		if self.trueTarget:isOutside() then
			if (distanceToTrueTarget <= self.attackDistance*2) then
				if (self.target ~= self.trueTarget) then
					self.target = self.trueTarget
					self:playEventSound("foundTarget")
				end
				self.timeSinceLastSeenTarget = timeStampMS
			end
		else
			--prevent constantly changing targets during roaming
			if (self.timeSinceLastRoamed < timeStampMS) then
				self.timeSinceLastRoamed = timeStampMS+10000 --10 seconds

				--random offset used for roaming
				local offset = self.attackDistance
				local randOffset = {-offset,offset}

				local tx = self.trueTarget:getX()
				--50% chance to offset x
				if ZombRand(1,100) <= 50 then
					--pick from randOffset, 50% negative or positive
					tx = tx+randOffset[ZombRand(1,#randOffset+1)]
				end
				local ty = self.trueTarget:getY()
				--50% chance to offset y
				if ZombRand(1,100) <= 50 then
					--pick from randOffset, 50% negative or positive
					tx = tx+randOffset[ZombRand(1,#randOffset+1)]
				end
				--set target to square from calculated offset
				self.target = getCell():getOrCreateGridSquare(tx,ty,0)
			end
		end

		--if trueTarget is not a gridSquare and timeSinceLastSeenTarget exceeds searchForTargetDuration set trueTarget to current target
		if (not instanceof(self.trueTarget, "IsoGridSquare")) and (self.timeSinceLastSeenTarget+self.searchForTargetDuration < timeStampMS) then
			self.trueTarget = self.target
			self:playEventSound("lostTarget")
		end
		self:setTargetPos()
	end

	if instanceof(self.trueTarget, "IsoGridSquare") and self.hoverOnTargetDuration and (self.timeSinceLastSeenTarget+self.searchForTargetDuration < timeStampMS) then
		local newTarget = self:findTarget(self.attackDistance*4)
		if newTarget and not instanceof(newTarget, "IsoGridSquare") then
			self.trueTarget = newTarget
			self:setTargetPos()
		else
			--look again later
			self.timeSinceLastSeenTarget = timeStampMS+(self.searchForTargetDuration/5)
		end
	end

	local distToTarget = self:getDistanceToVector(self.targetPosition)
	thatIsCloseEnough = thatIsCloseEnough+4

	local crashMin = math.floor(thatIsCloseEnough*20)
	local crashMax = math.min(250, math.floor(ZombRand(crashMin,crashMin*2)))
	if self.crashing and (distToTarget <= crashMax) and (distToTarget >= crashMin) then
		--[DEBUG]] print("EHE: crashing parameters met. ("..crashMin.." to "..crashMax..")")
		if self:crash() then
			return
		end
	end

	if self.hoverOnTargetDuration then
		thatIsCloseEnough = thatIsCloseEnough*ZombRand(2,4)
	end

	local preventMovement = false
	if (self.state == "gotoTarget") and (distToTarget <= thatIsCloseEnough) then
		if self.hoverOnTargetDuration then
			--[DEBUG]] if getDebug() then self:hoverAndFlyOverReport(" - HOVERING OVER TARGET") end
			self:playEventSound("hoverOverTarget", nil, true)

			if self.addedFunctionsToEvents then
				local eventFunction = self.addedFunctionsToEvents["OnHover"]
				if eventFunction then
					eventFunction(self)
				end
			end

			self.hoverOnTargetDuration = self.hoverOnTargetDuration-(1*getGameSpeed())
			if self.hoverOnTargetDuration <= 0 then
				self.hoverOnTargetDuration = false
			end
			preventMovement=true
		else

			--[[DEBUG]
			if getDebug() then
				local debugTargetText = " (square)"
				if self.trueTarget then
					if instanceof(self.trueTarget, "IsoPlayer") then debugTargetText = " ("..self.trueTarget:getFullName()..")" end
					self:hoverAndFlyOverReport(" - FLEW OVER TARGET"..debugTargetText)
				end
			end
			--]]

			self:playEventSound("hoverOverTarget",nil, nil, true)
			self:playEventSound("flyOverTarget")

			if self.addedFunctionsToEvents then
				local eventFunction = self.addedFunctionsToEvents["OnFlyaway"]
				if eventFunction then
					eventFunction(self)
				end
			end

			self:goHome()
		end
	end

	local lockOn = true
	if self.state == "goHome" then
		lockOn = false
	end

	--if it's ok to move do so, and update the shadow's position
	if not preventMovement then
		self:move(lockOn, true)
	end

	if self.announcerVoice and (not self.crashing) and (distToTarget <= thatIsCloseEnough*1500) then
		self:announce()
	end

	self:updateSubFunctions(thatIsCloseEnough, distToTarget, timeStampMS)
	for heli,offsets in pairs(self.formationFollowingHelis) do
		---@type eHelicopter
		local followingHeli = heli
		if followingHeli then
			followingHeli:updateSubFunctions(thatIsCloseEnough, distToTarget, timeStampMS)
		end
	end

	if not self:isInBounds() then
		self:unlaunch()
	end
end


function eHelicopter:updateSubFunctions(thatIsCloseEnough, distToTarget, timeStampMS)
	local currentSquare = self:getIsoGridSquare()
	--Wake up (Wake up) / Grab a brush and put a little make-up
	for character,value in pairs(EHEIsoPlayers) do
		---@type IsoGameCharacter p
		local p = character
		if self:getDistanceToIsoObject(p) < (self.flightVolume*3) then
			p:forceAwake()
		end
	end

	self:checkDelayedEventSounds()

	--drop carpackage
	local packageDropRange = thatIsCloseEnough*100
	local packageDropRateChance = ZombRand(100) <= ((distToTarget/packageDropRange)*100)+10
	if self.dropPackages and packageDropRateChance and (distToTarget <= packageDropRange) then
		self:dropCarePackage()
	end

	--drop items
	local itemDropRange = thatIsCloseEnough*250
	if self.dropItems and (distToTarget <= itemDropRange) then
		local dropChance = ((itemDropRange-distToTarget)/itemDropRange)*10
		self:tryToDropItem(dropChance)
	end

	if self.shadow ~= false then
		if self.shadow == true then
			self.shadow = getWorldMarkers():addGridSquareMarker("circle_shadow", nil, currentSquare, 0.2, 0.2, 0.2, false, 6)
		end

		local shadowSquare = getOutsideSquareFromAbove(currentSquare) or currentSquare
		if shadowSquare then
			self.shadow:setPos(shadowSquare:getX(),shadowSquare:getY(),shadowSquare:getZ())
		end
	end

	--shadowBob
	if self.shadow and (self.shadow ~= true) and (self.timeSinceLastShadowBob < timeStampMS) then
		self.timeSinceLastShadowBob = timeStampMS+10
		local shadowSize = self.shadow:getSize()
		shadowSize = shadowSize+self.shadowBobRate
		if shadowSize >= 6.5 then
			self.shadowBobRate = 0-math.abs(self.shadowBobRate)
		elseif shadowSize <= 6 then
			self.shadowBobRate = math.abs(self.shadowBobRate)
		end
		self.shadow:setSize(shadowSize)
	end

	local volumeFactor = 1
	local zoneType = currentSquare:getZoneType()
	if (zoneType == "Forest") or (zoneType == "DeepForest") then
		volumeFactor = 0.25
	end
	addSound(nil, currentSquare:getX(),currentSquare:getY(), 0, (self.flightVolume*5)*volumeFactor, self.flightVolume*volumeFactor)

	if self.hostilePreference and (not self.crashing) then
		self:lookForHostiles(self.hostilePreference)
	end
end


lastUpdateAllHelicopters = -1
function updateAllHelicopters()

	local timeStamp = getTimestampMs()
	if (lastUpdateAllHelicopters+5 >= timeStamp) then
		return
	else
		lastUpdateAllHelicopters = timeStamp
	end

	for _,helicopter in ipairs(ALL_HELICOPTERS) do
		---@type eHelicopter heli
		local heli = helicopter

		if heli and heli.state and (heli.state ~= "unLaunched") and (heli.state ~= "following") then
			heli:update()
		end
	end
end

Events.OnTick.Add(updateAllHelicopters)