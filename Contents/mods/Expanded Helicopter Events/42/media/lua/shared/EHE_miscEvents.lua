---@param heli eHelicopter
function eHelicopter_dropCrewOff(heli)
	if not heli then
		return
	end

	local x, y, z = heli:getXYZAsInt()
	local xOffset = ZombRand(20,35)
	local yOffset = ZombRand(20,35)

	local trueTarget = heli.trueTarget
	if trueTarget then
		local tX, tY = trueTarget:getX(), trueTarget:getY()
		xOffset=math.max(0,xOffset-tX)
		yOffset=math.max(0,yOffset-tY)
	end

	if ZombRand(101) <= 50 then
		xOffset=0-xOffset
	end
	if ZombRand(101) <= 50 then
		yOffset=0-yOffset
	end

	x = x+xOffset
	y = y+yOffset

	--[[DEBUG]] print("EHE: DEBUG: eHelicopter_dropCrewOff: "..x..","..y)
	--for k,v in pairs(heli.crew) do print(" -- k:"..tostring(k).." -- ("..tostring(v)..")") end

	eventMarkerHandler.setOrUpdate(getRandomUUID(), "media/ui/crew.png", 750, x, y, heli.markerColor)
	heli:spawnCrew(x, y, 0)
	heli.addedFunctionsToEvents.OnHover = false
end


---@param crew table
function eHelicopter_crewSeek(crew)

	if not crew then
		return
	end

	local choice
	local location

	if crew:size() > 0 then
		location = crew:get(0):getSquare()
	end
	if not location then
		return
	end

	for character,_ in pairs(EHEIsoPlayers) do
		if (not choice) or (choice and character and (location:DistTo(choice) < location:DistTo(character)) ) then
			choice = character
		end
	end

	if choice then
		for i=0, crew:size()-1 do
			---@type IsoZombie
			local zombie = crew:get(i)
			if zombie then
				zombie:spotted(choice, true)
			end
		end
	end
end