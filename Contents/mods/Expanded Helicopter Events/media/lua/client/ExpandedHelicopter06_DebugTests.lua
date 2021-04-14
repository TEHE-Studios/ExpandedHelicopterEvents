--- Check eHeliEvent within eHeliEventsOnSchedule
Events.OnCustomUIKey.Add(function(key)
	if key == Keyboard.KEY_3 then
		print("eHeliEventsOnSchedule: ")
		for k,v in pairs(eHeliEventsOnSchedule) do
			print(
					k..
					" startDay:"..tostring(v.startDay)..
					" startTime:"..tostring(v.startTime)..
					" endTime:"..tostring(v.endTime)..
					" params:"..tostring(v.renew)..
					" expired:"..tostring(v.expired)
			)
		end
	end
end)


--- Check sandboxoverride
Events.OnCustomUIKey.Add(function(key)
	if key == Keyboard.KEY_4 then
		HelicopterSandboxOptionOverride()
	end
end)


--- Raise the dead
Events.OnCustomUIKey.Add(function(key)
	if key == Keyboard.KEY_5 then

		local player = getSpecificPlayer(0)
		local squaresInRange = getIsoRange(player, 30)
		local reanimated=0

		for sq=1, #squaresInRange do
			---@type IsoGridSquare
			local square = squaresInRange[sq]
			local squareContents = square:getStaticMovingObjects()

			for i=1, squareContents:size() do
				---@type IsoDeadBody
				local foundObj = squareContents:get(i-1)

				if instanceof(foundObj, "IsoDeadBody") then
					reanimated = reanimated+1
					foundObj:reanimateNow()
				end
			end
		end
		print("-- Reanimated: "..reanimated)
	end
end)



--- Debug: Reports helicopter's useful variables -- note: this will flood your output
function eHelicopter:Report(aiming, dampen)
	---@type eHelicopter heli
	local heli = self
	local report = " a:"..tostring(aiming).." d:"..tostring(dampen).." "
	print("HELI: "..heli.ID.." (x:"..Vector3GetX(heli.currentPosition)..", y:"..Vector3GetY(heli.currentPosition)..")")
	print("TARGET: (x:"..Vector3GetX(heli.targetPosition)..", y:"..Vector3GetY(heli.targetPosition)..")")
	print("(dist: "..heli:getDistanceToTarget().."  "..report)
	print("-----------------------------------------------------------------")
end


--- Test launch heli
Events.OnCustomUIKey.Add(function(key)
	if key == Keyboard.KEY_0 then
		---@type eHelicopter heli
		local heli = getFreeHelicopter()
		heli:launch()
		print("HELI: "..heli.ID.." LAUNCHED".." (x:"..Vector3GetX(heli.currentPosition)..", y:"..Vector3GetY(heli.currentPosition)..")")
	end
end)


--- Test launch close heli
Events.OnCustomUIKey.Add(function(key)
	if key == Keyboard.KEY_8 then
		---@type eHelicopter heli
		local heli = getFreeHelicopter()
		heli:launch()

		--move closer
		local tpX = heli.target:getX()
		local tpY = heli.target:getY()
		local offset = ZombRand(300)
		heli.currentPosition:set(tpX+offset, tpY+offset, heli.height)

		print("HELI: "..heli.ID.." LAUNCHED".." (x:"..Vector3GetX(heli.currentPosition)..", y:"..Vector3GetY(heli.currentPosition)..")")
	end
end)


--- Test getHumanoidsInFractalRange
Events.OnCustomUIKey.Add(function(key)
	if key == Keyboard.KEY_7 then
		local player = getSpecificPlayer(0)
		local fractalObjectsFound = getHumanoidsInFractalRange(player, 1, 2, "IsoZombie")

		---debug: list type found
		print("-----[ getHumanoidsInFractalRange ]-----")
		for fractalIndex=1, #fractalObjectsFound do
			local objectsArray = fractalObjectsFound[fractalIndex]
			print(" "..fractalIndex..":  hostile count:"..#objectsArray)
		end

	end
end)


--- Test getHumanoidsInRange
Events.OnCustomUIKey.Add(function(key)
	if key == Keyboard.KEY_6 then
		local player = getSpecificPlayer(0)
		local objectsFound = getHumanoidsInRange(player, 1, "IsoZombie")

		---debug: list type found
		print("-----[ getHumanoidsInRange ]-----")
		print(" objectsFound: ".." count: "..#objectsFound)
		for i=1, #objectsFound do
			---@type IsoMovingObject|IsoGameCharacter foundObj
			local foundObj = objectsFound[i]
			print(" "..i..":  "..tostring(foundObj:getClass())) -- "IsoZombie" or "IsoPlayer"
		end

	end
end)


--- Test all announcements
Events.OnCustomUIKey.Add(function(key)
	if key == Keyboard.KEY_9 then
	testAllLines()
	end
end)

--GLOBAL DEBUG VARS
testAllLines__ALL_LINES = {}
testAllLines__DELAYS = {}
testAllLines__lastDemoTime = 0

function testAllLines()
	if #eHelicopter_announcersLoaded <= 0 then
		print("ERROR: NO VOICES LOADED")
		return
	end

	if #testAllLines__ALL_LINES > 0 then
		testAllLines__ALL_LINES = {}
		testAllLines__DELAYS = {}
		testAllLines__lastDemoTime = 0
		return
	end

	for _,v in pairs(eHelicopter_announcersLoaded) do
		for _,v2 in pairs(eHelicopter_announcers[v]["Lines"]) do
			for k3,_ in pairs(v2) do
				if k3 ~= 1 then
					table.insert(testAllLines__ALL_LINES, v2[k3])
					table.insert(testAllLines__DELAYS, v2[1])
				end
			end
		end
	end
	table.insert(testAllLines__ALL_LINES, "heli_fire_single")
	table.insert(testAllLines__DELAYS, 1)
end

function testAllLinesLOOP()
	if #testAllLines__ALL_LINES > 0 then
		if (testAllLines__lastDemoTime <= getTimestamp()) then
			local line = testAllLines__ALL_LINES[1]
			local delay = testAllLines__DELAYS[1]
			testAllLines__lastDemoTime = getTimestamp()+delay
			---@type IsoPlayer | IsoGameCharacter player
			local player = getSpecificPlayer(0)
			player:playSound(line)
			table.remove(testAllLines__ALL_LINES, 1)
			table.remove(testAllLines__DELAYS, 1)
		end
	end
end

Events.OnTick.Add(testAllLinesLOOP)